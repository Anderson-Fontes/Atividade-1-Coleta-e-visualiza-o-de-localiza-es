import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:latlong2/latlong.dart';
import 'package:localizacoes/features/localizacoes/models/localizacao.dart';
import 'package:localizacoes/features/localizacoes/presentation/widgets/item_localizacao.dart';

class MapaLocalizacoes extends StatelessWidget {
  const MapaLocalizacoes({
    super.key,
    required this.controlador,
    required this.localizacoes,
    required this.armazenamento,
    required this.aoMapaPronto,
  });

  final MapController controlador;
  final List<Localizacao> localizacoes; // índice 0 = mais recente
  final FileCacheStore armazenamento;
  final VoidCallback aoMapaPronto;

  /// Ajusta a câmera para mostrar todos os pontos.
  static void enquadrar(
    MapController controlador,
    List<Localizacao> localizacoes,
  ) {
    if (localizacoes.isEmpty) return;
    final pontos = localizacoes
        .map((l) => LatLng(l.latitude, l.longitude))
        .toList();
    final limites = LatLngBounds.fromPoints(pontos);

    // Ponto único (ou todos iguais): não existe "área" para enquadrar.
    if (limites.north == limites.south && limites.east == limites.west) {
      controlador.move(pontos.first, 16);
      return;
    }
    controlador.fitCamera(
      CameraFit.bounds(bounds: limites, padding: const EdgeInsets.all(48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCenter: LatLng(
          localizacoes.first.latitude,
          localizacoes.first.longitude,
        ),
        initialZoom: 16,
        maxZoom: 19,
        onMapReady: aoMapaPronto,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // Identifica o app para o provedor (exigência do OSM).
          userAgentPackageName: 'br.edu.fatec.localizacoes',
          tileProvider: CachedTileProvider(store: armazenamento),
        ),
        MarkerLayer(markers: _criarMarcadores(context)),
        // Atribuição obrigatória do OpenStreetMap.
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors'),
        ),
      ],
    );
  }

  List<Marker> _criarMarcadores(BuildContext context) {
    // Percorre do mais antigo ao mais recente: o vermelho (índice 0) é
    // desenhado por último e fica por cima dos outros.
    return [
      for (var i = localizacoes.length - 1; i >= 0; i--)
        Marker(
          point: LatLng(localizacoes[i].latitude, localizacoes[i].longitude),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter, // a ponta do pino fica no ponto
          child: GestureDetector(
            onTap: () => _mostrarDetalhes(context, localizacoes[i], i == 0),
            child: Icon(
              Icons.location_on,
              size: 40,
              color: i == 0 ? Colors.red : Colors.blue.shade700,
            ),
          ),
        ),
    ];
  }

  void _mostrarDetalhes(
    BuildContext context,
    Localizacao localizacao,
    bool maisRecente,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ItemLocalizacao(localizacao: localizacao, destaque: maisRecente),
      ),
    );
  }
}
