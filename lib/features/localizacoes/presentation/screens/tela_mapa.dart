import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/widgets/mapa_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/services/cache_mapa.dart';

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  final MapController _controlador = MapController();

  List<Localizacao> _localizacoes = [];
  FileCacheStore? _armazenamento;
  bool _carregando = true;
  String? _erro;
  bool _mapaPronto = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await _repositorio.consultarUltimas();
      final armazenamento =
          _armazenamento ?? await CacheMapa.obterArmazenamento();

      if (!mounted) return;
      setState(() {
        _localizacoes = lista;
        _armazenamento = armazenamento;
        _carregando = false;
        // Enquanto o indicador de espera ou a mensagem de vazio aparecem,
        // o mapa não existe; ele será recriado e avisará quando estiver pronto.
        _mapaPronto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as localizações.';
        _carregando = false;
      });
    }
  }

  void _enquadrar() => MapaLocalizacoes.enquadrar(_controlador, _localizacoes);

  void _aoMapaPronto() {
    // Chamado pelo mapa depois de construído: enquadra ao carregar os dados.
    if (!mounted) return;
    setState(() => _mapaPronto = true);
    _enquadrar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Enquadrar todos os pontos',
            onPressed: _mapaPronto ? _enquadrar : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar registros',
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) {
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
    if (_localizacoes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma localização salva ainda.\n'
            'Inicie a coleta na tela inicial.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return MapaLocalizacoes(
      controlador: _controlador,
      localizacoes: _localizacoes,
      armazenamento: _armazenamento!,
      aoMapaPronto: _aoMapaPronto,
    );
  }
}
