import 'package:flutter/material.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';

class TelaLocalizacoes extends StatefulWidget {
  const TelaLocalizacoes({super.key, required this.coletaAtiva});

  final bool coletaAtiva;

  @override
  State<TelaLocalizacoes> createState() => _TelaLocalizacoesState();
}

class _TelaLocalizacoesState extends State<TelaLocalizacoes> {
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();

  List<Localizacao> _localizacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _repositorio.consultarUltimas();
      if (!mounted) return;
      setState(() {
        _localizacoes = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o histórico.';
        _carregando = false;
      });
    }
  }

  Future<void> _confirmarLimpeza() async {
    var mensagem =
        'Todos os registros serão apagados, inclusive os anteriores aos 100 '
        'exibidos. Esta operação é permanente.';
    if (widget.coletaAtiva) {
      mensagem +=
          '\n\nA coleta está ativa: novos registros continuarão '
          'sendo salvos.';
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await _repositorio.excluirTodos();
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      _mostrarMensagem('Histórico limpo com sucesso.');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao limpar o histórico.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpar todo o histórico',
            onPressed: _confirmarLimpeza,
          ),
        ],
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    if (_carregando && _localizacoes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: _localizacoes.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Nenhuma localização registrada.')),
              ],
            )
          : ListView.separated(
              itemCount: _localizacoes.length,
              separatorBuilder: (context, indice) => const Divider(height: 1),
              itemBuilder: (context, indice) => ItemLocalizacao(
                localizacao: _localizacoes[indice],
                destaque: indice == 0,
              ),
            ),
    );
  }
}
