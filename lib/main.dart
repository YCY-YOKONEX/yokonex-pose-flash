import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'ui/home_screen.dart';
import 'ui/pose_figure.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PoseFlashApp());
}

class PoseFlashApp extends StatelessWidget {
  const PoseFlashApp({super.key, this.locale});

  /// 留空时跟随系统；测试或宿主集成可显式指定语言。
  final Locale? locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ink,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: teal,
            brightness: Brightness.dark,
          ).copyWith(
            primary: teal,
            secondary: coral,
            surface: mint,
            onSurface: paper,
            outline: line,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: paper,
        displayColor: paper,
        fontFamily: 'sans-serif',
        fontFamilyFallback: ['PingFang SC', 'Microsoft YaHei'],
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: teal,
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontFamily: 'sans-serif',
            fontFamilyFallback: ['PingFang SC', 'Microsoft YaHei'],
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: paper,
          backgroundColor: Colors.transparent,
          selectedForegroundColor: ink,
          selectedBackgroundColor: teal,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: teal,
        inactiveTrackColor: line,
        thumbColor: paper,
        overlayColor: teal.withValues(alpha: .18),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: teal,
        linearTrackColor: line,
      ),
    ),
    home: const HomeScreen(),
  );
}
