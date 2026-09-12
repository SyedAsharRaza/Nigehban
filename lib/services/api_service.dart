import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/verdict.dart';
import 'prefs.dart';
import 'rules_engine.dart';

/// Where the content came from — matches the backend's `source` values.
enum CheckSource { pastedText, dictated, image, voiceNote, shared }

extension on CheckSource {
  String get wire {
    switch (this) {
      case CheckSource.pastedText:
        return 'pasted_text';
      case CheckSource.dictated:
        return 'dictated';
      case CheckSource.image:
        return 'image';
      case CheckSource.voiceNote:
        return 'voice_note';
      case CheckSource.shared:
        return 'shared';
    }
  }
}

/// The one function the app needs: [check]. Never throws — returns an offline
/// verdict (from the rules engine) if the backend cannot be reached.
class ApiService {
  ApiService._();

  static Uri _u(String path) {
    final base = Prefs.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  /// Quick reachability probe for the status dot on the home screen.
  static Future<bool> health() async {
    try {
      final r = await http.get(_u('/api/health')).timeout(AppConfig.healthTimeout);
      return r.statusCode == 200 && (jsonDecode(r.body)['ok'] == true);
    } catch (_) {
      return false;
    }
  }

  static Future<Verdict> check({
    String text = '',
    Uint8List? fileBytes,
    String? fileName,
    required CheckSource source,
  }) async {
    final lang = Prefs.lang;
    try {
      final req = http.MultipartRequest('POST', _u('/api/check'))
        ..fields['text'] = text
        ..fields['source'] = source.wire
        ..fields['lang'] = lang;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        final name = (fileName == null || fileName.isEmpty) ? 'upload.bin' : fileName;
        req.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: name,
          contentType: _mediaTypeFor(name),
        ));
      }
      final streamed = await req.send().timeout(AppConfig.checkTimeout);
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw HttpException('Backend returned ${streamed.statusCode}: ${body.length > 200 ? body.substring(0, 200) : body}');
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) throw const FormatException('Unexpected response');
      return Verdict.fromJson(json);
    } on SocketException catch (_) {
      return RulesEngine.offlineVerdict(text);
    } on TimeoutException catch (_) {
      return RulesEngine.offlineVerdict(text);
    } on HttpException catch (_) {
      return RulesEngine.offlineVerdict(text);
    } catch (_) {
      return RulesEngine.offlineVerdict(text);
    }
  }

  static MediaType _mediaTypeFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'ogg':
      case 'opus':
      case 'oga':
        return MediaType('audio', 'ogg');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'm4a':
      case 'mp4':
        return MediaType('audio', 'mp4');
      case 'aac':
        return MediaType('audio', 'aac');
      case 'wav':
        return MediaType('audio', 'wav');
      case 'amr':
        return MediaType('audio', 'amr');
      case '3gp':
        return MediaType('audio', '3gpp');
      case 'webm':
        return MediaType('audio', 'webm');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
