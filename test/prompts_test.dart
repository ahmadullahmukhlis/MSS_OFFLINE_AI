import 'package:flutter_test/flutter_test.dart';
import 'package:mss_offline_ai/core/prompts.dart';
import 'package:mss_offline_ai/models/language.dart';
import 'package:mss_offline_ai/models/record.dart';

void main() {
  test('all four languages have unique identifiers', () {
    expect(AppLanguage.values.length, 4);
    expect(AppLanguage.values.map((e) => e.code).toSet().length, 4);
  });

  test('all 12 language directions generate a non-empty prompt', () {
    var count = 0;
    for (final source in AppLanguage.values) {
      for (final target in AppLanguage.values) {
        if (source == target) continue;
        final prompt = AiPrompts.translation(source, target, 'Hello');
        expect(prompt, contains(source.name));
        expect(prompt, contains(target.name));
        count++;
      }
    }
    expect(count, 12);
  });

  test('translator prompts explicitly request Afghan Dari', () {
    final prompt =
        AiPrompts.translation(AppLanguage.english, AppLanguage.dari, 'Hello');
    expect(prompt, contains('Afghan Dari'));
    expect(prompt, contains('English'));
  });

  test('writing prompt chooses language and intent', () {
    final prompt = AiPrompts.writing(
        WritingMode.email, AppLanguage.german, 'A meeting invitation');
    expect(prompt, contains('professional'));
    expect(prompt, contains('German'));
  });

  test('chat context is capped for small memory devices', () {
    final chat = List.generate(
        18, (i) => LocalChatMessage(role: 'user', content: 'Message $i'));
    final prompt = AiPrompts.chat(chat, AppLanguage.pashto);
    expect(prompt.length, 7);
    expect(prompt.last.content, 'Message 17');
  });

  test('history JSON survives save and load', () {
    final original = [
      AiRecord(
          id: '1',
          mode: 'writing',
          input: 'Hello',
          output: 'Hallo',
          createdAt: DateTime(2026, 10, 25),
          subtitle: 'German')
    ];
    final decoded = AiRecord.decode(AiRecord.encode(original));
    expect(decoded.single.output, 'Hallo');
    expect(decoded.single.createdAt.year, 2026);
  });
}
