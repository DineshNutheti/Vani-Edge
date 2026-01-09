import 'package:flutter/material.dart';

import '../../../core/app_language.dart';
import '../domain/message.dart';
import 'chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
  });

  final ChatController controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _initializing = true;
  bool _isInternalUpdate = false;

  ChatController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    controller.init().whenComplete(() {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_isInternalUpdate) {
      return;
    }
    if (_textController.text != controller.draftText) {
      _isInternalUpdate = true;
      _textController.text = controller.draftText;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
      _isInternalUpdate = false;
    }
    // Keep latest messages visible after new responses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(controller.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        actions: [
          _LanguageMenu(
            language: controller.language,
            onChanged: (language) => controller.setLanguage(language),
          ),
          IconButton(
            onPressed: controller.messages.isEmpty ? null : controller.clearHistory,
            tooltip: strings.clearHistory,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_initializing)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: controller.messages.isEmpty
                  ? _EmptyState(strings: strings)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
                        return _MessageBubble(
                          message: message,
                          isUser: message.isUser,
                        );
                      },
                    ),
            ),
            _StatusBanner(
              strings: strings,
              statusKey: controller.statusMessage,
              isListening: controller.isListening,
              sttAvailable: controller.sttAvailable,
            ),
            _InputBar(
              controller: controller,
              strings: strings,
              textController: _textController,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AppLanguage>(
        value: language,
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        items: [
          for (final lang in AppLanguages.all)
            DropdownMenuItem(
              value: lang,
              child: Text(AppLanguages.config(lang).displayName),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          strings.tapToSpeak,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.strings,
    required this.textController,
  });

  final ChatController controller;
  final AppStrings strings;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.sttAvailable
                ? () async {
                    if (controller.isListening) {
                      await controller.stopListening();
                    } else {
                      await controller.startListening();
                    }
                  }
                : null,
            icon: Icon(controller.isListening ? Icons.stop_circle : Icons.mic),
          ),
          Expanded(
            child: TextField(
              controller: textController,
              onChanged: (value) => controller.updateDraft(value),
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: strings.typeMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: controller.isBusy
                ? null
                : () async {
                    await controller.sendMessage(textController.text);
                  },
            child: Text(strings.send),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  final Message message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.strings,
    required this.statusKey,
    required this.isListening,
    required this.sttAvailable,
  });

  final AppStrings strings;
  final String? statusKey;
  final bool isListening;
  final bool sttAvailable;

  @override
  Widget build(BuildContext context) {
    String? message;
    if (!sttAvailable) {
      message = strings.speechUnavailable;
    } else if (isListening) {
      message = strings.listening;
    } else {
      message = switch (statusKey) {
        'stt_error' => strings.sttPermissionDenied,
        'tts_unavailable' => strings.ttsUnavailable,
        'retrying' => strings.retrying,
        _ => null,
      };
    }
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
