import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'llm_service.dart';

class LlamaService implements LLMService {
  // We don't hardcode paths. We define filenames.
  final String _modelFileName = 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';
  final String _cliFileName = 'llama-cli';
  static const bool _enableMobileNativeLlm =
      bool.fromEnvironment('ENABLE_LOCAL_LLM', defaultValue: false);

  String? _executablePath;
  String? _modelPath;
  Isolate? _mobileIsolate;
  ReceivePort? _mobileReceivePort;
  ReceivePort? _mobileErrorPort;
  ReceivePort? _mobileExitPort;
  SendPort? _mobileSendPort;
  Completer<void>? _mobileInitCompleter;
  StreamController<String>? _activeMobileController;
  _StreamSanitizer? _activeSanitizer;
  String? _mobileInitError;

  bool get _desktopReady =>
      _executablePath != null &&
      _modelPath != null &&
      File(_executablePath!).existsSync() &&
      File(_modelPath!).existsSync();

  @override
  Future<void> initialize() async {
    print("System: Initializing Llama Engine...");

    // 1. Get a safe directory for this platform (Android/Linux safe)
    final docDir = await getApplicationDocumentsDirectory();

    // 3A. Mobile: use llama_cpp_dart
    if (Platform.isAndroid || Platform.isIOS) {
      if (!_enableMobileNativeLlm) {
        _mobileInitError =
            'Local LLM disabled on mobile. Run with --dart-define=ENABLE_LOCAL_LLM=true to enable.';
        print("System: $_mobileInitError");
        return;
      }
      if (!_canLoadNativeLlama()) {
        _mobileInitError =
            'Native llama library not available or incompatible. Using fallback.';
        print("System: $_mobileInitError");
        return;
      }
      _modelPath = '${docDir.path}/$_modelFileName';
      final copied =
          await _copyAssetToFile('assets/models/$_modelFileName', _modelPath!);
      if (!copied) {
        print("System: Failed to prepare model file for mobile.");
        return;
      }
      if (Platform.isAndroid) {
        // Load from jniLibs packaged into the APK (lib/arm64-v8a/libllama.so).
        Llama.libraryPath = 'libllama.so';
      }
      await _initMobileEngine();
      return;
    }

    // 2B. Desktop: Prepare the Model File
    _modelPath = '${docDir.path}/$_modelFileName';
    await _copyAssetToFile('assets/models/$_modelFileName', _modelPath!);

    // 3. Prepare the Engine (CLI)
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _executablePath = '${docDir.path}/$_cliFileName';
      await _copyAssetToFile('assets/bin/$_cliFileName', _executablePath!);
      
      // CRITICAL: Make binary executable on Linux/Mac
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', _executablePath!]);
      }
      print("System: Engine ready at $_executablePath");
    } else {
      // Android/iOS Sandbox Constraint: 
      // You CANNOT run a subprocess binary easily on mobile due to W^X security.
      // For Mobile, we would typically use a JNI library (llama_cpp_dart).
      print("System: Subprocess engine not supported on Mobile. Using Logic Fallback.");
    }
  }

  Future<void> _initMobileEngine() async {
    try {
      if (_modelPath == null) {
        throw Exception('Model path not set. Did initialization run?');
      }
      _mobileInitError = null;
      _mobileInitCompleter = Completer<void>();
      _mobileReceivePort?.close();
      _mobileReceivePort = ReceivePort();
      _mobileErrorPort?.close();
      _mobileErrorPort = ReceivePort();
      _mobileExitPort?.close();
      _mobileExitPort = ReceivePort();

      // Keep context small for mobile memory budgets
      final contextParams = ContextParams()
        ..context = 512
        ..batch = 128
        ..threads = (Platform.numberOfProcessors / 2).ceil()
        ..threadsBatch = (Platform.numberOfProcessors / 2).ceil();

      // Use CPU on mobile; GPU layers = 0
      final modelParams = ModelParams()
        ..gpuLayerLayer = 0
        ..useMemorymap = true
        ..useMemoryLock = false;

      _mobileReceivePort!.listen((message) {
        if (message is SendPort) {
          _mobileSendPort = message;
          _mobileSendPort!.send({
            'command': 'load',
            'path': _modelPath,
            'modelParams': modelParams.toJson(),
            'contextParams': contextParams.toJson(),
          });
          return;
        }

        if (message is Map) {
          final type = message['type'];
          if (type == 'ready') {
            if (!(_mobileInitCompleter?.isCompleted ?? true)) {
              _mobileInitCompleter?.complete();
            }
            print("System: Mobile Llama engine ready.");
          } else if (type == 'token') {
            final token = message['value'] as String?;
            if (token != null && _activeMobileController != null) {
              final sanitized = _activeSanitizer?.push(token);
              if (sanitized != null) {
                _activeMobileController!.add(sanitized);
              }
            }
          } else if (type == 'done') {
            _activeMobileController?.close();
            _activeMobileController = null;
            _activeSanitizer = null;
          } else if (type == 'error') {
            final errorMessage =
                (message['message'] as String?) ?? 'Unknown mobile LLM error.';
            _mobileInitError = errorMessage;
            if (!(_mobileInitCompleter?.isCompleted ?? true)) {
              _mobileInitCompleter?.completeError(errorMessage);
            }
            if (_activeMobileController != null) {
              _activeMobileController!.add(errorMessage);
              _activeMobileController!.close();
              _activeMobileController = null;
            }
            _activeSanitizer = null;
          }
        }
      });

      _mobileIsolate = await Isolate.spawn(
        _mobileIsolateEntryPoint,
        {
          'port': _mobileReceivePort!.sendPort,
          'libraryPath': Llama.libraryPath,
        },
        onError: _mobileErrorPort!.sendPort,
        onExit: _mobileExitPort!.sendPort,
      );

      _mobileErrorPort!.listen((error) {
        _handleMobileError('Mobile LLM isolate error: $error');
      });
      _mobileExitPort!.listen((_) {
        _handleMobileError('Mobile LLM isolate exited unexpectedly.');
      });
    } catch (e) {
      print("System: Failed to init llama_cpp_dart on mobile: $e");
      _handleMobileError('Failed to init llama_cpp_dart on mobile: $e');
    }
  }

  void _handleMobileError(String message) {
    _mobileInitError = message;
    if (!(_mobileInitCompleter?.isCompleted ?? true)) {
      _mobileInitCompleter?.completeError(message);
    }
    if (_activeMobileController != null) {
      _activeMobileController!.add(message);
      _activeMobileController!.close();
      _activeMobileController = null;
    }
    _activeSanitizer = null;
  }

  bool _canLoadNativeLlama() {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final lib = DynamicLibrary.open('libllama.so');
      lib.lookup<NativeFunction<Void Function(Int8)>>('llama_backend_init');
      return true;
    } catch (e) {
      print("System: Native llama library check failed: $e");
      return false;
    }
  }

  /// Helper to copy assets to writable storage dynamically
  Future<bool> _copyAssetToFile(String assetPath, String targetPath) async {
    final file = File(targetPath);
    if (!await file.exists()) {
      print("System: Extracting $assetPath to $targetPath...");
      try {
        final byteData = await rootBundle.load(assetPath);
        await file.writeAsBytes(byteData.buffer.asUint8List(
            byteData.offsetInBytes, byteData.lengthInBytes));
        return true;
      } catch (e) {
        print("Error extracting asset: $e. (Did you add it to pubspec.yaml?)");
        return false;
      }
    }
    return true;
  }

  @override
  Stream<String> streamResponse(String formattedPrompt) {
    // Controller to bridge the gap between Process and UI
    final controller = StreamController<String>();
    Process? runningProcess;
    bool stopRequested = false;

    void sendFallback(String message) {
      controller.add(message);
      controller.close();
    }

    void stopGeneration() {
      if (stopRequested) return;
      stopRequested = true;
      if (Platform.isAndroid || Platform.isIOS) {
        _mobileSendPort?.send({'command': 'stop'});
      } else {
        runningProcess?.kill();
      }
      if (!controller.isClosed) {
        controller.close();
      }
    }

    final sanitizer = _StreamSanitizer(isJunk: _isJunk, onStop: stopGeneration);
    _activeSanitizer = sanitizer;

    // CASE A: Android/iOS (Use llama_cpp_dart)
    if (Platform.isAndroid || Platform.isIOS) {
      _startMobileStream(formattedPrompt, controller, sendFallback);
      return controller.stream;
    }

    // CASE A: Linux/Desktop (Run Local Binary)
    if (Platform.isLinux || Platform.isMacOS) {
      if (!_desktopReady) {
        sendFallback("Local model or binary missing. Ensure assets/models and assets/bin are packaged.");
        return controller.stream;
      }

      print("System: Launching Subprocess...");
      
      Process.start(
        _executablePath!,
        [
          '-m', _modelPath!,
          '-p', formattedPrompt,
          '--simple-io',        // raw tokens to stdout, no REPL prompts
          '-n', '128',           
          '-c', '512',           
          '--temp', '0.1',       
          '--no-display-prompt', 
          '--log-disable',       
          '-t', '4'              
        ],
        runInShell: false, // Clean stream capture
      ).then((process) {
        runningProcess = process;
        
        // Listen to stdout (The Data)
        process.stdout.transform(utf8.decoder).listen((data) {
          final sanitized = sanitizer.push(data);
          if (sanitized != null) controller.add(sanitized);
        });

        // Listen to stderr (The Logs/Errors)
        process.stderr.transform(utf8.decoder).listen((data) {
          final sanitized = sanitizer.push(data);
          if (sanitized != null) controller.add(sanitized);
        });

        process.exitCode.then((code) {
          _activeSanitizer = null;
          if (code != 0 && !stopRequested) {
            controller.add("Engine exited with code $code. Please verify model/binary assets.");
          }
          controller.close();
        });
      }).catchError((e) {
        sendFallback("Failed to start local engine: $e");
      });
    } 
    // CASE B: Other platforms (Fallback/Mock)
    else {
      sendFallback("Local model is not supported on this platform build.");
    }

    return controller.stream;
  }

  Future<void> _startMobileStream(
    String prompt,
    StreamController<String> controller,
    void Function(String message) sendFallback,
  ) async {
    if (_mobileInitCompleter == null) {
      if (_mobileInitError != null) {
        sendFallback(_mobileInitError!);
      } else {
        sendFallback("Mobile LLM is not initialized yet.");
      }
      return;
    }

    try {
      await _mobileInitCompleter!.future
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      sendFallback("Mobile LLM failed to initialize: $e");
      return;
    }

    if (_mobileSendPort == null) {
      sendFallback("Mobile LLM transport not ready.");
      return;
    }

    if (_mobileInitError != null) {
      sendFallback(_mobileInitError!);
      return;
    }

    if (_activeMobileController != null &&
        !(_activeMobileController?.isClosed ?? true)) {
      _mobileSendPort!.send({'command': 'stop'});
      _activeMobileController!.close();
      _activeMobileController = null;
    }

    _activeMobileController = controller;
    _mobileSendPort!.send({'command': 'prompt', 'prompt': prompt});
  }

  bool _isJunk(String data) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return true;
    // Filter loader banners, prompts, metadata, stats, and control lines
    return trimmed.startsWith("build") ||
           trimmed.startsWith("model") ||
           trimmed.contains("Loading model") ||
           trimmed.contains("modalities") ||
           trimmed.contains("/exit") ||
           trimmed.contains("/regen") ||
           trimmed.contains("/clear") ||
           trimmed.contains("chat history") ||
           trimmed.startsWith("available commands") ||
           trimmed.startsWith(">") ||
           trimmed.startsWith("[ Prompt") ||
           trimmed.contains("Prompt:") ||
           trimmed.contains("Generation:") ||
           trimmed.contains("██") ||
           trimmed.contains("▄▄") ||
           trimmed.contains("▀▀") ||
           trimmed.contains("llama_") || 
           trimmed.contains("<|system|>") ||
           trimmed.contains("<|user|>");
  }

  @override
  void dispose() {
    if (_mobileSendPort != null) {
      _mobileSendPort!.send({'command': 'dispose'});
    }
    _mobileReceivePort?.close();
    _mobileErrorPort?.close();
    _mobileExitPort?.close();
    _mobileIsolate?.kill(priority: Isolate.immediate);
    _activeMobileController?.close();
  }

  static void _mobileIsolateEntryPoint(Map<String, dynamic> args) {
    final SendPort mainSendPort = args['port'] as SendPort;
    final ReceivePort isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    Llama.libraryPath = args['libraryPath'] as String?;

    Llama? llama;
    bool stopRequested = false;

    isolateReceivePort.listen((message) async {
      if (message is Map) {
        switch (message['command']) {
          case 'load':
            try {
              final contextParams =
                  ContextParams.fromJson(message['contextParams']);
              final modelParams =
                  ModelParams.fromJson(message['modelParams']);
              final modelPath = message['path'] as String;
              llama = Llama(modelPath, modelParams, contextParams);
              mainSendPort.send({'type': 'ready'});
            } catch (e) {
              mainSendPort.send({
                'type': 'error',
                'message': 'Failed to load model: $e',
              });
            }
            break;
          case 'prompt':
            if (llama == null) {
              mainSendPort.send({
                'type': 'error',
                'message': 'Mobile LLM not loaded.',
              });
              break;
            }
            stopRequested = false;
            try {
              llama!.setPrompt(message['prompt'] as String);
              while (true) {
                if (stopRequested) {
                  stopRequested = false;
                  break;
                }
                final (text, done) = llama!.getNext();
                if (done) break;
                mainSendPort.send({'type': 'token', 'value': text});
                await Future.delayed(Duration.zero);
              }
              mainSendPort.send({'type': 'done'});
            } catch (e) {
              mainSendPort.send({
                'type': 'error',
                'message': 'Generation failed: $e',
              });
            }
            break;
          case 'stop':
            stopRequested = true;
            llama?.clear();
            break;
          case 'dispose':
            llama?.dispose();
            isolateReceivePort.close();
            break;
        }
      }
    });
  }
}

class _StreamSanitizer {
  _StreamSanitizer({required this.isJunk, required this.onStop});

  final bool Function(String) isJunk;
  final void Function() onStop;

  bool _assistantStarted = false;
  bool _emittedFirstChar = false;
  bool _stopped = false;
  String _prefixBuffer = '';
  String _tailBuffer = '';

  final List<String> _stopSequences = const [
    '<|user|>',
    '<|assistant|>',
    '\nYou:',
    '\nUser:',
    '\nAssistant:',
    '\nVani:',
  ];

  late final int _maxStopLen = _stopSequences.fold(0, (maxLen, seq) {
    return seq.length > maxLen ? seq.length : maxLen;
  });

  final RegExp _roleRegex =
      RegExp(r'(^|\n)\s*(You|User|Assistant|Vani)\s*:');

  String? push(String data) {
    if (_stopped) return null;

    var clean = _stripAnsi(data).replaceAll('\r', '');

    if (!_assistantStarted) {
      _prefixBuffer += clean;
      const marker = '<|assistant|>';
      final markerIndex = _prefixBuffer.indexOf(marker);
      if (markerIndex == -1) {
        if (_prefixBuffer.length > 2048) {
          clean = _prefixBuffer;
          _prefixBuffer = '';
          _assistantStarted = true;
        } else {
          return null;
        }
      } else {
        clean = _prefixBuffer.substring(markerIndex + marker.length);
        _prefixBuffer = '';
        _assistantStarted = true;
      }
    }

    final pieces = clean.split('\n');
    final buffer = StringBuffer();

    for (var line in pieces) {
      var processed = line.replaceAll(
          RegExp(r'<\|system\|>|<\|user\|>|<\|assistant\|>'), '');

      processed = processed.replaceFirst(RegExp(r'^\s*>\s?'), '');

      final trimmed = processed.trim();
      if (trimmed.isEmpty) continue;
      if (isJunk(trimmed)) continue;

      final truncated = _truncateOnStop(processed);
      if (truncated.isEmpty) {
        if (_stopped) break;
        continue;
      }

      processed = truncated;

      if (!_emittedFirstChar) {
        final match = RegExp(r'[A-Za-z]').firstMatch(processed);
        if (match != null) {
          final idx = match.start;
          final upper = match.group(0)!.toUpperCase();
          processed =
              '${processed.substring(0, idx)}$upper${processed.substring(idx + 1)}';
          _emittedFirstChar = true;
        }
      }

      buffer.write(processed.trimRight());
      buffer.write(' ');

      if (_stopped) break;
    }

    final result = buffer.toString().trimRight();
    return result.isEmpty ? null : result;
  }

  String _stripAnsi(String value) {
    return value.replaceAll(RegExp(r'\x1B\[[0-9;]*[A-Za-z]'), '');
  }

  String _truncateOnStop(String chunk) {
    final combined = _tailBuffer + chunk;

    int? stopIndex;
    for (final seq in _stopSequences) {
      final idx = combined.indexOf(seq);
      if (idx != -1 && (stopIndex == null || idx < stopIndex)) {
        stopIndex = idx;
      }
    }

    final roleMatch = _roleRegex.firstMatch(combined);
    if (roleMatch != null) {
      final idx = roleMatch.start;
      if (stopIndex == null || idx < stopIndex) {
        stopIndex = idx;
      }
    }

    if (stopIndex != null) {
      final cutIndex = stopIndex - _tailBuffer.length;
      _stopped = true;
      onStop();
      if (cutIndex <= 0) return '';
      return chunk.substring(0, cutIndex);
    }

    if (combined.length > _maxStopLen) {
      _tailBuffer = combined.substring(combined.length - _maxStopLen);
    } else {
      _tailBuffer = combined;
    }
    return chunk;
  }
}
