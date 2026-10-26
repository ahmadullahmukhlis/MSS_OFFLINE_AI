import '../models/language.dart';
import '../models/record.dart';

/// The model is a text generator, not a guaranteed certified translator.
/// Prompts are deliberately short to reduce memory/context on 2 GB devices.
class AiPrompts {
  static String translation(
          AppLanguage source, AppLanguage target, String text) =>
      'You are a careful professional translator. Translate from ${source.name} (${source.nativeName}) '
      'to ${target.name} (${target.nativeName}). Preserve meaning, names, dates, numbers and tone. '
      'Use natural ${target.name} language. Dari means Afghan Dari; Pashto means Afghan Pashto. '
      'Return ONLY the translation, without commentary.\n\nText:\n$text';

  static String writing(WritingMode mode, AppLanguage language, String text) {
    final task = switch (mode) {
      WritingMode.paragraph =>
        'Write one polished original paragraph based on these instructions',
      WritingMode.email =>
        'Write a professional, ready-to-send email based on these instructions',
      WritingMode.rewrite =>
        'Improve grammar, style, fluency and clarity while preserving the meaning of the text',
      WritingMode.summary =>
        'Summarize the text clearly without inventing facts',
    };
    return '$task. Write exclusively in ${language.name} (${language.nativeName}). '
        'For Dari use natural Afghan Dari; for Pashto use natural Afghan Pashto. '
        'Give the result only, without an introduction.\n\n$text';
  }

  static List<LocalChatMessage> chat(
          List<LocalChatMessage> messages, AppLanguage language) =>
      [
        LocalChatMessage(
          role: 'system',
          content:
              'You are MSS Offline AI, a helpful, careful writing and language assistant. '
              'Follow instructions in the message: answer questions, translate, write, rewrite or summarize. '
              'For translation, detect the source language and use the target language requested in the message, '
              'including Pashto, English, Dari, German or another language. Return only the translation unless asked to explain. '
              'If the target is missing and cannot be inferred from the conversation, ask which language to use. '
              'Otherwise reply in the user’s language. '
              'For Dari use Afghan Dari. For Pashto use Afghan Pashto. '
              'If uncertain, say so briefly. Do not claim internet access or current knowledge. /no_think',
        ),
        ...messages
            .where((e) => e.content.trim().isNotEmpty)
            .toList()
            .reversed
            .take(6)
            .toList()
            .reversed,
      ];
}
