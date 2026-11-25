# J7 Topaz AI Mobile

Projeto Flutter para Android.

## O que esta versão já oferece
- Interface escura estilo J7.
- Seleção de fotos da galeria.
- Seleção e pré-visualização de vídeos.
- Controles visuais de nitidez, redução de ruído, detalhes e brilho.
- Seleção de resolução-alvo (720p, 1080p, 2K e 4K).
- Workflow do GitHub Actions que gera os arquivos Android e compila o APK release.

## Limitação importante
Esta é a primeira base do aplicativo. Os controles ainda são apenas parâmetros de interface: não existe processamento real de super-resolução por IA nem exportação aprimorada nesta versão. Selecionar 4K não converte o arquivo para 4K. A implementação do motor de processamento e exportação é uma etapa posterior.

## Gerar APK pelo GitHub
1. Envie o conteúdo deste ZIP para a raiz do repositório GitHub.
2. Abra a aba **Actions** do repositório.
3. Se necessário, habilite GitHub Actions.
4. Abra **Build J7 APK** e toque em **Run workflow** (ou faça um commit na branch `main`).
5. Quando terminar, abra a execução concluída e baixe o artefato **J7-Topaz-AI-Mobile-APK**.
6. Extraia o ZIP do artefato para encontrar `app-release.apk`.

## Pacotes
- Flutter
- image_picker
- video_player
