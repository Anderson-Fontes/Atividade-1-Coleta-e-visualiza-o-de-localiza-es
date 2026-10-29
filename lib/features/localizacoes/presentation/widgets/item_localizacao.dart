import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';

class ItemLocalizacao extends StatelessWidget {
  const ItemLocalizacao({
    super.key,
    required this.localizacao,
    this.destaque = false,
  });

  final Localizacao localizacao;
  final bool destaque;

  static final DateFormat _formatoData = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final l = localizacao;
    return ListTile(
      leading: Icon(
        Icons.location_on,
        color: destaque ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      // toLocal(): o banco guarda UTC, aqui convertemos para o horário local.
      title: Text(_formatoData.format(l.instante.toLocal())),
      subtitle: Text(
        'Latitude: ${l.latitude.toStringAsFixed(6)}\n'
        'Longitude: ${l.longitude.toStringAsFixed(6)}\n'
        'Precisão: ${l.precisao.toStringAsFixed(1)} m',
      ),
      isThreeLine: true,
    );
  }
}
