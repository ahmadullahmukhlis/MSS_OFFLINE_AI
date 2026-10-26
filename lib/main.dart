import 'package:flutter/material.dart';
import 'core/brand.dart';
import 'services/ai_engine.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final engine = AiEngine();
  await engine.initialize();
  runApp(MssApp(engine: engine));
}

class MssApp extends StatelessWidget {
  const MssApp({super.key, required this.engine});
  final AiEngine engine;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: engine,
        builder: (context, _) => MaterialApp(
          title: 'MSS Offline AI',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(),
          darkTheme: Brand.theme(dark: true),
          themeMode: engine.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: MssShell(engine: engine),
        ),
      );
}
