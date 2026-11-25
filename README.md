# J7 Topaz AI Mobile

Projeto Flutter para Android, preparado para compilar APK pelo GitHub Actions.

## O que funciona nesta primeira versão
- Seleção de fotos e vídeos da galeria.
- Fotos: redimensionamento bicúbico até limite de 3840 px no lado maior e filtro de nitidez configurável.
- Vídeos: transcodificação H.264/AAC com AndroidX Media3 Transformer e saída com altura de até 2160 px (4K UHD para conteúdo horizontal).
- Interface escura J7, controles e status de processamento.

## Limitações importantes
Esta versão NÃO contém os modelos de IA proprietários do Topaz. Os controles de redução de ruído e fidelidade são exibidos na interface, mas ainda não estão conectados a modelos de IA; a nitidez é aplicada no processamento de fotos. A exportação de vídeo faz upscale/transcodificação por Media3, não super-resolução neural. Em um Redmi 13C, 4K pode exigir muito tempo, espaço e memória e pode não ser suportado por todos os arquivos de origem. O tamanho final nunca recupera detalhes que não existiam na origem.

## Gerar APK usando somente o celular
1. Baixe e extraia `J7_Topaz_AI_Mobile.zip`.
2. Abra github.com no navegador e crie um repositório novo chamado `J7-Topaz-AI-Mobile`.
3. Envie o conteúdo da pasta do projeto para a raiz do repositório (o arquivo `pubspec.yaml` deve ficar na raiz).
4. Abra a aba **Actions** do repositório e permita executar workflows, se o GitHub pedir.
5. O workflow **Build J7 Android APK** inicia após o envio. Também pode abrir Actions, selecionar o workflow e tocar em **Run workflow**.
6. Quando terminar com sucesso, abra a execução, desça até **Artifacts** e baixe `J7-Topaz-AI-Mobile-APK`.
7. Extraia o ZIP baixado e instale `app-release.apk`. Se o Android bloquear, permita instalar apps dessa origem nas configurações.

## Compilar localmente
Com Flutter instalado: `flutter pub get` e `flutter build apk --release`.

## Identificador
`com.j7.topaz_ai_mobile`
