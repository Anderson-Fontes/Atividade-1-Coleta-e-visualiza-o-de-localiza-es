import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum ResultadoPermissao {
  permitido,
  servicoDesativado,
  negada,
  negadaParaSempre,
}

class ServicoLocalizacao {
  Future<ResultadoPermissao> verificarPermissoes() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) return ResultadoPermissao.servicoDesativado;

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      return ResultadoPermissao.negadaParaSempre;
    }
    if (permissao == LocationPermission.denied) {
      return ResultadoPermissao.negada;
    }

    // Android 13+: sem esta permissão a notificação do serviço fica oculta.
    // Não bloqueamos a coleta se o usuário recusar.
    await Permission.notification.request();

    return ResultadoPermissao.permitido;
  }

  Stream<Position> obterStreamPosicoes() {
    final LocationSettings configuracao;

    if (defaultTargetPlatform == TargetPlatform.android) {
      configuracao = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Coleta de localização ativa',
          notificationText: 'Registrando sua posição a cada 20 segundos.',
          notificationIcon: AndroidResource(
            name: 'ic_localizacoes',
            defType: 'mipmap',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else {
      configuracao = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    return Geolocator.getPositionStream(locationSettings: configuracao);
  }

  Future<bool> abrirConfiguracoesApp() => Geolocator.openAppSettings();

  Future<bool> abrirConfiguracoesLocalizacao() =>
      Geolocator.openLocationSettings();
}
