import 'dart:io';

import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CacheMapa {
  CacheMapa._();

  static Future<FileCacheStore>? _preparacao;

  static Future<FileCacheStore> obterArmazenamento() async {
    try {
      return await (_preparacao ??= _preparar());
    } catch (_) {
      _preparacao = null; // permite nova tentativa
      rethrow;
    }
  }

  static Future<FileCacheStore> _preparar() async {
    // Pasta de cache PRIVADA do aplicativo (outros apps não acessam).
    final base = await getApplicationCacheDirectory();
    final pasta = Directory(p.join(base.path, 'tiles_mapa'));
    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    return FileCacheStore(pasta.path);
  }
}
