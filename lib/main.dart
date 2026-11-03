import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/emulator_config.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/analise/data/limpeza_copias_seletor.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sem await: a varredura de cópias órfãs do seletor (RNF01) nunca lança
  // e não deve atrasar a abertura do app.
  unawaited(LimpezaCopiasSeletor.executar());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final emuladores = EmulatorConfig.emuladores;
  final emuladorAuth = emuladores.auth;
  if (emuladorAuth != null) {
    await FirebaseAuth.instance.useAuthEmulator(
      emuladorAuth.host,
      emuladorAuth.porta,
    );
  }
  final emuladorFirestore = emuladores.firestore;
  if (emuladorFirestore != null) {
    FirebaseFirestore.instance.useFirestoreEmulator(
      emuladorFirestore.host,
      emuladorFirestore.porta,
    );
  }
  runApp(const PhizeApp());
}

class PhizeApp extends StatelessWidget {
  const PhizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phize',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
