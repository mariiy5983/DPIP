import 'dart:async';

import 'package:dpip/utils/log.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  CompassService._();

  static final CompassService _instance = CompassService._();
  static CompassService get instance => _instance;

  StreamController<CompassEvent>? _controller;
  StreamSubscription<CompassEvent>? _sourceSubscription;
  double _lastHeading = 0;
  bool _isInitialized = false;

  Stream<CompassEvent>? get events => _controller?.stream;

  double get lastHeading => _lastHeading;

  bool get isInitialized => _isInitialized;

  bool get hasCompass => _isInitialized && _controller != null;

  Future<void> initialize() async {
    final log = TalkerManager.instance;
    if (_isInitialized) {
      log.debug('CompassService: already initialized');
      return;
    }

    log.debug('CompassService: initializing...');

    try {
      final sourceStream = FlutterCompass.events;
      if (sourceStream == null) {
        log.debug('CompassService: compass not available');
        return;
      }

      _controller = StreamController<CompassEvent>.broadcast(
        onListen: () => log.debug('CompassService: first listener added'),
        onCancel: () => log.debug('CompassService: last listener removed'),
      );

      _sourceSubscription = sourceStream.listen(
        (event) {
          if (event.heading != null) _lastHeading = event.heading!;
          _controller?.add(event);
        },
        onError: (Object error) {
          log.error('CompassService: stream error', error);
          _controller?.addError(error);
        },
        onDone: () {
          log.debug('CompassService: source stream done');
          _controller?.close();
        },
      );

      log.debug('CompassService: initialized successfully');
    } catch (e, s) {
      log.error('CompassService: initialization failed', e, s);
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> dispose() async {
    TalkerManager.instance.debug('CompassService: disposing...');
    await _sourceSubscription?.cancel();
    _sourceSubscription = null;
    await _controller?.close();
    _controller = null;
    _isInitialized = false;
  }
}
