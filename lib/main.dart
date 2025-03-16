import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'providers/repository_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  
  runApp(MyApp(storageService: storageService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  
  const MyApp({Key? key, required this.storageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RepositoryProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp(
                title: AppConstants.appName,
                theme: AppTheme.getLightTheme(
                  useDynamicColor: themeProvider.useDynamicColor, 
                  seedColor: themeProvider.seedColor,
                  dynamicLightColorScheme: lightDynamic,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  useDynamicColor: themeProvider.useDynamicColor, 
                  seedColor: themeProvider.seedColor,
                  dynamicDarkColorScheme: darkDynamic,
                ),
                themeMode: themeProvider.themeMode,
                home: const HomeScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}