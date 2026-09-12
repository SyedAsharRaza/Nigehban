import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../main.dart';
import '../models/verdict.dart';
import '../services/api_service.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../widgets/big_button.dart';
import 'checking_screen.dart';
import 'guardian_screen.dart';
import 'result_screen.dart';
import 'speak_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? _serverOk; // null = checking
  final _speech = SpeechService.instance;

  @override
  void initState() {
    super.initState();
    _probe();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Prefs.onboarded) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen(firstRun: true)));
        await Prefs.setOnboarded(true);
      }
      // Small delay so TTS engine is ready on cold start.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _speech.say(en: S.en('home_speak'), ur: S.ur('home_speak'));
    });
  }

  Future<void> _probe() async {
    setState(() => _serverOk = null);
    final ok = await ApiService.health();
    if (mounted) setState(() => _serverOk = ok);
  }

  // ---------------------------------------------------------------- flows

  void _runCheck({
    required String text,
    Uint8List? bytes,
    String? fileName,
    required CheckSource source,
    String? previewNote,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckingScreen(
        text: text,
        previewNote: previewNote,
        run: () => ApiService.check(text: text, fileBytes: bytes, fileName: fileName, source: source),
        onVerdict: (Verdict v) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ResultScreen(verdict: v, originalText: text),
          ));
        },
      ),
    ));
  }

  Future<void> _pasteFlow() async {
    await _speech.say(en: S.en('paste_speak'), ur: S.ur('paste_speak'));
    if (!mounted) return;
    final controller = TextEditingController();
    // Pre-fill from clipboard if it looks like a message.
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final t = clip?.text?.trim() ?? '';
      if (t.isNotEmpty && t.length < 4000) controller.text = t;
    } catch (_) {}
    if (!mounted) return;
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.message_rounded, color: NColors.paste, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(S.t('btn_paste'), style: Theme.of(ctx).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: () async {
                    final clip = await Clipboard.getData(Clipboard.kTextPlain);
                    controller.text = clip?.text ?? '';
                  },
                  icon: const Icon(Icons.content_paste_rounded),
                  label: Text(S.t('btn_paste_clip')),
                ),
                IconButton(onPressed: () => controller.clear(), icon: const Icon(Icons.close_rounded), tooltip: S.t('btn_clear')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 7,
              minLines: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(hintText: S.t('paste_hint')),
            ),
            const SizedBox(height: 14),
            WideButton(
              icon: Icons.shield_rounded,
              label: S.t('btn_check'),
              color: NColors.brand,
              onTap: () => Navigator.of(ctx).pop(controller.text),
            ),
          ],
        ),
      ),
    );
    if (text == null) return;
    if (text.trim().isEmpty) {
      _speech.say(en: S.en('empty_text'), ur: S.ur('empty_text'));
      return;
    }
    _runCheck(text: text.trim(), source: CheckSource.pastedText);
  }

  Future<void> _speakFlow() async {
    if (!_speech.sttAvailable) {
      await _speech.say(en: S.en('speak_unavailable'), ur: S.ur('speak_unavailable'));
      return _pasteFlow();
    }
    if (!mounted) return;
    final text = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const SpeakScreen()));
    if (text == null || text.trim().isEmpty) return;
    _runCheck(text: text.trim(), source: CheckSource.dictated);
  }

  Future<void> _photoFlow() async {
    await _speech.say(en: S.en('photo_speak'), ur: S.ur('photo_speak'));
    if (!mounted) return;
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: NColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(child: BigButton(icon: Icons.photo_camera_rounded, label: S.t('btn_camera'), color: NColors.photo, onTap: () => Navigator.of(ctx).pop(ImageSource.camera))),
            const SizedBox(width: 16),
            Expanded(child: BigButton(icon: Icons.photo_library_rounded, label: S.t('btn_gallery'), color: NColors.paste, onTap: () => Navigator.of(ctx).pop(ImageSource.gallery))),
          ],
        ),
      ),
    );
    if (src == null) return;
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: src,
        imageQuality: AppConfig.imageQuality,
        maxWidth: AppConfig.imageMaxWidth.toDouble(),
      );
    } catch (_) {
      file = null;
    }
    if (file == null) {
      _speech.say(en: S.en('nothing_selected'), ur: S.ur('nothing_selected'));
      return;
    }
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
    _runCheck(text: '', bytes: bytes, fileName: name, source: CheckSource.image, previewNote: S.t('btn_photo'));
  }

  Future<void> _voiceNoteFlow() async {
    await _speech.say(en: S.en('voice_speak'), ur: S.ur('voice_speak'));
    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ogg', 'opus', 'oga', 'mp3', 'm4a', 'aac', 'wav', 'amr', '3gp', 'mp4', 'webm'],
        withData: true,
      );
    } catch (_) {
      // Some pickers reject custom filters; fall back to the generic audio type.
      try {
        res = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
      } catch (_) {
        res = null;
      }
    }
    final f = res?.files.isNotEmpty == true ? res!.files.first : null;
    Uint8List? bytes = f?.bytes;
    if (bytes == null && f?.path != null) {
      try {
        bytes = await XFile(f!.path!).readAsBytes();
      } catch (_) {}
    }
    if (f == null || bytes == null || bytes.isEmpty) {
      _speech.say(en: S.en('nothing_selected'), ur: S.ur('nothing_selected'));
      return;
    }
    _runCheck(text: '', bytes: bytes, fileName: f.name, source: CheckSource.voiceNote, previewNote: S.t('btn_voice'));
  }

  Future<void> _toggleLang() async {
    await Prefs.setLang(Prefs.lang == 'ur' ? 'en' : 'ur');
    setState(() {});
    _speech.say(en: S.en('home_speak'), ur: S.ur('home_speak'));
  }

  Future<void> _openSettings() async {
    final c = TextEditingController(text: Prefs.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t('settings_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: c, decoration: InputDecoration(labelText: S.t('settings_url')), keyboardType: TextInputType.url),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ActionChip(label: const Text('Vercel'), onPressed: () => c.text = AppConfig.defaultBaseUrl),
              ActionChip(label: const Text('Emulator'), onPressed: () => c.text = AppConfig.emulatorLocalUrl),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.t('btn_save'))),
        ],
      ),
    );
    if (saved == true) {
      await Prefs.setBaseUrl(c.text);
      _probe();
    }
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final ur = Prefs.lang == 'ur';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onLongPress: _openSettings,
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(color: NColors.brand, shape: BoxShape.circle),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.t('app_name'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: NColors.brandDark)),
                            Text(S.t('tagline'), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _probe,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _serverOk == null ? Colors.grey : (_serverOk! ? NColors.safe : NColors.danger),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_serverOk == null ? '…' : (_serverOk! ? S.t('server_ok') : S.t('server_down')), style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton(
                    onPressed: _toggleLang,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 40)),
                    child: Text(S.t('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Prompt
              Text(
                S.t('home_speak'),
                textAlign: TextAlign.center,
                textDirection: ur ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontSize: 19, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 18),
              // 2x2 giant buttons
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(children: [
                        Expanded(child: BigButton(icon: Icons.message_rounded, label: S.t('btn_paste'), color: NColors.paste, height: 170, onTap: _pasteFlow)),
                        const SizedBox(width: 16),
                        Expanded(child: BigButton(icon: Icons.mic_rounded, label: S.t('btn_speak'), color: NColors.speak, height: 170, onTap: _speakFlow)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(children: [
                        Expanded(child: BigButton(icon: Icons.photo_camera_rounded, label: S.t('btn_photo'), color: NColors.photo, height: 170, onTap: _photoFlow)),
                        const SizedBox(width: 16),
                        Expanded(child: BigButton(icon: Icons.graphic_eq_rounded, label: S.t('btn_voice'), color: NColors.voice, height: 170, onTap: _voiceNoteFlow)),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WideButton(
                icon: Icons.family_restroom_rounded,
                label: Prefs.guardianName.isNotEmpty ? '${S.t('btn_guardian')}: ${Prefs.guardianName}' : S.t('btn_guardian'),
                color: Colors.white,
                foreground: NColors.brandDark,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen()));
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
