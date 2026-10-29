import 'package:flutter/material.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_coleta.dart';

class AppLocalizacoes extends StatelessWidget {
  const AppLocalizacoes({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const TelaColeta(),
    );
  }
}
