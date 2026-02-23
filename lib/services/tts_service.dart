import 'package:flutter_tts/flutter_tts.dart';


class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();
  factory TtsService() => instance;

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isSpeaking = false;
  bool _muted = false;

  final List<_TtsMessage> _queue = [];

  String? _lastMessage;
  DateTime? _lastMessageTime;
  static const _cooldownSeconds = 8;

  int _gpsTickCount = 0;
  static const _gpsAnnounceEvery = 5;


  Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage("fr-FR");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _queue.clear();
    });

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (_muted || text.trim().isEmpty) return;
    await init();

    if (_isSameRecentMessage(text)) return;

    _queue.add(_TtsMessage(text: text, priority: false));
    if (!_isSpeaking) _processQueue();
  }

  Future<void> speakNow(String text) async {
    if (_muted || text.trim().isEmpty) return;
    await init();

    _queue.clear();
    await _tts.stop();
    _isSpeaking = false;

    _lastMessage = text;
    _lastMessageTime = DateTime.now();

    await _tts.speak(text);
  }


  Future<bool> announceGps(double distance) async {
    if (_muted) return false;
    await init();

    _gpsTickCount++;

    String? message;

    if (distance <= 10) {
      await speakNow("Vous êtes arrivé à destination. Bon appétit !");
      _gpsTickCount = 0;
      return true;
    } else if (distance <= 30) {
      message = "Dans ${distance.toInt()} mètres, vous arrivez.";
    } else if (distance <= 50) {
      message = "Vous êtes presque arrivé.";
    } else if (distance <= 100) {
      if (_gpsTickCount % _gpsAnnounceEvery == 0) {
        message = "Continuez, il reste environ ${_roundedDistance(distance)}.";
      }
    } else {
      if (_gpsTickCount % (_gpsAnnounceEvery * 2) == 0) {
        message = "Continuez tout droit. ${_roundedDistance(distance)} restants.";
      }
    }

    if (message != null && !_isSameRecentMessage(message)) {
      await speak(message);
      return true;
    }
    return false;
  }

  Future<void> onAppReady() async {
    await speak("Bienvenue sur AyimolouMap. Trouvez l'ayimolou près de vous.");
  }

  Future<void> onVendorsLoaded(int count) async {
    if (count == 0) {
      await speak("Aucun vendeur trouvé dans votre zone.");
    } else {
      await speak("$count vendeur${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''} près de vous.");
    }
  }

  Future<void> onRouteCalculating(String vendorName) async {
    await speak("Calcul de l'itinéraire vers $vendorName.");
  }

  Future<void> onRouteReady(String vendorName) async {
    await speakNow("Itinéraire prêt vers $vendorName. Appuyez sur Démarrer pour la navigation.");
  }

  Future<void> onRouteNotFound(String vendorName) async {
    await speakNow("Impossible de trouver un itinéraire vers $vendorName.");
  }

  Future<void> onNavigationStarted(String vendorName) async {
    await speakNow("Navigation démarrée vers $vendorName. Bonne route !");
  }

  Future<void> onNavigationCancelled() async {
    await speak("Navigation annulée.");
  }

  Future<void> onLocationError() async {
    await speak("Impossible d'accéder à votre position. Vérifiez votre GPS.");
  }

  bool get isMuted => _muted;

  Future<void> toggleMute() async {
    _muted = !_muted;
    if (_muted) {
      await _tts.stop();
      _queue.clear();
    }
  }

  Future<void> setMuted(bool value) async {
    _muted = value;
    if (_muted) {
      await _tts.stop();
      _queue.clear();
    }
  }

  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
    _initialized = false;
  }


  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isSpeaking || _muted) return;

    final next = _queue.removeAt(0);
    _lastMessage = next.text;
    _lastMessageTime = DateTime.now();
    await _tts.speak(next.text);
  }

  bool _isSameRecentMessage(String text) {
    if (_lastMessage == null || _lastMessageTime == null) return false;
    final elapsed = DateTime.now().difference(_lastMessageTime!).inSeconds;
    return _lastMessage == text && elapsed < _cooldownSeconds;
  }

  String _roundedDistance(double meters) {
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return "$km kilomètres";
    }
    final rounded = (meters / 50).round() * 50;
    return "$rounded mètres";
  }
}

class _TtsMessage {
  final String text;
  final bool priority;
  _TtsMessage({required this.text, required this.priority});
}