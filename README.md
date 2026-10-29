# Localizações – Atividade 1

Programação para Dispositivos Móveis II – Fatec – Prof. Arley

## Integrantes

- Anderson Fontes Fernandes Júnior

## Sobre

Aplicativo Flutter (Android) que coleta a localização do aparelho de forma
contínua (stream de posições, alta precisão, intervalo solicitado de 20 s),
salva cada posição em SQLite (`localizacoes.db`, tabela `localizacoes`) e
permite consultar o histórico (últimas 100) em lista e em mapa interativo.

- Coleta em primeiro plano no Android, com notificação visível
- Histórico com data/hora locais, latitude/longitude (6 casas) e precisão (1 casa)
- Limpeza de todo o histórico com confirmação
- Mapa com camada de ruas (OpenStreetMap), cache de tiles em pasta privada do app
  e atribuição "© OpenStreetMap contributors"
- Ícone próprio do aplicativo

## Organização do código

    lib/
    ├── main.dart / app.dart
    └── features/localizacoes/
        ├── models/            Localizacao (modelo tipado)
        ├── data/database/     BancoLocalizacoes (abre o SQLite)
        ├── data/repositories/ RepositorioLocalizacoes (inserir, consultar, excluir)
        ├── services/          ServicoLocalizacao (GPS/permissões/stream), CacheMapa
        └── presentation/      telas (coleta, histórico, mapa) e widgets

## Como executar

    flutter pub get
    flutter run

Use um emulador Android ou um aparelho físico (o SQLite e o GPS não funcionam
no navegador).
