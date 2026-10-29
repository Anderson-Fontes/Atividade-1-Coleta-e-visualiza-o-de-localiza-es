import 'package:localizacoes/features/localizacoes/data/database/banco_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

class RepositorioLocalizacoes {
  RepositorioLocalizacoes({BancoLocalizacoes? banco})
    : _banco = banco ?? BancoLocalizacoes.instancia;

  final BancoLocalizacoes _banco;

  Future<int> inserir(Localizacao localizacao) async {
    final db = await _banco.obterBanco();
    return db.insert(BancoLocalizacoes.nomeTabela, localizacao.toMap());
  }

  /// Retorna as últimas [limite] localizações, da mais recente para a mais antiga.
  Future<List<Localizacao>> consultarUltimas({int limite = 100}) async {
    final db = await _banco.obterBanco();
    final linhas = await db.query(
      BancoLocalizacoes.nomeTabela,
      orderBy: 'instante DESC, id DESC',
      limit: limite,
    );
    return linhas.map(Localizacao.fromMap).toList();
  }

  /// Remove todas as linhas, preservando a tabela e o arquivo do banco.
  Future<int> excluirTodos() async {
    final db = await _banco.obterBanco();
    return db.delete(BancoLocalizacoes.nomeTabela);
  }
}
