import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';
import '../models/record.dart';
import '../core/prompts.dart';

/// Owns all device-local state. No inference API / analytics / cloud storage.
class AiEngine extends ChangeNotifier {
  static const modelFilename = 'Qwen3.5-0.8B-Q4_0.gguf';
  static const modelSha256 =
      '57d1997790d1744fba5b40a7317df71ea5e2acee28c47e78f0cce39c0703f8cf';
  static const modelDownloadUrl =
      'https://huggingface.co/ggml-org/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_0.gguf';

  final Dio _dio = Dio();
  LlamaController? _llama;
  CancelToken? _downloadCancel;
  SharedPreferences? _prefs;

  List<AiRecord> history = [];
  List<ChatConversation> conversations = [];
  String? activeConversationId;
  List<LocalChatMessage> get messages => activeConversation?.messages ?? [];
  ChatConversation? get activeConversation {
    for (final chat in conversations) {
      if (chat.id == activeConversationId) return chat;
    }
    return null;
  }

  AppLanguage source = AppLanguage.english;
  AppLanguage target = AppLanguage.pashto;
  AppLanguage writingLanguage = AppLanguage.english;
  AppLanguage chatLanguage = AppLanguage.english;
  bool darkMode = false;
  bool lowMemoryMode = true;
  bool downloading = false;
  bool loading = false;
  bool loaded = false;
  bool generating = false;
  bool chatting = false;

  void setChatting(bool value) {
    chatting = value;
    notifyListeners();
  }

  double downloadProgress = 0;
  String? modelPath;
  String? error;
  String status = 'No model installed';
  int _generationId = 0;

  bool get modelInstalled => modelPath != null;
  bool get supported => !kIsWeb && Platform.isAndroid;
  int get contextSize => lowMemoryMode ? 512 : 1536;
  int get outputLimit => lowMemoryMode ? 160 : 420;

  Future<Directory> get _modelDirectory async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    darkMode = _prefs?.getBool('dark') ?? false;
    lowMemoryMode = _prefs?.getBool('lowMemory') ?? true;
    source = AppLanguage.fromCode(_prefs?.getString('source'));
    target = AppLanguage.fromCode(_prefs?.getString('target'),
        fallback: AppLanguage.pashto);
    writingLanguage = AppLanguage.fromCode(_prefs?.getString('writeLang'));
    chatLanguage = AppLanguage.fromCode(_prefs?.getString('chatLang'));
    history = AiRecord.decode(_prefs?.getString('history'));
    final savedChats = _prefs?.getString('conversations');
    if (savedChats != null) {
      try {
        for (final item in jsonDecode(savedChats) as List) {
          try {
            conversations.add(ChatConversation.fromJson(
                Map<String, dynamic>.from(item as Map)));
          } catch (_) {/* Keep other readable conversations. */}
        }
      } catch (_) {/* Leave unreadable storage intact until the next save. */}
      activeConversationId = _prefs?.getString('activeConversation');
    } else {
      final legacy = (_prefs?.getStringList('messages') ?? [])
          .map((raw) {
            final parts = raw.split('\u0001');
            return LocalChatMessage(
                role: parts.first, content: parts.skip(1).join('\u0001'));
          })
          .where((m) => m.content.isNotEmpty)
          .toList();
      if (legacy.isNotEmpty) {
        final chat = ChatConversation(
            id: _newChatId(),
            title: _titleFor(legacy.first.content),
            updatedAt: DateTime.now(),
            messages: legacy);
        conversations.add(chat);
        activeConversationId = chat.id;
        await _saveMessages();
      }
    }
    final saved = _prefs?.getString('modelPath');
    final standard = File('${(await _modelDirectory).path}/$modelFilename');
    if (saved != null && await File(saved).exists()) {
      modelPath = saved;
    } else if (await standard.exists() && await _isValidGguf(standard)) {
      modelPath = standard.path;
    }
    status = modelInstalled
        ? 'Model installed · tap Load model'
        : 'Model not installed';
    notifyListeners();
  }

  void setLanguages(AppLanguage from, AppLanguage to) {
    if (from == to) return;
    source = from;
    target = to;
    _prefs?.setString('source', from.code);
    _prefs?.setString('target', to.code);
    notifyListeners();
  }

  void setWritingLanguage(AppLanguage lang) {
    writingLanguage = lang;
    _prefs?.setString('writeLang', lang.code);
    notifyListeners();
  }

  void setChatLanguage(AppLanguage lang) {
    chatLanguage = lang;
    _prefs?.setString('chatLang', lang.code);
    notifyListeners();
  }

  void toggleTheme() {
    darkMode = !darkMode;
    _prefs?.setBool('dark', darkMode);
    notifyListeners();
  }

  Future<void> setLowMemory(bool low) async {
    if (lowMemoryMode == low) return;
    if (loaded) await unload();
    lowMemoryMode = low;
    await _prefs?.setBool('lowMemory', low);
    notifyListeners();
  }

  Future<bool> _isValidGguf(File file) async {
    try {
      if (await file.length() < 50 * 1024 * 1024) return false;
      final stream = await file.open();
      final magic = await stream.read(4);
      await stream.close();
      return magic.length == 4 &&
          magic[0] == 0x47 &&
          magic[1] == 0x47 &&
          magic[2] == 0x55 &&
          magic[3] == 0x46;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _officialChecksum(File file) async {
    final checksum = await sha256.bind(file.openRead()).first;
    return checksum.toString() == modelSha256;
  }

  Future<void> _installFrom(File sourceFile) async {
    if (!await _isValidGguf(sourceFile)) {
      throw const FormatException('This is not a valid GGUF model file.');
    }
    final dest = File('${(await _modelDirectory).path}/$modelFilename');
    if (loaded) await unload();
    if (sourceFile.path != dest.path) {
      if (await dest.exists()) await dest.delete();
      await sourceFile.copy(dest.path);
    }
    modelPath = dest.path;
    status = 'Model installed · tap Load model';
    error = null;
    await _prefs?.setString('modelPath', dest.path);
    notifyListeners();
  }

  Future<void> importModel() async {
    if (loading || downloading || generating) return;
    try {
      error = null;
      status = 'Choose a GGUF model file';
      notifyListeners();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf'],
        withData: false,
      );
      if (result == null) {
        status = modelInstalled ? 'Model installed' : 'No model installed';
        notifyListeners();
        return;
      }
      final path = result.files.single.path;
      if (path == null) {
        throw const FileSystemException('Cannot access the selected file.');
      }
      status = 'Copying model to private storage…';
      notifyListeners();
      await _installFrom(File(path));
    } catch (e) {
      error = 'Import failed: $e';
      status = 'Model import failed';
      notifyListeners();
    }
  }

  Future<void> downloadModel() async {
    if (downloading || loading || generating) return;
    downloading = true;
    downloadProgress = 0;
    error = null;
    status = 'Downloading official model (~563 MB)';
    _downloadCancel = CancelToken();
    notifyListeners();
    final file = File('${(await _modelDirectory).path}/$modelFilename.part');
    try {
      // Download to disk, not RAM. A cancelled/incomplete download is never loaded.
      await _dio.download(
        modelDownloadUrl,
        file.path,
        cancelToken: _downloadCancel,
        options: Options(
            followRedirects: true, receiveTimeout: const Duration(minutes: 20)),
        onReceiveProgress: (received, total) {
          if (total > 0) downloadProgress = received / total;
          notifyListeners();
        },
      );
      if (!await _isValidGguf(file)) {
        throw const FormatException('Downloaded file is not a valid GGUF.');
      }
      status = 'Verifying official model checksum…';
      notifyListeners();
      if (!await _officialChecksum(file)) {
        throw const FormatException(
            'Model checksum does not match the official file. Please retry.');
      }
      final dest = File('${(await _modelDirectory).path}/$modelFilename');
      if (loaded) await unload();
      if (await dest.exists()) await dest.delete();
      await file.rename(dest.path);
      modelPath = dest.path;
      await _prefs?.setString('modelPath', dest.path);
      status = 'Model verified · tap Load model';
      downloadProgress = 1;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        status = 'Download cancelled';
      } else {
        error =
            'Download failed: ${e.message}. Check connectivity and storage.';
        status = 'Download unsuccessful';
      }
    } catch (e) {
      error = 'Download failed: $e';
      status = 'Download unsuccessful';
    } finally {
      if (await file.exists()) await file.delete();
      _downloadCancel = null;
      downloading = false;
      notifyListeners();
    }
  }

  void cancelDownload() => _downloadCancel?.cancel('Cancelled by user');

  Future<void> load() async {
    if (loaded || loading || downloading) return;
    if (!modelInstalled) {
      error = 'Download or import a GGUF model first.';
      notifyListeners();
      return;
    }
    if (!supported) {
      error =
          'On-device inference is configured for Android. Run on a physical Android phone.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    status = 'Loading local model…';
    notifyListeners();
    try {
      _llama ??= LlamaController();
      // Conservative CPU-only settings avoid large GPU allocations on 2 GB phones.
      await _llama!.loadModel(
        modelPath: modelPath!,
        contextSize: contextSize,
        threads: lowMemoryMode ? 2 : 4,
        gpuLayers: 0,
      );
      loaded = true;
      status = 'AI ready · offline';
    } catch (e) {
      loaded = false;
      error =
          'Unable to load model: $e. The phone may lack free memory or the runtime may not support this GGUF architecture.';
      status = 'Failed to load model';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> unload() async {
    if (generating) await stop();
    try {
      await _llama?.dispose();
    } catch (_) {}
    _llama = null;
    loaded = false;
    status = modelInstalled
        ? 'Model unloaded · tap Load model'
        : 'No model installed';
    notifyListeners();
  }

  Future<void> deleteModel() async {
    if (generating || downloading) return;
    await unload();
    if (modelPath != null) {
      final file = File(modelPath!);
      if (await file.exists()) await file.delete();
    }
    modelPath = null;
    await _prefs?.remove('modelPath');
    status = 'No model installed';
    error = null;
    notifyListeners();
  }

  Future<String> generate({
    required List<LocalChatMessage> promptMessages,
    required void Function(String) onUpdate,
    double temperature = 0.2,
  }) async {
    if (!loaded || _llama == null) {
      throw StateError('Open Settings and start the offline AI first.');
    }
    if (generating) throw StateError('Another response is still running.');
    final id = ++_generationId;
    generating = true;
    error = null;
    notifyListeners();
    final buffer = StringBuffer();
    try {
      final stream = _llama!.generateChat(
        messages: promptMessages
            .map((e) => ChatMessage(role: e.role, content: e.content))
            .toList(),
        template: 'chatml',
        maxTokens: outputLimit,
        temperature: temperature,
        topP: 0.85,
        topK: 30,
        repeatPenalty: 1.07,
      );
      await for (final token in stream) {
        if (id != _generationId) break;
        buffer.write(token);
        onUpdate(buffer.toString());
      }
      return buffer.toString().trim();
    } finally {
      if (id == _generationId) {
        generating = false;
        notifyListeners();
      }
    }
  }

  Future<String> translate(String text, void Function(String) onUpdate) async =>
      generate(
        promptMessages: [
          const LocalChatMessage(
              role: 'system',
              content:
                  'You are a precise translator. Respond with translated text only. /no_think'),
          LocalChatMessage(
              role: 'user',
              content: AiPrompts.translation(source, target, text)),
        ],
        onUpdate: onUpdate,
        temperature: 0.1,
      );

  Future<String> write(String text, WritingMode mode,
          void Function(String) onUpdate) async =>
      generate(
        promptMessages: [
          const LocalChatMessage(
              role: 'system',
              content:
                  'You are a skilled multilingual writing assistant. /no_think'),
          LocalChatMessage(
              role: 'user',
              content: AiPrompts.writing(mode, writingLanguage, text)),
        ],
        onUpdate: onUpdate,
        temperature: 0.5,
      );

  Future<void> stop() async {
    if (!generating) return;
    _generationId++;
    try {
      await _llama?.stop();
    } finally {
      generating = false;
      notifyListeners();
    }
  }

  Future<void> saveRecord(
      {required String mode,
      required String input,
      required String output,
      required String subtitle}) async {
    if (output.trim().isEmpty) return;
    history.insert(
        0,
        AiRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          mode: mode,
          input: input.trim(),
          output: output.trim(),
          subtitle: subtitle,
          createdAt: DateTime.now(),
        ));
    if (history.length > 100) history = history.take(100).toList();
    await _prefs?.setString('history', AiRecord.encode(history));
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    history.removeWhere((e) => e.id == id);
    await _prefs?.setString('history', AiRecord.encode(history));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _prefs?.remove('history');
    notifyListeners();
  }

  String _newChatId() => DateTime.now().microsecondsSinceEpoch.toString();
  String _titleFor(String text) {
    final title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title.length > 48 ? '${title.substring(0, 48)}…' : title;
  }

  Future<void> addMessage(LocalChatMessage message) async {
    var chat = activeConversation;
    if (chat == null) {
      chat = ChatConversation(
          id: _newChatId(),
          title: _titleFor(message.content),
          updatedAt: DateTime.now());
      conversations.insert(0, chat);
      activeConversationId = chat.id;
    }
    chat.messages.add(message);
    chat.updatedAt = DateTime.now();
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveMessages();
    notifyListeners();
  }

  Future<void> newChat() async {
    if (generating || chatting) return;
    activeConversationId = null;
    await _saveMessages();
    notifyListeners();
  }

  Future<void> openConversation(String id) async {
    if (generating || chatting || !conversations.any((c) => c.id == id)) return;
    activeConversationId = id;
    await _saveMessages();
    notifyListeners();
  }

  Future<void> renameConversation(String id, String title) async {
    if (title.trim().isEmpty) return;
    for (final chat in conversations) {
      if (chat.id == id) chat.title = title.trim();
    }
    await _saveMessages();
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    if (generating || chatting) return;
    conversations.removeWhere((c) => c.id == id);
    if (activeConversationId == id) activeConversationId = null;
    await _saveMessages();
    notifyListeners();
  }

  Future<void> clearChat() => newChat();

  Future<void> _saveMessages() async {
    await _prefs?.setString('conversations',
        jsonEncode(conversations.map((c) => c.toJson()).toList()));
    await _prefs?.remove('messages');
    if (activeConversationId == null) {
      await _prefs?.remove('activeConversation');
    } else {
      await _prefs?.setString('activeConversation', activeConversationId!);
    }
  }

  @override
  void dispose() {
    _downloadCancel?.cancel('App disposed');
    _generationId++;
    _llama?.dispose();
    _dio.close();
    super.dispose();
  }
}
