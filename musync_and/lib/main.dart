import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:musync_and/pages/main_page.dart';
import 'package:musync_and/helpers/audio_player_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'themes.dart';
import 'services/audio_player.dart';
import 'package:intl/date_symbol_data_local.dart';
//import 'services/databasehelper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  modoDeEnergia = prefs.getInt('modo_energia') ?? 0;

  final conf =
      modoDeEnergia != 0
          ? AudioServiceConfig(
            androidNotificationChannelId: 'com.nathandv.musync_and',
            androidNotificationChannelName: 'mediaPlayback',
            androidShowNotificationBadge: true,
            androidStopForegroundOnPause: false,
          )
          : AudioServiceConfig(
            androidNotificationChannelId: 'com.nathandv.musync_and',
            androidNotificationChannelName: 'mediaPlayback',
            androidShowNotificationBadge: true,
            androidNotificationOngoing: true,
          );

  mscAudPl = await AudioService.init(
    builder: () => MusyncAudioHandler(),
    config: conf,
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
