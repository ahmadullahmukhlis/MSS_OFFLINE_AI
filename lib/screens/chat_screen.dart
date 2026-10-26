import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/prompts.dart';
import '../models/record.dart';
import '../services/ai_engine.dart';
import '../widgets/ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.engine, required this.onSetup});
  final AiEngine engine;
  final VoidCallback onSetup;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final editor = TextEditingController();
  final scroll = ScrollController();
  bool busy = false;
  String incoming = '';
  String? displayedChat;

  @override
  void initState() {
    super.initState();
    displayedChat = widget.engine.activeConversationId;
    scrollDown();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (displayedChat != widget.engine.activeConversationId) {
      displayedChat = widget.engine.activeConversationId;
      if (!busy) editor.clear();
      scrollDown();
    }
  }

  @override
  void dispose() {
    editor.dispose();
    scroll.dispose();
    super.dispose();
  }

  void scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.animateTo(scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut);
        }
      });

  Future<void> send() async {
    final text = editor.text.trim();
    final engine = widget.engine;
    if (text.isEmpty || busy || engine.generating) return;
    if (!engine.loaded) {
      showInfo(context, 'Set up and load the offline model to start chatting.');
      widget.onSetup();
      return;
    }
    setState(() {
      busy = true;
      incoming = '';
    });
    engine.setChatting(true);
    editor.clear();
    try {
      await engine.addMessage(LocalChatMessage(role: 'user', content: text));
      scrollDown();
      final response = await engine.generate(
        promptMessages: AiPrompts.chat(engine.messages, engine.chatLanguage),
        temperature: 0.4,
        onUpdate: (partial) {
          if (mounted) {
            setState(() => incoming = partial);
            scrollDown();
          }
        },
      );
      if (response.isNotEmpty) {
        await engine
            .addMessage(LocalChatMessage(role: 'assistant', content: response));
      }
    } catch (e) {
      // Retain any generated text when inference fails partway through.
      if (incoming.trim().isNotEmpty) {
        await engine
            .addMessage(LocalChatMessage(role: 'assistant', content: incoming));
      }
      if (mounted) {
        showInfo(
            context, 'Could not finish the response. Please try again. $e');
      }
    } finally {
      engine.setChatting(false);
      if (mounted) {
        setState(() {
          busy = false;
          incoming = '';
        });
      }
      scrollDown();
    }
  }

  Widget message(String text,
      {required bool assistant, bool streaming = false}) {
    final colors = Theme.of(context).colorScheme;
    final rtl = RegExp(r'[\u0600-\u06ff]').hasMatch(text) &&
        !RegExp(r'[a-zA-Z]')
            .hasMatch(text.substring(0, text.length.clamp(0, 20)));
    return Align(
        alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: assistant ? 760 : 560),
          margin:
              EdgeInsets.only(top: 12, bottom: 16, left: assistant ? 0 : 36),
          padding: EdgeInsets.symmetric(
              horizontal: assistant ? 0 : 18, vertical: assistant ? 0 : 12),
          decoration: assistant
              ? null
              : BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(text,
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                    fontSize: 16, height: 1.65, color: colors.onSurface)),
            if (assistant && !streaming)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: IconButton(
                      tooltip: 'Copy response',
                      icon: const Icon(Icons.content_copy_outlined, size: 17),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        showInfo(context, 'Copied');
                      })),
          ]),
        ));
  }

  void suggest(String prompt) {
    editor.text = prompt;
    editor.selection = TextSelection.collapsed(offset: prompt.length);
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
              child: engine.messages.isEmpty && !busy
                  ? Center(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.auto_awesome_outlined, size: 36),
                            const SizedBox(height: 22),
                            const Text('What can I help with?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.8)),
                            const SizedBox(height: 12),
                            Text('Ask, translate, or write — all in one chat.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: colors.onSurfaceVariant)),
                            const SizedBox(height: 28),
                            Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  ActionChip(
                                      avatar:
                                          const Icon(Icons.translate, size: 18),
                                      label: const Text('Translate to Pashto'),
                                      onPressed: () => suggest(
                                          'Translate to Pashto: Hello, how are you?')),
                                  ActionChip(
                                      label: const Text('Translate to English'),
                                      onPressed: () =>
                                          suggest('Translate to English: ')),
                                  ActionChip(
                                      label: const Text('Help me write'),
                                      onPressed: () => suggest(
                                          'Write a friendly email in English about ')),
                                  ActionChip(
                                      label: const Text('Explain something'),
                                      onPressed: () =>
                                          suggest('Explain in simple words: ')),
                                ]),
                          ])))
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: ListView(
                              controller: scroll,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              children: [
                                for (final m in engine.messages)
                                  message(m.content,
                                      assistant: m.role == 'assistant'),
                                if (busy)
                                  message(
                                      incoming.isEmpty ? 'Thinking…' : incoming,
                                      assistant: true,
                                      streaming: true),
                              ])))),
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                        decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: colors.outlineVariant)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: TextField(
                                controller: editor,
                                minLines: 1,
                                maxLines: 6,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                    hintText: 'Message MSS AI',
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 12)),
                              )),
                              const SizedBox(width: 8),
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: IconButton.filled(
                                      style: IconButton.styleFrom(
                                          backgroundColor: colors.onSurface,
                                          foregroundColor: colors.surface),
                                      tooltip: busy
                                          ? 'Stop response'
                                          : 'Send message',
                                      onPressed: busy ? engine.stop : send,
                                      icon: Icon(busy
                                          ? Icons.stop_rounded
                                          : Icons.arrow_upward_rounded))),
                            ]),
                      )))),
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Saved on your device · AI can make mistakes',
                  style:
                      TextStyle(fontSize: 11, color: colors.onSurfaceVariant))),
        ]));
  }
}
