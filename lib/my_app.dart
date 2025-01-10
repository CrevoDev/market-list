import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state_management/my_app_state.dart';
import 'my_home_page.dart';
import 'services/google_sheets_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoogleSheetsService>(
      future: GoogleSheetsService.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Erro ao inicializar o Google Sheets')),
            ),
          );
        } else {
          return ChangeNotifierProvider(
            create: (context) => MyAppState(snapshot.data!),
            child: MaterialApp(
              title: 'Namer App',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.deepPurpleAccent,
                  elevation: 4,
                  centerTitle: true,
                  toolbarHeight: 70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              home: MyHomePage(),
            ),
          );
        }
      },
    );
  }
}
