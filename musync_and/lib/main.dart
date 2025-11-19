import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/pages/main_page.dart';
import 'themes.dart';
import 'services/audio_player_base.dart';
import 'package:intl/date_symbol_data_local.dart';

MusyncAudioHandler _audioHandler = MusyncAudioHandler();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => MusyncAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.nathandv.musync_and',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  await initializeDateFormatting('pt_BR', null);
  //await DatabaseHelper().deleteDatabaseFile();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musync',
      theme: lighttheme(),
      darkTheme: darktheme(),
      themeMode: ThemeMode.system,
      home: MusicPage(audioHandler: _audioHandler),
    );
  }
}
