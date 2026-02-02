import 'dart:io';

import 'package:crypt/pages/home.dart';
import 'package:crypt/pages/mnumber_input.dart';
import 'package:crypt/pages/oauth.dart';
import 'package:crypt/pages/otp_number.dart';
import 'package:crypt/pages/qrcode_scan.dart';
import 'package:crypt/pages/sign_document.dart';
import 'package:crypt/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Custom HTTP overrides for handling SSL certificates in debug mode.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (kDebugMode) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        if (kDebugMode) {
          print('Allowing certificate for $host:$port in debug mode');
        }
        return true;
      };
    }
    return client;
  }
}

/// The main entry point of the Dohatec e-Sign application.
Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    Provider<OAuthService>(
      create: (_) => OAuthService(),
      dispose: (_, service) => service.dispose(),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the Dohatec e-Sign application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dohatec e-Sign',
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/mobile-number': (context) => const MobileNumberInputPage(),
        '/qr-scanner': (context) => const QRScannerPage(),
        '/otp-number': (context) => const OtpNumberInputPage(),
        '/sign-document': (context) => const PdfViewer(),
      },
    );
  }
}
