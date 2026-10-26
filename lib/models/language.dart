import 'package:flutter/widgets.dart';

enum AppLanguage {
  pashto('Pashto', 'پښتو', 'ps', true),
  dari('Dari', 'دری', 'fa-AF', true),
  english('English', 'English', 'en', false),
  german('German', 'Deutsch', 'de', false);

  const AppLanguage(this.name, this.nativeName, this.code, this.rtl);
  final String name;
  final String nativeName;
  final String code;
  final bool rtl;
  TextDirection get direction => rtl ? TextDirection.rtl : TextDirection.ltr;
  static AppLanguage fromCode(String? code,
      {AppLanguage fallback = AppLanguage.english}) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return fallback;
  }
}

enum WritingMode {
  paragraph('Paragraph', 'Create a polished, coherent paragraph', 'edit_note'),
  email('Email', 'Compose a professional email', 'mail_outline'),
  rewrite('Improve', 'Correct grammar, clarity, and tone', 'auto_fix_high'),
  summary('Summarize', 'Make text concise and clear', 'subject');

  const WritingMode(this.name, this.hint, this.iconName);
  final String name;
  final String hint;
  final String iconName;
}
