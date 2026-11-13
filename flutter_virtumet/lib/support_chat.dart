import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faq_section.dart';

/// Soporte de VirtuMet.
///
/// Funciona en tres pasos:
///  1. El visitante escribe una duda. El sistema la compara con las preguntas
///     frecuentes ([kFaqs]) y, si encuentra una respuesta suficientemente
///     parecida, responde solo (sin internet externo ni IA de pago).
///  2. Si no alcanza, el visitante puede enviar la consulta al administrador.
///     Se guarda en `soporte_consultas`:
///       { codigo, nombre, correo, mensaje, estado: 'Pendiente'|'Respondida',
///         respuesta, uid, creadoEn, respondidoEn, respondidoPor }
///  3. El administrador la responde desde su panel (admin_support_view.dart) y
///     el visitante ve la respuesta con su código + correo ("Ver mi respuesta").
Future<void> showSupportChat(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SupportChatDialog(),
  );
}

// =============================================================================
// Motor de respuestas automáticas (coincidencia de palabras clave)
// =============================================================================
class _Puntaje {
  final FaqItem faq;
  final double puntaje;
  final int indice;
  const _Puntaje(this.faq, this.puntaje, this.indice);
}

class _Motor {
  static const _origen = 'áàäâéèëêíìïîóòöôúùüûñ';
  static const _destino = 'aaaaeeeeiiiioooouuuun';

  // Palabras que no aportan significado a la búsqueda.
  static const Set<String> _vacias = {
    'que', 'como', 'cual', 'cuales', 'donde', 'cuando', 'por', 'para', 'con',
    'sin', 'los', 'las', 'del', 'una', 'uno', 'unos', 'unas', 'mis', 'tus',
    'sus', 'puedo', 'puede', 'pueden', 'quiero', 'quisiera', 'necesito', 'hay',
    'hacer', 'hago', 'esta', 'estoy', 'ser', 'son', 'fue', 'mas', 'muy', 'pero',
    'ahora', 'tengo', 'tiene', 'tienen', 'favor', 'hola', 'buenas', 'buenos',
    'dias', 'tardes', 'noches', 'gracias', 'ayuda', 'duda', 'dudas', 'pregunta',
    'preguntas', 'saber', 'sobre', 'esto', 'eso', 'ese', 'esa', 'les', 'nos',
    'disciplina', 'disciplinas', 'virtumet', 'plataforma', 'pagina', 'sistema',
    'aplicacion', 'app', 'unimet', 'estudiante', 'estudiantes', 'cuanto',
    'cuantos', 'cuanta', 'cuantas', 'cambiar', 'cambio', 'cambia', 'ver',
  };

  // Palabras distintas que significan lo mismo.
  static const Map<String, String> _sinonimos = {
    'pagar': 'pago', 'pagado': 'pago', 'pagan': 'pago', 'pague': 'pago',
    'paga': 'pago', 'cobran': 'pago', 'cobro': 'pago', 'cobraron': 'pago',
    'cuesta': 'precio', 'costo': 'precio', 'tarifa': 'precio', 'valor': 'precio', 'cuestan': 'precio',
    'devolver': 'reembolso', 'devolucion': 'reembolso',
    'devuelven': 'reembolso', 'reintegro': 'reembolso',
    'coach': 'entrenador', 'profesor': 'entrenador', 'profe': 'entrenador',
    'maestro': 'entrenador', 'profesores': 'entrenador',
    'anotar': 'inscribir', 'anotarme': 'inscribir', 'unirme': 'inscribir',
    'matricular': 'inscribir', 'matricula': 'inscribir',
    'contrasena': 'clave', 'password': 'clave',
  };

  static String _sinAcentos(String s) {
    final b = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final ch = String.fromCharCode(r);
      final i = _origen.indexOf(ch);
      b.write(i >= 0 ? _destino[i] : ch);
    }
    return b.toString();
  }

  /// Convierte un texto en una lista de "raíces" comparables.
  static List<String> _raices(String texto) {
    final limpio = _sinAcentos(texto).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    final salida = <String>[];
    for (var t in limpio.split(RegExp(r'\s+'))) {
      if (t.length < 3 || _vacias.contains(t)) continue;
      if (t.length > 4 && t.endsWith('s')) t = t.substring(0, t.length - 1);
      t = _sinonimos[t] ?? t;
      salida.add(t.length > 5 ? t.substring(0, 5) : t);
    }
    return salida;
  }

  // Cuántas preguntas frecuentes contienen cada raíz (para dar más peso a
  // las palabras poco comunes). Se calcula una sola vez.
  static Map<String, int>? _df;
  static Map<String, int> get _frecuencias {
    final df = <String, int>{};
    for (final f in kFaqs) {
      final r = {
        ..._raices(f.pregunta),
        ..._raices(f.respuesta),
      };
      for (final t in r) {
        df[t] = (df[t] ?? 0) + 1;
      }
    }
    return _df = df;
  }

  static const double _umbral = 1.5;

  /// Devuelve las preguntas frecuentes más parecidas a [consulta], de la más
  /// a la menos relevante. Lista vacía si ninguna alcanza el umbral.
  static List<FaqItem> buscar(String consulta) {
    final q = _raices(consulta).toSet();
    if (q.isEmpty) return [];
    final df = _df ?? _frecuencias;
    final n = kFaqs.length;
    final puntajes = <_Puntaje>[];
    for (int i = 0; i < kFaqs.length; i++) {
      final f = kFaqs[i];
      final enPregunta = _raices(f.pregunta).toSet();
      final enRespuesta = _raices('${f.categoria} ${f.respuesta}').toSet();
      double s = 0;
      int aciertosPregunta = 0;
      for (final t in q) {
        final peso = log(1 + n / (df[t] ?? 1));
        if (enPregunta.contains(t)) {
          s += 2 * peso;
          aciertosPregunta++;
        } else if (enRespuesta.contains(t)) {
          s += peso;
        }
      }
      // Bonus: qué parte de la pregunta frecuente cubre lo que escribió el usuario.
      if (aciertosPregunta > 0 && enPregunta.isNotEmpty) {
        s += 3 * aciertosPregunta / enPregunta.length;
      }
      // Si ninguna palabra está en el título de la pregunta, se exige más
      // evidencia (varias coincidencias en la respuesta) para no responder mal.
      final minimo = aciertosPregunta > 0 ? _umbral : 2.5;
      if (s >= minimo) puntajes.add(_Puntaje(f, s, i));
    }
    // Mayor puntaje primero; si empatan, gana la que aparece antes en la lista.
    puntajes.sort((a, b) {
      final c = b.puntaje.compareTo(a.puntaje);
      return c != 0 ? c : a.indice.compareTo(b.indice);
    });
    return puntajes.map((e) => e.faq).toList();
  }

  /// ¿El visitante pide hablar con una persona?
  static bool pideHumano(String consulta) {
    final t = _sinAcentos(consulta);
    return t.contains('administrador') ||
        t.contains('admin') ||
        t.contains('persona') ||
        t.contains('humano') ||
        t.contains('hablar con');
  }

  static bool esSaludo(String consulta) {
    final t = _sinAcentos(consulta).trim();
    return t.startsWith('hola') ||
        t.startsWith('buenas') ||
        t.startsWith('buenos') ||
        t.contains('gracias');
  }
}

// =============================================================================
// Ventana de chat
// =============================================================================
enum _Modo { chat, enviar, consultar }

class _Accion {
  final String etiqueta;
  final VoidCallback onTap;
  const _Accion(this.etiqueta, this.onTap);
}

class _Msg {
  final bool usuario;
  final String texto;
  final List<_Accion> acciones;
  const _Msg(this.usuario, this.texto, {this.acciones = const []});
}

class _SupportChatDialog extends StatefulWidget {
  const _SupportChatDialog();

  @override
  State<_SupportChatDialog> createState() => _SupportChatDialogState();
}

class _SupportChatDialogState extends State<_SupportChatDialog> {
  static const Color _azul = Color(0xFF0F2C59);
  static const Color _naranja = Color(0xFFFF5500);

  _Modo _modo = _Modo.chat;
  final List<_Msg> _msgs = [];
  final TextEditingController _entrada = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // Formulario "Enviar al administrador"
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _mensaje = TextEditingController();
  bool _enviando = false;
  String? _error;
  String _ultimaPregunta = '';

  // "Ver mi respuesta"
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _correoConsulta = TextEditingController();
  bool _buscando = false;
  String? _resultado;

  @override
  void initState() {
    super.initState();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _correo.text = email;
    _correoConsulta.text = email;
    _msgs.add(_Msg(
      false,
      '¡Hola! Soy el asistente de VirtuMet. Pregúntame lo básico (inscripción, '
      'pagos, cupos, ficha deportiva…). Si no puedo resolverlo, envío tu '
      'consulta al administrador.',
      acciones: [
        _Accion('¿Cómo me inscribo?', () => _preguntar('¿Cómo me inscribo?')),
        _Accion('¿Cómo se paga?', () => _preguntar('¿Cómo se paga?')),
        _Accion('Hablar con el administrador', _irAEnviar),
      ],
    ));
  }

  @override
  void dispose() {
    _entrada.dispose();
    _scroll.dispose();
    _nombre.dispose();
    _correo.dispose();
    _mensaje.dispose();
    _codigo.dispose();
    _correoConsulta.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _irAEnviar() {
    setState(() {
      _modo = _Modo.enviar;
      _error = null;
      if (_mensaje.text.trim().isEmpty) _mensaje.text = _ultimaPregunta;
    });
  }

  // ------------------------------------------------------------- Chat automático
  void _preguntar(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return;
    _entrada.clear();
    _ultimaPregunta = t;

    final respuestas = <_Msg>[];
    if (_Motor.pideHumano(t)) {
      respuestas.add(_Msg(
        false,
        'Claro, puedes enviar tu consulta al administrador y te responderá '
        'desde su panel.',
        acciones: [_Accion('Escribir al administrador', _irAEnviar)],
      ));
    } else {
      final coincidencias = _Motor.buscar(t);
      if (coincidencias.isNotEmpty) {
        final mejor = coincidencias.first;
        final otras = coincidencias.skip(1).take(2).toList();
        respuestas.add(_Msg(
          false,
          '${mejor.pregunta}\n\n${mejor.respuesta}',
          acciones: [
            _Accion('Me sirvió', () => _agregarBot(
                '¡Me alegra haber ayudado! Si necesitas algo más, aquí estoy.')),
            for (final o in otras)
              _Accion(o.pregunta, () => _mostrarFaq(o)),
            _Accion('Hablar con el administrador', _irAEnviar),
          ],
        ));
      } else if (_Motor.esSaludo(t)) {
        respuestas.add(const _Msg(false,
            '¡Hola! Cuéntame tu duda sobre inscripciones, pagos, cupos o tu cuenta.'));
      } else {
        respuestas.add(_Msg(
          false,
          'No estoy seguro de poder responder eso con lo que sé. Puedo enviar '
          'tu consulta al administrador para que te responda personalmente.',
          acciones: [_Accion('Enviar al administrador', _irAEnviar)],
        ));
      }
    }
    setState(() {
      _msgs.add(_Msg(true, t));
      _msgs.addAll(respuestas);
    });
    _bajar();
  }

  void _mostrarFaq(FaqItem f) {
    setState(() => _msgs.add(_Msg(
          false,
          '${f.pregunta}\n\n${f.respuesta}',
          acciones: [_Accion('Hablar con el administrador', _irAEnviar)],
        )));
    _bajar();
  }

  void _agregarBot(String texto) {
    setState(() => _msgs.add(_Msg(false, texto)));
    _bajar();
  }

  // --------------------------------------------------- Enviar al administrador
  String _generarCodigo() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => letras[r.nextInt(letras.length)]).join();
  }

  Future<void> _enviar() async {
    final nombre = _nombre.text.trim();
    final correo = _correo.text.trim();
    final mensaje = _mensaje.text.trim();
    if (nombre.isEmpty || correo.isEmpty || mensaje.isEmpty) {
      setState(() => _error = 'Completa tu nombre, correo y consulta.');
      return;
    }
    if (!correo.contains('@') || !correo.contains('.')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final codigo = _generarCodigo();
      await FirebaseFirestore.instance.collection('soporte_consultas').add({
        'codigo': codigo,
        'nombre': nombre,
        'correo': correo,
        'correoMin': correo.toLowerCase(),
        'mensaje': mensaje,
        'estado': 'Pendiente',
        'respuesta': '',
        'uid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'creadoEn': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _modo = _Modo.chat;
        _mensaje.clear();
        _codigoPendiente = codigo;
        _msgs.add(_Msg(
          false,
          'Listo, enviamos tu consulta al administrador.\n\n'
          'Tu código es: $codigo\n'
          'Guárdalo: con ese código y tu correo puedes ver la respuesta cuando '
          'esté lista, en "Ver mi respuesta".',
          acciones: [_Accion('Ver mi respuesta', _irAConsultar)],
        ));
      });
      _bajar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = 'No se pudo enviar la consulta: $e';
      });
    }
  }

  String _codigoPendiente = '';

  // ------------------------------------------------------------ Ver mi respuesta
  void _irAConsultar() {
    setState(() {
      _modo = _Modo.consultar;
      _resultado = null;
      if (_codigo.text.isEmpty && _codigoPendiente.isNotEmpty) {
        _codigo.text = _codigoPendiente;
      }
    });
  }

  Future<void> _consultar() async {
    final cod = _codigo.text.trim().toUpperCase();
    final correo = _correoConsulta.text.trim().toLowerCase();
    if (cod.isEmpty || correo.isEmpty) {
      setState(() => _resultado = 'Escribe tu código y tu correo.');
      return;
    }
    setState(() {
      _buscando = true;
      _resultado = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('soporte_consultas')
          .where('codigo', isEqualTo: cod)
          .limit(1)
          .get();
      String texto;
      if (snap.docs.isEmpty ||
          ((snap.docs.first.data()['correoMin'] ??
                      snap.docs.first.data()['correo'] ??
                      '')
                  .toString()
                  .toLowerCase() !=
              correo)) {
        texto = 'No encontramos una consulta con ese código y correo. '
            'Revisa que estén escritos igual que al enviarla.';
      } else {
        final d = snap.docs.first.data();
        final respuesta = (d['respuesta'] ?? '').toString().trim();
        if ((d['estado'] ?? 'Pendiente') == 'Respondida' &&
            respuesta.isNotEmpty) {
          texto = 'Tu consulta:\n${d['mensaje'] ?? ''}\n\n'
              'Respuesta del administrador:\n$respuesta';
        } else {
          texto = 'Tu consulta sigue pendiente. El administrador la '
              'responderá pronto; vuelve a revisar más tarde.';
        }
      }
      if (mounted) setState(() => _resultado = texto);
    } catch (e) {
      if (mounted) setState(() => _resultado = 'No se pudo consultar: $e');
    }
    if (mounted) setState(() => _buscando = false);
  }

  // ------------------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: min(640, size.height * 0.88),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _encabezado(),
            Flexible(
              child: switch (_modo) {
                _Modo.chat => _vistaChat(),
                _Modo.enviar => _vistaEnviar(),
                _Modo.consultar => _vistaConsultar(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    final String titulo = switch (_modo) {
      _Modo.chat => 'Soporte VirtuMet',
      _Modo.enviar => 'Escribir al administrador',
      _Modo.consultar => 'Ver mi respuesta',
    };
    return Container(
      color: _azul,
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      child: Row(
        children: [
          if (_modo != _Modo.chat)
            IconButton(
              tooltip: 'Volver al chat',
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _modo = _Modo.chat),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _vistaChat() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.builder(
            controller: _scroll,
            shrinkWrap: true,
            padding: const EdgeInsets.all(14),
            itemCount: _msgs.length,
            itemBuilder: (_, i) => _burbuja(_msgs[i]),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entrada,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu duda…',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: _preguntar,
                ),
              ),
              IconButton(
                tooltip: 'Enviar',
                icon: const Icon(Icons.send, color: _naranja),
                onPressed: () => _preguntar(_entrada.text),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: _irAEnviar,
                child: const Text('Escribir al administrador'),
              ),
              TextButton(
                onPressed: _irAConsultar,
                child: const Text('Ver mi respuesta'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _burbuja(_Msg m) {
    return Align(
      alignment: m.usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment:
              m.usuario ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: m.usuario ? _naranja : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                m.texto,
                style: TextStyle(
                  color: m.usuario ? Colors.white : Colors.black87,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ),
            if (m.acciones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in m.acciones)
                      ActionChip(
                        label: Text(a.etiqueta,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _azul),
                        onPressed: a.onTap,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _campo(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        isDense: true,
        border: const OutlineInputBorder(),
      );

  Widget _vistaEnviar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuéntanos tu duda. El administrador la revisará y te responderá. '
            'Podrás ver la respuesta con tu código y tu correo.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(controller: _nombre, decoration: _campo('Tu nombre')),
          const SizedBox(height: 10),
          TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: _campo('Tu correo'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mensaje,
            maxLines: 4,
            decoration: _campo('Tu consulta'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _naranja),
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
              label: const Text('Enviar consulta'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaConsultar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escribe el código que recibiste al enviar tu consulta y el correo '
            'que usaste.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            decoration: _campo('Código (6 caracteres)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _correoConsulta,
            keyboardType: TextInputType.emailAddress,
            decoration: _campo('Correo'),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _naranja),
              onPressed: _buscando ? null : _consultar,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Buscar'),
            ),
          ),
          if (_buscando)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_resultado != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(_resultado!,
                  style: const TextStyle(height: 1.4, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }
}
