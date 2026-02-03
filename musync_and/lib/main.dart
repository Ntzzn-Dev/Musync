import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/pages/main_page.dart';
import 'package:musync_and/services/audio_player_organize.dart';
import 'themes.dart';
import 'services/audio_player.dart';
import 'package:intl/date_symbol_data_local.dart';
//import 'services/databasehelper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audPl = await AudioService.init(
    builder: () => MusyncAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nathandv.musync_and',
      androidNotificationChannelName: 'mediaPlayback',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false,
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
      home: MusicPage(),
    );
  }
}
