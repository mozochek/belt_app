import 'package:belt_app/features/core/presentation/photos_scope.dart';
import 'package:belt_app/features/photos_overview/presentation/photos_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Demo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: .0,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
        ),
      ),
      builder: (context, child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: theme.scaffoldBackgroundColor,
              titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                color: Colors.black,
              ),
            ),
          ),
          child: PhotosScope(child: child!),
        );
      },
      home: const PhotosOverviewScreen(),
    );
  }
}
