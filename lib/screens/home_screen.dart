import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/verdict.dart';
import '../services/api_service.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ui.dart';
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
  bool? _serverOk;
  final _speech = SpeechService.instance;

  @override
  void initState() {
    super.initState();
    _probe();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!Prefs.onboarded && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen(firstRun: true)));
        await Prefs.setOnboarded(true);
        if (mounted) setState(() {});
      }
      // No unprompted speech on the home screen — the app talks when it has something to say.
    });
  }

  Future<void> _probe() async {
    setState(() => _serverOk = null);
    final ok = await ApiService.health();
    if (mounted) setState(() => _serverOk = ok);
  }

  // ------------------------------------------------------------------ flows

  void _runCheck({required String text, Uint8List? bytes, String? fileName, required CheckSource source, String? previewNote}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckingScreen(
        text: text,
        previewNote: previewNote,
        run: () => ApiService.check(text: text, fileBytes: bytes, fileName: fileName, source: source),
        onVerdict: (Verdict v) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(verdict: v, originalText: text))),
      ),
    ));
  }

  Future<void> _pasteFlow() async {
    final controller = TextEditingController(); // starts empty — the user chooses to paste
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: N.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: N.message.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.chat_rounded, color: N.message, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(S.t('btn_paste'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              TextButton.icon(
                onPressed: () async {
                  final clip = await Clipboard.getData(Clipboard.kTextPlain);
                  controller.text = clip?.text ?? '';
                },
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: Text(S.t('btn_paste_clip')),
              ),
              IconButton(onPressed: controller.clear, icon: const Icon(Icons.close_rounded), tooltip: S.t('btn_clear')),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 7,
              minLines: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 16.5, height: 1.4),
              decoration: InputDecoration(hintText: S.t('paste_hint')),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: S.t('btn_check'), icon: Icons.shield_rounded, onTap: () => Navigator.of(ctx).pop(controller.text)),
          ],
        ),
      ),
    );
    if (text == null) return;
    if (text.trim().isEmpty) {
      _toast(S.t('empty_text'));
      return;
    }
    _runCheck(text: text.trim(), source: CheckSource.pastedText);
  }

  Future<void> _speakFlow() async {
    if (!_speech.sttAvailable) {
      _toast(S.t('speak_unavailable'));
      return _pasteFlow();
    }
    final text = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const SpeakScreen()));
    if (text == null || text.trim().isEmpty) return;
    _runCheck(text: text.trim(), source: CheckSource.dictated);
  }

  Future<void> _photoFlow() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: N.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ActionTile(icon: Icons.photo_camera_rounded, label: S.t('btn_camera'), caption: '', color: N.photo, onTap: () => Navigator.of(ctx).pop(ImageSource.camera))),
              const SizedBox(width: 12),
              Expanded(child: ActionTile(icon: Icons.photo_library_rounded, label: S.t('btn_gallery'), caption: '', color: N.message, onTap: () => Navigator.of(ctx).pop(ImageSource.gallery))),
            ]),
          ]),
        ),
      ),
    );
    if (src == null) return;
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: src, imageQuality: AppConfig.imageQuality, maxWidth: AppConfig.imageMaxWidth.toDouble());
    } catch (_) {
      file = null;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _runCheck(text: '', bytes: bytes, fileName: file.name.isNotEmpty ? file.name : 'photo.jpg', source: CheckSource.image, previewNote: S.t('btn_photo'));
  }

  Future<void> _voiceNoteFlow() async {
    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ogg', 'opus', 'oga', 'mp3', 'm4a', 'aac', 'wav', 'amr', '3gp', 'mp4', 'webm'],
        withData: true,
      );
    } catch (_) {
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
    if (f == null || bytes == null || bytes.isEmpty) return;
    _runCheck(text: '', bytes: bytes, fileName: f.name, source: CheckSource.voiceNote, previewNote: S.t('btn_voice'));
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openSettings() async {
    bool voice = Prefs.voiceOn;
    String lang = Prefs.lang;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(lang == 'ur' ? S.ur('settings_title') : S.en('settings_title')),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(lang == 'ur' ? S.ur('language_label') : S.en('language_label'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: N.ink2)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ur', label: Text('اردو', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                ButtonSegment(value: 'en', label: Text('English', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              ],
              selected: {lang},
              onSelectionChanged: (v) => setS(() => lang = v.first),
              style: SegmentedButton.styleFrom(selectedBackgroundColor: N.brandSoft, selectedForegroundColor: N.brandDark),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_rounded, color: N.brand),
              title: Text(lang == 'ur' ? S.ur('voice_toggle') : S.en('voice_toggle'), style: const TextStyle(fontSize: 15)),
              value: voice,
              activeThumbColor: N.brand,
              onChanged: (v) => setS(() => voice = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang == 'ur' ? S.ur('btn_cancel') : S.en('btn_cancel'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lang == 'ur' ? S.ur('btn_save') : S.en('btn_save'))),
          ],
        ),
      ),
    );
    if (saved == true) {
      await Prefs.setLang(lang);
      await Prefs.setVoiceOn(voice);
      if (mounted) setState(() {});
    }
  }

  /// Hidden (long-press the logo/title): backend URL for demo-day fallback. Not part of the user-facing UI.
  Future<void> _openDeveloper() async {
    final c = TextEditingController(text: Prefs.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Developer'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: c, decoration: const InputDecoration(labelText: 'Backend URL'), keyboardType: TextInputType.url, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(label: const Text('Vercel'), onPressed: () => c.text = AppConfig.defaultBaseUrl),
            ActionChip(label: const Text('Emulator'), onPressed: () => c.text = AppConfig.emulatorLocalUrl),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      await Prefs.setBaseUrl(c.text);
      _probe();
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final ur = Prefs.lang == 'ur';
    final dir = ur ? TextDirection.rtl : TextDirection.ltr;
    final hasGuardian = Prefs.guardianPhone.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ---- header
                  Row(children: [
                    GestureDetector(
                      onLongPress: _openDeveloper,
                      child: Image.asset('assets/brand/logo_1024.png', width: 40, height: 40),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: _openDeveloper,
                        child: Text(S.t('app_name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: N.brandDark)),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.tune_rounded, color: N.ink2, size: 22),
                      tooltip: S.t('settings_title'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // ---- hero
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [N.brand, N.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: N.shadow,
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(S.t('hero_title'), textDirection: dir, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2)),
                          const SizedBox(height: 6),
                          Text(S.t('hero_sub'), textDirection: dir, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.45)),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _probe,
                            borderRadius: BorderRadius.circular(999),
                            child: Pill(
                              icon: Icons.circle,
                              text: _serverOk == null ? '…' : (_serverOk! ? S.t('server_ok') : S.t('server_down')),
                              color: _serverOk == null ? Colors.white70 : (_serverOk! ? const Color(0xFF9BE7B8) : const Color(0xFFFFB4B4)),
                              bg: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      const Motion('scan', size: 92, fallbackColor: Colors.white),
                    ]),
                  ),
                  const SizedBox(height: 22),

                  // ---- actions
                  Text(S.t('section_check'), textDirection: dir, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: N.ink2)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: ActionTile(icon: Icons.chat_rounded, label: S.t('btn_paste'), caption: S.t('cap_paste'), color: N.message, onTap: _pasteFlow)),
                    const SizedBox(width: 12),
                    Expanded(child: ActionTile(icon: Icons.mic_rounded, label: S.t('btn_speak'), caption: S.t('cap_speak'), color: N.speak, onTap: _speakFlow)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: ActionTile(icon: Icons.photo_camera_rounded, label: S.t('btn_photo'), caption: S.t('cap_photo'), color: N.photo, onTap: _photoFlow)),
                    const SizedBox(width: 12),
                    Expanded(child: ActionTile(icon: Icons.graphic_eq_rounded, label: S.t('btn_voice'), caption: S.t('cap_voice'), color: N.voice, onTap: _voiceNoteFlow)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.ios_share_rounded, size: 15, color: N.ink2),
                    const SizedBox(width: 6),
                    Expanded(child: Text(S.t('share_tip'), textDirection: dir, style: const TextStyle(fontSize: 12.5, color: N.ink2))),
                  ]),
                  const SizedBox(height: 22),

                  // ---- guardian
                  InfoCard(
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen()));
                      if (mounted) setState(() {});
                    },
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: hasGuardian ? N.safeSoft : N.brandSoft, borderRadius: BorderRadius.circular(13)),
                        child: Icon(hasGuardian ? Icons.verified_user_rounded : Icons.person_add_alt_1_rounded, color: hasGuardian ? N.safe : N.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(hasGuardian ? '${S.t('guardian_set')}: ${Prefs.guardianName.isNotEmpty ? Prefs.guardianName : Prefs.guardianPhone}' : S.t('guardian_none'),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(hasGuardian ? Prefs.guardianPhone : S.t('guardian_none_sub'), textDirection: dir, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: N.ink2)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: N.ink2),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Center(child: Text(S.t('privacy'), textDirection: dir, style: const TextStyle(fontSize: 12, color: N.ink2))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
