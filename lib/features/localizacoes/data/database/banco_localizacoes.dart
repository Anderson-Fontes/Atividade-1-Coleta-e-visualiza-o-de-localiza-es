import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoLocalizacoes {
  BancoLocalizacoes._();

  static final BancoLocalizacoes instancia = BancoLocalizacoes._();

  static const String nomeTabela = 'localizacoes';
  static const String _nomeArquivo = 'localizacoes.db';
  static const int _versao = 1;

  Future<Database>? _abertura;

  /// Devolve a conexão, reutilizando a mesma enquanto ela estiver aberta.
  Future<Database> obterBanco() async {
    try {
      return await (_abertura ??= _abrir());
    } catch (_) {
      _abertura = null; // permite tentar abrir novamente depois
      rethrow;
    }
  }

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();
    final caminho = p.join(pasta, _nomeArquivo);

    return openDatabase(
      caminho,
      version: _versao,
      onCreate: (db, versao) async {
        await db.execute('''
          CREATE TABLE $nomeTabela (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            precisao REAL NOT NULL,
            instante TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
