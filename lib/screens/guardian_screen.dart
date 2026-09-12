import 'package:flutter/material.dart';

import '../main.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../widgets/big_button.dart';

/// Set the trusted family member who gets a WhatsApp warning on a red verdict.
/// Shown once on first launch (skippable) and from the home screen.
class GuardianScreen extends StatefulWidget {
  final bool firstRun;
  const GuardianScreen({super.key, this.firstRun = false});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _name = TextEditingController(text: Prefs.guardianName);
  final _phone = TextEditingController(text: Prefs.guardianPhone);
  final _speech = SpeechService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _speech.say(en: S.en('guardian_speak'), ur: S.ur('guardian_speak'));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('guardian_phone'))));
      return;
    }
    await Prefs.setGuardianPhone(phone);
    await Prefs.setGuardianName(_name.text.trim());
    await _speech.say(en: S.en('guardian_saved'), ur: S.ur('guardian_saved'));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ur = Prefs.lang == 'ur';
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('guardian_title')),
        backgroundColor: NColors.bg,
        automaticallyImplyLeading: !widget.firstRun,
        actions: [
          if (widget.firstRun)
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.t('btn_skip'), style: const TextStyle(fontSize: 18))),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.family_restroom_rounded, size: 110, color: NColors.brand),
              const SizedBox(height: 12),
              Text(
                S.t('guardian_speak'),
                textAlign: TextAlign.center,
                textDirection: ur ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontSize: 19, height: 1.45),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                style: const TextStyle(fontSize: 20),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(hintText: S.t('guardian_name'), prefixIcon: const Icon(Icons.person_rounded)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                style: const TextStyle(fontSize: 22, letterSpacing: 1),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: S.t('guardian_phone'), prefixIcon: const Icon(Icons.phone_rounded)),
              ),
              const Spacer(),
              WideButton(icon: Icons.check_rounded, label: S.t('btn_save'), color: NColors.brand, onTap: _save),
            ],
          ),
        ),
      ),
    );
  }
}
