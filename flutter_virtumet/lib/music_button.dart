import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Servicio global de música ambiental: un solo reproductor para toda la app,
/// así la música sigue sonando al iniciar sesión y al cambiar de página.
/// Usa el elemento <audio> del propio navegador (la app corre en web).
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  // Flutter web sirve los assets en "assets/<ruta declarada en pubspec>"
  static const String _ruta = 'assets/lib/assets/musica_relajante.mp3';

  late final web.HTMLAudioElement _audio;
  final ValueNotifier<bool> sonando = ValueNotifier<bool>(false);
  final ValueNotifier<double> volumen = ValueNotifier<double>(0.4);

  bool _iniciado = false;
  bool _pausadaPorUsuario = false; // si la pausó a propósito, no se reanuda sola
  bool _arrancando = false;

  void iniciar() {
    if (_iniciado) return;
    _iniciado = true;
    _audio = web.HTMLAudioElement()
      ..src = _ruta
      ..loop = true // música en bucle
      ..volume = volumen.value;
    // Intento de reproducción automática: el navegador puede bloquearla
    _reproducir();
  }

  Future<void> _reproducir() async {
    if (_arrancando || sonando.value) return;
    _arrancando = true;
    try {
      await _audio.play().toDart;
      sonando.value = true;
    } catch (e) {
      debugPrint('Música: no se pudo reproducir ($e)');
      sonando.value = false; // bloqueada: se reintenta con el primer clic
    } finally {
      _arrancando = false;
    }
  }

  /// Se llama con el primer clic/toque de la persona en cualquier parte:
  /// los navegadores solo permiten audio después de una interacción.
  void alPrimerToque() {
    if (!_pausadaPorUsuario && !sonando.value) _reproducir();
  }

  Future<void> alternar() async {
    if (sonando.value) {
      _pausadaPorUsuario = true;
      _audio.pause();
      sonando.value = false;
    } else {
      _pausadaPorUsuario = false;
      await _reproducir();
    }
  }

  void cambiarVolumen(double v) {
    volumen.value = v;
    _audio.volume = v;
  }
}

/// Envuelve toda la app: detecta el primer toque y muestra el botón de música
/// flotante (abajo a la izquierda) en todas las pantallas. Usa su propio
/// Overlay porque este widget vive por encima del Navigator de la app.
class MusicOverlay extends StatefulWidget {
  final Widget child;
  const MusicOverlay({super.key, required this.child});

  @override
  State<MusicOverlay> createState() => _MusicOverlayState();
}

class _MusicOverlayState extends State<MusicOverlay> {
  late final OverlayEntry _entradaApp;
  late final OverlayEntry _entradaBoton;

  @override
  void initState() {
    super.initState();
    MusicService.instance.iniciar();
    _entradaApp = OverlayEntry(builder: (_) => widget.child);
    _entradaBoton = OverlayEntry(
      builder: (_) => const Positioned(
        left: 16,
        bottom: 16,
        child: _MusicButton(),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MusicOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entradaApp.markNeedsBuild();
  }

  @override
  void dispose() {
    _entradaApp.remove();
    _entradaBoton.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => MusicService.instance.alPrimerToque(),
      child: Overlay(initialEntries: [_entradaApp, _entradaBoton]),
    );
  }
}

class _MusicButton extends StatefulWidget {
  const _MusicButton();

  @override
  State<_MusicButton> createState() => _MusicButtonState();
}

class _MusicButtonState extends State<_MusicButton> {
  static const Color _navy = Color(0xFF0F2C59);
  static const Color _orange = Color(0xFFFF5500);
  bool _expandido = false;

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    MusicService.instance.sonando.addListener(_refrescar);
    MusicService.instance.volumen.addListener(_refrescar);
  }

  @override
  void dispose() {
    MusicService.instance.sonando.removeListener(_refrescar);
    MusicService.instance.volumen.removeListener(_refrescar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = MusicService.instance;
    final sonando = m.sonando.value;
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                sonando ? Icons.pause_circle_filled : Icons.music_note,
                color: sonando ? _orange : _navy,
                size: 28,
              ),
              onPressed: m.alternar,
            ),
            if (_expandido)
              SizedBox(
                width: 110,
                child: Slider(
                  value: m.volumen.value,
                  activeColor: _orange,
                  onChanged: m.cambiarVolumen,
                ),
              ),
            IconButton(
              icon: Icon(
                _expandido ? Icons.chevron_left : Icons.volume_up,
                color: _navy,
                size: 20,
              ),
              onPressed: () => setState(() => _expandido = !_expandido),
            ),
          ],
        ),
      ),
    );
  }
}
