import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mss_offline_ai/main.dart';
import 'package:mss_offline_ai/models/record.dart';
import 'package:mss_offline_ai/services/ai_engine.dart';

void main() {
  testWidgets(
      'mobile chat opens without language selectors and exposes saved chats',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = AiEngine();
    await engine.addMessage(const LocalChatMessage(
        role: 'user', content: 'Translate hello to Pashto'));
    await engine
        .addMessage(const LocalChatMessage(role: 'assistant', content: 'سلام'));
    await engine.newChat();
    await tester.pumpWidget(MssApp(engine: engine));
    await tester.pumpAndSettle();
    expect(find.text('What can I help with?'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Translate hello to Pashto'));
    await tester.pumpAndSettle();
    expect(find.text('سلام'), findsOneWidget);
    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();
    expect(find.text('What can I help with?'), findsOneWidget);
    expect(engine.conversations.length, 1);
    expect(tester.takeException(), isNull);
    await tester.enterText(
        find.byType(TextField), 'Translate to English: سلام');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Download AI'), findsOneWidget);
    expect(find.text('Your AI. Your device.'), findsNothing);
    expect(find.text('Before you begin'), findsNothing);
    expect(engine.conversations.length, 1);
  });
  testWidgets('drawer contains only chat navigation and settings',
      (tester) async {
    await tester.pumpWidget(MssApp(engine: AiEngine()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Search chats'), findsOneWidget);
    expect(find.text('Saved results & settings'), findsNothing);
    expect(find.text('Offline model'), findsNothing);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Download AI'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final settingsContext = tester.element(find.text('Settings'));
    expect(Theme.of(settingsContext).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
