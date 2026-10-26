import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mss_offline_ai/models/record.dart';
import 'package:mss_offline_ai/services/ai_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => '/tmp/mss-chat-tests');
  });

  test(
      'separate chats survive restart, rename and delete without losing other chats',
      () async {
    final engine = AiEngine();
    await engine.initialize();
    await engine.addMessage(const LocalChatMessage(
        role: 'user', content: 'Translate this to Pashto: Hello'));
    final first = engine.activeConversationId!;
    for (var i = 0; i < 65; i++) {
      await engine
          .addMessage(LocalChatMessage(role: 'assistant', content: 'Reply $i'));
    }
    await engine.newChat();
    expect(engine.messages, isEmpty);
    await engine.addMessage(const LocalChatMessage(
        role: 'user', content: 'Write an email in English'));
    final second = engine.activeConversationId!;
    await engine.renameConversation(first, 'Pashto translations');
    final restored = AiEngine();
    await restored.initialize();
    expect(restored.conversations.length, 2);
    expect(restored.activeConversationId, second);
    await restored.openConversation(first);
    expect(restored.messages.length, 66);
    expect(restored.activeConversation!.title, 'Pashto translations');
    await restored.deleteConversation(first);
    expect(restored.messages, isEmpty);
    await restored.openConversation(second);
    expect(restored.messages.single.content, 'Write an email in English');
    final afterDelete = AiEngine();
    await afterDelete.initialize();
    expect(afterDelete.conversations.single.id, second);
    engine.dispose();
    restored.dispose();
    afterDelete.dispose();
  });

  test('legacy chat is migrated once and retained when starting a new chat',
      () async {
    SharedPreferences.setMockInitialValues({
      'messages': ['user\u0001Hello', 'assistant\u0001Hi']
    });
    final engine = AiEngine();
    await engine.initialize();
    expect(engine.messages.length, 2);
    await engine.newChat();
    final restored = AiEngine();
    await restored.initialize();
    expect(restored.conversations.length, 1);
    expect(restored.messages, isEmpty);
    expect(restored.conversations.single.messages.last.content, 'Hi');
    engine.dispose();
    restored.dispose();
  });
}
