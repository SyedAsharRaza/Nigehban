import 'package:flutter/material.dart';

import '../services/prefs.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Set the trusted family member who gets a WhatsApp warning on a red verdict.
/// Shown once on first launch (skippable) and from the home screen. Scrollable so the keyboard never overflows it.
class GuardianScreen extends StatefulWidget {
  final bool firstRun;
  const GuardianScreen({super.key, this.firstRun = false});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _name = TextEditingController(text: Prefs.guardianName);
  final _phone = TextEditingController(text: Prefs.guardianPhone);

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('guardian_saved'))));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dir = Prefs.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('guardian_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: !widget.firstRun,
        actions: [if (widget.firstRun) TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.t('btn_skip')))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: N.brandSoft, borderRadius: BorderRadius.circular(N.radius)),
              child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: N.brand, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Text(S.t('guardian_speak'), textDirection: dir, style: const TextStyle(fontSize: 14.5, height: 1.45, color: N.brandDark, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 22),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: S.t('guardian_name'), prefixIcon: const Icon(Icons.person_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _phone, keyboardType: TextInputType.phone, style: const TextStyle(fontSize: 18, letterSpacing: 0.8), decoration: InputDecoration(hintText: S.t('guardian_phone'), prefixIcon: const Icon(Icons.phone_rounded))),
            const SizedBox(height: 24),
            PrimaryButton(label: S.t('btn_save'), icon: Icons.check_rounded, onTap: _save),
          ]),
        ),
      ),
    );
  }
}
