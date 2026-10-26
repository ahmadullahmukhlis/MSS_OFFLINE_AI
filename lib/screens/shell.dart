import 'package:flutter/material.dart';
import '../services/ai_engine.dart';
import 'chat_screen.dart';
import 'model_screen.dart';

class MssShell extends StatefulWidget {
  const MssShell({super.key, required this.engine});
  final AiEngine engine;
  @override
  State<MssShell> createState() => _MssShellState();
}

class _MssShellState extends State<MssShell> {
  String query = '';
  void openModel() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ModelScreen(engine: widget.engine)));

  Future<void> rename(String id, String title) async {
    final editor = TextEditingController(text: title);
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Rename chat'),
              content: TextField(
                  controller: editor,
                  autofocus: true,
                  onSubmitted: (value) => Navigator.pop(context, value)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, editor.text),
                    child: const Text('Save'))
              ],
            ));
    // Dispose after the dialog's exit transition has finished.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    editor.dispose();
    if (value != null) await widget.engine.renameConversation(id, value);
  }

  Future<void> delete(String id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete chat?'),
              content: const Text(
                  'This conversation will be removed from this device.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'))
              ],
            ));
    if (confirmed == true) await widget.engine.deleteConversation(id);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.engine,
        builder: (context, _) {
          final engine = widget.engine;
          final chats = engine.conversations
              .where((c) =>
                  c.title.toLowerCase().contains(query.toLowerCase()) ||
                  c.messages.any((m) =>
                      m.content.toLowerCase().contains(query.toLowerCase())))
              .toList();
          return Scaffold(
            appBar: AppBar(
              title: const Text('MSS AI',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 21)),
              actions: [
                IconButton(
                    tooltip: 'New chat',
                    onPressed: (engine.generating || engine.chatting)
                        ? null
                        : engine.newChat,
                    icon: const Icon(Icons.edit_square)),
                const SizedBox(width: 6),
              ],
            ),
            drawer: Drawer(
                child: SafeArea(
                    child: Column(children: [
              ListTile(
                  leading: const Icon(Icons.edit_square),
                  title: const Text('New chat'),
                  enabled: !engine.generating && !engine.chatting,
                  onTap: () {
                    engine.newChat();
                    Navigator.pop(context);
                  }),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                          hintText: 'Search chats',
                          prefixIcon: Icon(Icons.search)))),
              const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Your chats'))),
              Expanded(
                  child: chats.isEmpty
                      ? Center(
                          child: Text(
                              query.isEmpty
                                  ? 'Your conversations will appear here'
                                  : 'No chats found',
                              textAlign: TextAlign.center))
                      : ListView.builder(
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            return ListTile(
                              selected: chat.id == engine.activeConversationId,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              title: Text(chat.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              enabled: !engine.generating && !engine.chatting,
                              onTap: () {
                                engine.openConversation(chat.id);
                                Navigator.pop(context);
                              },
                              trailing: PopupMenuButton<String>(
                                  enabled:
                                      !engine.generating && !engine.chatting,
                                  onSelected: (action) => action == 'rename'
                                      ? rename(chat.id, chat.title)
                                      : delete(chat.id),
                                  itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'rename',
                                            child: Text('Rename')),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete')),
                                      ]),
                            );
                          })),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    openModel();
                  }),
              const SizedBox(height: 12),
            ]))),
            body: ChatScreen(engine: engine, onSetup: openModel),
          );
        },
      );
}
