import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/llm_service.dart';
import '../domain/message.dart';
import '../domain/prompt_wrapper.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/stt_service.dart';

// State provider for the list of messages
final chatHistoryProvider = StateProvider<List<Message>>((ref) => []);

// State provider for the selected language
final languageProvider = StateProvider<String>((ref) => 'English');

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // The Brain's Logic Layer
  final PromptWrapper _promptWrapper = PromptWrapper();
  
  bool _isThinking = false;
  bool _isListening = false;

  // The 5 Required Languages
  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Tamil', 'Gujarati'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Wake up the Brain
      ref.read(llmServiceProvider).initialize();
      
      // 2. Wake up the Ears (STT)
      bool available = await ref.read(sttServiceProvider).initialize();
      if (!available) {
        print("Warning: Speech recognition not available on this platform.");
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // CORE LOGIC: Send text to the LLM Service
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    final currentLang = ref.read(languageProvider);

    // 1. Add User Message to UI
    ref.read(chatHistoryProvider.notifier).update((state) => [
      ...state,
      Message(text: text, isUser: true),
    ]);
    
    setState(() => _isThinking = true);
    _scrollToBottom();

    String fullResponse = "";

    // 2. Prepare AI Response container (Placeholder)
    ref.read(chatHistoryProvider.notifier).update((state) => [
      ...state,
      Message(text: "...", isUser: false),
    ]);

    try {
      // --- INTELLIGENT WRAPPER LOGIC START ---
      
      // Step A: Check Cache (Zero Latency)
      final cachedResponse = _promptWrapper.getCachedResponse(text, currentLang);
      
      if (cachedResponse != null) {
        print("Wrapper: Cache Hit! Returning instant response.");
        fullResponse = cachedResponse;
        
        // Update UI immediately
        ref.read(chatHistoryProvider.notifier).update((state) {
          final List<Message> newState = List.from(state);
          newState.last = Message(text: "$fullResponse [Cached]", isUser: false);
          return newState;
        });
        
        await Future.delayed(const Duration(milliseconds: 100));
        
      } else {
        // Step B: Process Prompt
        print("Wrapper: Cache Miss. Processing Intent...");
        final formattedPrompt = _promptWrapper.processPrompt(text, currentLang);
        
        // Step C: Stream from Brain
        final stream = ref.read(llmServiceProvider).streamResponse(formattedPrompt);
        
        await for (final token in stream) {
          // DEBUG: Verify we are receiving data
          print("UI RECEIVED TOKEN: $token");
          
          fullResponse += token;
          
          // Live update UI
          ref.read(chatHistoryProvider.notifier).update((state) {
            if (state.isEmpty) return state;
            
            // Force a state change by creating a new list
            final List<Message> newState = List.from(state);
            newState.last = Message(text: fullResponse, isUser: false);
            return newState;
          });
        }
        
        // Step D: Save to Cache
        _promptWrapper.cacheResponse(text, currentLang, fullResponse);
      }
      // --- INTELLIGENT WRAPPER LOGIC END ---

      // 3. Speak the Response (TTS)
      try {
        ref.read(ttsServiceProvider).speak(fullResponse, currentLang);
      } catch (e) {
        print("TTS Error: $e");
      }

    } catch (e) {
      print("Chat Error: $e");
      ref.read(chatHistoryProvider.notifier).update((state) => [
        ...state,
        Message(text: "Error: $e", isUser: false),
      ]);
    } finally {
      setState(() => _isThinking = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatHistoryProvider);
    final selectedLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vani-Edge"),
        actions: [
          // Language Selector with high-contrast styling
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
              splashColor: Colors.deepPurple[50],
              highlightColor: Colors.deepPurple[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLang,
                icon: const Icon(Icons.language, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(languageProvider.notifier).state = newValue;
                  }
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.deepPurple[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Thinking Indicator
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Type or Speak...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Mic Button
                FloatingActionButton(
                  onPressed: () {
                    final stt = ref.read(sttServiceProvider);
                    
                    if (_isListening) {
                      stt.stop();
                      setState(() => _isListening = false);
                    } else {
                      setState(() => _isListening = true);
                      final selectedLang = ref.read(languageProvider);
                      stt.listen(onResult: (text) {
                        setState(() {
                          _textController.text = text;
                        });
                      }, language: selectedLang);
                    }
                  },
                  backgroundColor: _isListening ? Colors.red : Colors.deepPurple,
                  child: Icon(_isListening ? Icons.stop : Icons.mic),
                ),
                const SizedBox(width: 8),
                
                // Send Button
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
