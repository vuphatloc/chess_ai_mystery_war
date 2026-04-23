import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure audio to use the media volume stream on all platforms.
  // Without this, Android may use the ringer stream (silent when ringer is off).
  AudioPlayer.global.setAudioContext(AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {},
    ),
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: ChessAIMysteryWarApp(),
    ),
  );
}

class ChessAIMysteryWarApp extends StatelessWidget {
  const ChessAIMysteryWarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess AI: Mystery War',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainScreen(),
    );
  }
}
