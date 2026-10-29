import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:localizacoes/features/localizacoes/data/repositories/repositorio_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_localizacoes.dart';
import 'package:localizacoes/features/localizacoes/presentation/screens/tela_mapa.dart';
import 'package:localizacoes/features/localizacoes/services/servico_localizacao.dart';

class TelaColeta extends StatefulWidget {
  const TelaColeta({super.key});

  @override
  State<TelaColeta> createState() => _TelaColetaState();
}

class _TelaColetaState extends State<TelaColeta> {
  final ServicoLocalizacao _servico = ServicoLocalizacao();
  final RepositorioLocalizacoes _repositorio = RepositorioLocalizacoes();
  static final DateFormat _formatoHora = DateFormat('HH:mm:ss');

  StreamSubscription<Position>? _assinatura;
  Future<void> _fila = Future.value(); // serializa as gravações

  bool _coletando = false;
  bool _iniciando = false;
  int _totalSalvas = 0;
  String? _ultimaPosicao;

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  // ---------- Iniciar / Parar ----------

  Future<void> _iniciarColeta() async {
    // Evita assinaturas duplicadas.
    if (_coletando || _iniciando || _assinatura != null) return;

    setState(() => _iniciando = true);

    final resultado = await _servico.verificarPermissoes();
    if (!mounted) return;

    if (resultado != ResultadoPermissao.permitido) {
      setState(() => _iniciando = false);
      await _orientarUsuario(resultado);
      return;
    }

    _assinatura = _servico.obterStreamPosicoes().listen(
      _aoReceberPosicao,
      onError: _aoOcorrerErro,
      cancelOnError: false,
    );

    setState(() {
      _iniciando = false;
      _coletando = true;
    });
  }

  Future<void> _pararColeta() async {
    await _assinatura?.cancel();
    _assinatura = null;
    if (!mounted) return;
    setState(() => _coletando = false);
  }

  // ---------- Recebimento e gravação ----------

  void _aoReceberPosicao(Position posicao) {
    final localizacao = Localizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
      precisao: posicao.accuracy,
      instante: DateTime.now().toUtc(),
    );
    // Cada gravação só começa quando a anterior termina.
    _fila = _fila.then((_) => _gravar(localizacao));
  }

  Future<void> _gravar(Localizacao localizacao) async {
    try {
      await _repositorio.inserir(localizacao);
      if (!mounted) return;
      setState(() {
        _totalSalvas++;
        _ultimaPosicao =
            '${localizacao.latitude.toStringAsFixed(6)}, '
            '${localizacao.longitude.toStringAsFixed(6)} '
            '(${_formatoHora.format(localizacao.instante.toLocal())})';
      });
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Erro ao salvar a posição no banco de dados.');
    }
  }

  Future<void> _aoOcorrerErro(Object erro) async {
    await _pararColeta();
    if (!mounted) return;
    _mostrarMensagem(
      erro is LocationServiceDisabledException
          ? 'O GPS foi desativado. A coleta foi interrompida.'
          : 'Erro na coleta de localização. A coleta foi interrompida.',
    );
  }

  // ---------- Orientação ao usuário ----------

  Future<void> _orientarUsuario(ResultadoPermissao resultado) async {
    final String mensagem;
    final String textoBotao;
    final Future<bool> Function() acao;

    switch (resultado) {
      case ResultadoPermissao.servicoDesativado:
        mensagem = 'O GPS está desativado. Ative a localização do aparelho.';
        textoBotao = 'Abrir configurações';
        acao = _servico.abrirConfiguracoesLocalizacao;
      case ResultadoPermissao.negada:
        mensagem =
            'Sem a permissão de localização não é possível coletar '
            'posições. Tente novamente e permita o acesso.';
        textoBotao = 'Configurações do app';
        acao = _servico.abrirConfiguracoesApp;
      case ResultadoPermissao.negadaParaSempre:
        mensagem =
            'A permissão foi negada permanentemente. Habilite a '
            'localização nas configurações do aplicativo.';
        textoBotao = 'Abrir configurações';
        acao = _servico.abrirConfiguracoesApp;
      case ResultadoPermissao.permitido:
        return;
    }

    await showDialog<void>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Localização necessária'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(contextoDialogo).pop();
              acao();
            },
            child: Text(textoBotao),
          ),
        ],
      ),
    );
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ---------- Navegação ----------

  void _abrirHistorico() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaLocalizacoes(coletaAtiva: _coletando),
      ),
    );
  }

  void _abrirMapa() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TelaMapa()));
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Coleta de localização')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: _coletando
                  ? cores.primaryContainer
                  : cores.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _coletando ? Icons.gps_fixed : Icons.gps_off,
                          color: _coletando ? cores.primary : cores.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _coletando ? 'Coleta ativa' : 'Coleta parada',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Posições salvas nesta sessão: $_totalSalvas'),
                    if (_ultimaPosicao != null) Text('Última: $_ultimaPosicao'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_coletando || _iniciando) ? null : _iniciarColeta,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar coleta'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _coletando ? _pararColeta : null,
              icon: const Icon(Icons.stop),
              label: const Text('Parar coleta'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _abrirHistorico,
              icon: const Icon(Icons.history),
              label: const Text('Consultar histórico'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _abrirMapa,
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _servico.abrirConfiguracoesApp,
              icon: const Icon(Icons.settings),
              label: const Text('Configurações de permissão'),
            ),
          ],
        ),
      ),
    );
  }
}
