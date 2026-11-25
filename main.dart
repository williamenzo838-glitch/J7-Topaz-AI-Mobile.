import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';

const bg = Color(0xFF090812);
const panel = Color(0xFF171326);
const purple = Color(0xFF9B6CFF);
const cyan = Color(0xFF52D8F2);

void main() => runApp(const J7App());

class J7App extends StatelessWidget {
  const J7App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'J7 Topaz AI Mobile',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: purple, brightness: Brightness.dark),
      sliderTheme: const SliderThemeData(activeTrackColor: purple, thumbColor: cyan),
      appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const videoChannel = MethodChannel('j7.topaz/video');
  final picker = ImagePicker();
  File? photo, video, output;
  VideoPlayerController? player;
  bool busy = false;
  String status = 'Pronto para aprimorar';
  double sharp = 45, denoise = 30, fidelity = 80;
  String scale = '2x';
  int tab = 0;

  Future<void> pickPhoto() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (x != null) setState(() { photo = File(x.path); video = null; output = null; status = 'Imagem carregada'; });
  }

  Future<void> pickVideo() async {
    final x = await picker.pickVideo(source: ImageSource.gallery);
    if (x != null) {
      await player?.dispose();
      video = File(x.path); photo = null; output = null;
      player = VideoPlayerController.file(video!);
      await player!.initialize();
      if (mounted) setState(() => status = 'Vídeo carregado');
    }
  }

  Future<void> enhancePhoto() async {
    if (photo == null || busy) return;
    setState(() { busy = true; status = 'Processando imagem…'; });
    try {
      final bytes = await photo!.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Formato de imagem não suportado.');
      final factor = scale == '4x' ? 4 : scale == '2x' ? 2 : 1;
      final maxSide = 3840;
      final targetW = math.min(decoded.width * factor, maxSide);
      final targetH = math.min(decoded.height * factor, maxSide);
      var processed = img.copyResize(decoded, width: targetW, height: targetH, interpolation: img.Interpolation.cubic);
      processed = _sharpen(processed, sharp / 100);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/J7_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(img.encodeJpg(processed, quality: 95), flush: true);
      if (!mounted) return;
      setState(() { output = file; status = 'Imagem aprimorada e salva no app'; });
    } catch (e) {
      if (mounted) setState(() => status = 'Erro: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  img.Image _sharpen(img.Image source, double amount) {
    if (amount <= 0.01 || source.width < 3 || source.height < 3) return source;
    final out = img.Image(width: source.width, height: source.height);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final c = source.getPixel(x, y);
        if (x == 0 || y == 0 || x == source.width - 1 || y == source.height - 1) {
          out.setPixel(x, y, c); continue;
        }
        final n = source.getPixel(x, y - 1), s = source.getPixel(x, y + 1);
        final w = source.getPixel(x - 1, y), e = source.getPixel(x + 1, y);
        int channel(num center, num a, num b, num d, num f) =>
          (center * (1 + 4 * amount) - (a + b + d + f) * amount).round().clamp(0, 255);
        out.setPixelRgb(x, y,
          channel(c.r, n.r, s.r, w.r, e.r),
          channel(c.g, n.g, s.g, w.g, e.g),
          channel(c.b, n.b, s.b, w.b, e.b));
      }
    }
    return out;
  }

  Future<void> enhanceVideo() async {
    if (video == null || busy) return;
    setState(() { busy = true; status = 'Preparando exportação de vídeo…'; });
    try {
      final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final path = '${dir.path}/J7_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final result = await videoChannel.invokeMethod<String>('enhance', {
        'input': video!.path, 'output': path, 'height': 2160,
        'sharpness': sharp, 'denoise': denoise, 'fidelity': fidelity,
      });
      if (result == null) throw Exception('O processamento foi cancelado.');
      if (!mounted) return;
      setState(() { output = File(result); status = 'Vídeo exportado em: $result'; });
    } on PlatformException catch (e) {
      if (mounted) setState(() => status = 'Falha no vídeo: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => status = 'Falha no vídeo: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { player?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(gradient: const LinearGradient(colors: [purple, cyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_awesome, color: Colors.black, size: 21)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('J7 TOPAZ AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          Text('MOBILE ENHANCER', style: TextStyle(fontSize: 9, color: cyan, letterSpacing: 2)),
        ]),
      ]),
      actions: [IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'J7 Topaz AI Mobile', applicationVersion: '1.0.0', children: const [Text('Aprimoramento local de imagens e exportação de vídeo via Android Media3. Não usa os modelos proprietários do Topaz.')]), icon: const Icon(Icons.info_outline))],
    ),
    body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF28194A), Color(0xFF111827)]), border: Border.all(color: purple.withOpacity(.35))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('REMASTER STUDIO', style: TextStyle(color: cyan, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Dê uma nova vida\\naos seus arquivos.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 8),
        Text('Fotos e vídeos • Saída até 4K • Processamento no dispositivo', style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12)),
      ])),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _modeButton('FOTO', Icons.image_outlined, tab == 0, () => setState(() => tab = 0))),
        const SizedBox(width: 10),
        Expanded(child: _modeButton('VÍDEO', Icons.movie_outlined, tab == 1, () => setState(() => tab = 1))),
      ]),
      const SizedBox(height: 14),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('01  •  ARQUIVO DE ORIGEM', style: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (tab == 0 && photo != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(photo!, height: 190, width: double.infinity, fit: BoxFit.contain))
        else if (tab == 1 && player?.value.isInitialized == true) AspectRatio(aspectRatio: player!.value.aspectRatio, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: VideoPlayer(player!)))
        else Container(height: 130, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(.035), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(tab == 0 ? Icons.add_photo_alternate_outlined : Icons.video_library_outlined, size: 34, color: purple), const SizedBox(height: 8), const Text('Selecione um arquivo da galeria', style: TextStyle(color: Colors.white60, fontSize: 12))])),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: busy ? null : (tab == 0 ? pickPhoto : pickVideo), icon: const Icon(Icons.folder_open), label: Text(tab == 0 ? 'ESCOLHER IMAGEM' : 'ESCOLHER VÍDEO'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: purple)))),
      ])),
      const SizedBox(height: 14),
      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('02  •  AJUSTES DE REMASTERIZAÇÃO', style: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        const Text('Escala de saída', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: ['Original', '2x', '4x'].map((v) => ChoiceChip(label: Text(v), selected: scale == v, onSelected: (_) => setState(() => scale = v), selectedColor: purple.withOpacity(.35))).toList()),
        const SizedBox(height: 12),
        _slider('Nitidez', sharp, (v) => setState(() => sharp = v), Icons.center_focus_strong),
        _slider('Redução de ruído', denoise, (v) => setState(() => denoise = v), Icons.blur_off),
        _slider('Fidelidade ao original', fidelity, (v) => setState(() => fidelity = v), Icons.tune),
        const SizedBox(height: 4),
        Text(tab == 0 ? 'Fotos: redimensionamento de alta qualidade e nitidez por filtro.' : 'Vídeos: transcodificação Android Media3 com saída em altura de até 2160p.', style: TextStyle(color: Colors.white.withOpacity(.48), fontSize: 11)),
      ])),
      const SizedBox(height: 14),
      SizedBox(height: 54, child: FilledButton.icon(
        onPressed: busy || (tab == 0 ? photo == null : video == null) ? null : (tab == 0 ? enhancePhoto : enhanceVideo),
        icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high),
        label: Text(busy ? 'PROCESSANDO…' : 'APRIMORAR ${tab == 0 ? 'IMAGEM' : 'VÍDEO'}'),
        style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      )),
      const SizedBox(height: 12),
      _panel(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.monitor_heart_outlined, color: cyan, size: 19),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('STATUS DO PROCESSAMENTO', style: TextStyle(fontSize: 10, color: cyan, letterSpacing: 1, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(status, style: const TextStyle(fontSize: 12))])),
      ])),
      if (output != null) ...[
        const SizedBox(height: 14),
        _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('03  •  RESULTADO', style: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          if (output!.path.toLowerCase().endsWith('.jpg')) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(output!, height: 190, width: double.infinity, fit: BoxFit.contain)),
          Text(output!.path, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          const SizedBox(height: 8),
          const Text('O arquivo foi salvo no armazenamento do aplicativo. Compartilhe para enviar à galeria, nuvem ou outro app.', style: TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Share.shareXFiles([XFile(output!.path)], text: 'Criado com J7 Topaz AI Mobile'),
            icon: const Icon(Icons.share), label: const Text('COMPARTILHAR / SALVAR'),
          )),
        ])),
      ],
      const SizedBox(height: 18),
      const Center(child: Text('J7 LABS  •  BUILD 1.0.0', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2))),
    ])),
  );

  Widget _modeButton(String title, IconData icon, bool selected, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: selected ? purple.withOpacity(.2) : panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? purple : Colors.white12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: selected ? cyan : Colors.white60), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.white60, letterSpacing: 1))])));
  Widget _panel({required Widget child}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.07))), child: child);
  Widget _slider(String label, double value, ValueChanged<double> onChanged, IconData icon) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 15, color: purple), const SizedBox(width: 7), Expanded(child: Text(label, style: const TextStyle(fontSize: 12))), Text('${value.round()}%', style: const TextStyle(fontSize: 11, color: cyan, fontWeight: FontWeight.bold))]),
    Slider(value: value, min: 0, max: 100, onChanged: onChanged),
  ]);
}
