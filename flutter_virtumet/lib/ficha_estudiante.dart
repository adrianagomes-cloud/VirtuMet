import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Ficha deportiva personal de cada estudiante.
///
/// - La PLANTILLA (qué campos se piden) la define el admin y vive en
///   `config/fichaDeportiva` (ver admin_fichas_view.dart).
/// - La FICHA de cada estudiante vive en `fichas/{uid}`:
///     { estudianteId, nombreEstudiante, correoEstudiante,
///       respuestas: {idCampo: valor}, etiquetas: {idCampo: etiqueta},
///       actualizado }
///   Es una sola ficha por estudiante: se llena la primera vez que se inscribe
///   y se reutiliza en las siguientes inscripciones. Si el admin agrega un campo
///   obligatorio nuevo, al próximo intento de inscripción se le pide completarlo.
/// - El estudiante usa [asegurarFichaCompleta] antes de pagar.
/// - El admin usa [mostrarFichaDeEstudiante] para ver la ficha de un estudiante.

class FichaCampo {
  final String id;
  final String etiqueta;
  final String tipo; // 'texto' | 'numero' | 'si_no'
  final bool obligatorio;
  const FichaCampo({
    required this.id,
    required this.etiqueta,
    required this.tipo,
    required this.obligatorio,
  });
}

/// Campos que se usan si el admin todavía no guardó una plantilla.
/// Debe coincidir con los de admin_fichas_view.dart.
const List<List<String>> _camposPorDefecto = [
  ['tipoSangre', 'Tipo de sangre', 'texto'],
  ['alergias', 'Alergias conocidas', 'texto'],
  ['condiciones', 'Condiciones médicas relevantes', 'texto'],
  ['contactoNombre', 'Contacto de emergencia (nombre)', 'texto'],
  ['contactoTelefono', 'Contacto de emergencia (teléfono)', 'texto'],
  ['aptoFisico', 'Declaro estar apto para la actividad física', 'si_no'],
];

/// Lee la plantilla vigente desde Firestore.
Future<List<FichaCampo>> cargarPlantillaFicha() async {
  final snap = await FirebaseFirestore.instance
      .collection('config')
      .doc('fichaDeportiva')
      .get();
  final raw = (snap.data()?['campos'] as List?) ?? [];
  final campos = raw
      .map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return FichaCampo(
          id: (m['id'] ?? '').toString(),
          etiqueta: (m['etiqueta'] ?? '').toString(),
          tipo: (m['tipo'] ?? 'texto').toString(),
          obligatorio: m['obligatorio'] == true,
        );
      })
      .where((c) => c.id.isNotEmpty && c.etiqueta.trim().isNotEmpty)
      .toList();
  if (campos.isEmpty) {
    return _camposPorDefecto
        .map((c) => FichaCampo(
            id: c[0], etiqueta: c[1], tipo: c[2], obligatorio: true))
        .toList();
  }
  return campos;
}

Map<String, String> _leerRespuestas(Map<String, dynamic>? data) {
  final raw = data?['respuestas'];
  if (raw is! Map) return {};
  return raw.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
}

/// True si todos los campos obligatorios de la plantilla tienen respuesta.
bool fichaCompleta(List<FichaCampo> campos, Map<String, String> respuestas) {
  return campos.every(
      (c) => !c.obligatorio || (respuestas[c.id] ?? '').trim().isNotEmpty);
}

/// Estudiante: garantiza que su ficha esté completa antes de inscribirse.
/// Si ya está completa devuelve true sin mostrar nada. Si falta algo, abre el
/// formulario; devuelve true solo si el estudiante lo guardó.
Future<bool> asegurarFichaCompleta(
  BuildContext context, {
  required String uid,
  required String nombre,
  required String correo,
}) async {
  if (uid.isEmpty) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final campos = await cargarPlantillaFicha();
    final ref = FirebaseFirestore.instance.collection('fichas').doc(uid);
    final snap = await ref.get();
    final previas = _leerRespuestas(snap.data());
    if (fichaCompleta(campos, previas)) return true;

    if (!context.mounted) return false;
    final nuevas = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _FichaDialog(campos: campos, iniciales: previas, nombre: nombre),
    );
    if (nuevas == null) return false; // el estudiante canceló

    await ref.set({
      'estudianteId': uid,
      'nombreEstudiante': nombre,
      'correoEstudiante': correo,
      'respuestas': nuevas,
      'etiquetas': {for (final c in campos) c.id: c.etiqueta},
      'actualizado': FieldValue.serverTimestamp(),
    });
    messenger.showSnackBar(const SnackBar(
      content: Text('Ficha deportiva guardada.'),
      backgroundColor: Colors.green,
    ));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text('No se pudo cargar o guardar la ficha: $e'),
      backgroundColor: Colors.red,
    ));
    return false;
  }
}

/// Formulario de la ficha (el estudiante lo completa).
class _FichaDialog extends StatefulWidget {
  final List<FichaCampo> campos;
  final Map<String, String> iniciales;
  final String nombre;
  const _FichaDialog({
    required this.campos,
    required this.iniciales,
    required this.nombre,
  });

  @override
  State<_FichaDialog> createState() => _FichaDialogState();
}

class _FichaDialogState extends State<_FichaDialog> {
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, String> _sino = {};
  final Set<String> _errores = {};

  @override
  void initState() {
    super.initState();
    for (final c in widget.campos) {
      final previo = widget.iniciales[c.id] ?? '';
      if (c.tipo == 'si_no') {
        if (previo == 'Sí' || previo == 'No') _sino[c.id] = previo;
      } else {
        _ctrl[c.id] = TextEditingController(text: previo);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _valor(FichaCampo c) =>
      c.tipo == 'si_no' ? (_sino[c.id] ?? '') : (_ctrl[c.id]?.text.trim() ?? '');

  void _guardar() {
    final errores = <String>{};
    for (final c in widget.campos) {
      final v = _valor(c);
      if (c.obligatorio && v.isEmpty) errores.add(c.id);
      if (c.tipo == 'numero' &&
          v.isNotEmpty &&
          double.tryParse(v.replaceAll(',', '.')) == null) {
        errores.add(c.id);
      }
    }
    if (errores.isNotEmpty) {
      setState(() {
        _errores
          ..clear()
          ..addAll(errores);
      });
      return;
    }
    Navigator.pop(context, {for (final c in widget.campos) c.id: _valor(c)});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ficha deportiva'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Completa tu ficha antes de inscribirte'
                '${widget.nombre.isEmpty ? '' : ', ${widget.nombre}'}. '
                'Solo la llenas una vez.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              for (final c in widget.campos) ...[
                if (c.tipo == 'si_no')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.obligatorio ? '${c.etiqueta} *' : c.etiqueta),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        emptySelectionAllowed: true,
                        segments: const [
                          ButtonSegment(value: 'Sí', label: Text('Sí')),
                          ButtonSegment(value: 'No', label: Text('No')),
                        ],
                        selected:
                            _sino[c.id] == null ? <String>{} : {_sino[c.id]!},
                        onSelectionChanged: (s) => setState(() {
                          if (s.isEmpty) {
                            _sino.remove(c.id);
                          } else {
                            _sino[c.id] = s.first;
                          }
                          _errores.remove(c.id);
                        }),
                      ),
                      if (_errores.contains(c.id))
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Elige una opción',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  )
                else
                  TextField(
                    controller: _ctrl[c.id],
                    keyboardType: c.tipo == 'numero'
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: c.obligatorio ? '${c.etiqueta} *' : c.etiqueta,
                      errorText: _errores.contains(c.id)
                          ? (c.tipo == 'numero'
                              ? 'Escribe un número válido'
                              : 'Este campo es obligatorio')
                          : null,
                    ),
                    onChanged: (_) {
                      if (_errores.contains(c.id)) {
                        setState(() => _errores.remove(c.id));
                      }
                    },
                  ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5500),
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          child: const Text('Guardar y continuar'),
        ),
      ],
    );
  }
}

/// Admin: muestra el perfil completo de un estudiante (solo lectura):
/// sus datos, su ficha deportiva y las disciplinas en las que está inscrito.
Future<void> mostrarFichaDeEstudiante(
  BuildContext context, {
  required String uid,
  required String nombre,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (uid.isEmpty) {
    messenger.showSnackBar(const SnackBar(
      content: Text('No se pudo identificar al estudiante.'),
      backgroundColor: Colors.red,
    ));
    return;
  }
  try {
    final db = FirebaseFirestore.instance;
    final campos = await cargarPlantillaFicha();
    final fichaSnap = await db.collection('fichas').doc(uid).get();
    final userSnap = await db.collection('users').doc(uid).get();
    final inscSnap = await db
        .collection('inscripciones')
        .where('estudianteId', isEqualTo: uid)
        .get();
    if (!context.mounted) return;

    final data = fichaSnap.data();
    final respuestas = _leerRespuestas(data);
    final etiquetasGuardadas = (data?['etiquetas'] is Map)
        ? (data!['etiquetas'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString()))
        : <String, String>{};

    // Filas de la ficha: primero los campos de la plantilla actual, luego
    // respuestas antiguas de campos que el admin ya quitó de la plantilla.
    final filas = <MapEntry<String, String>>[
      for (final c in campos) MapEntry(c.etiqueta, respuestas[c.id] ?? ''),
      for (final e in respuestas.entries)
        if (!campos.any((c) => c.id == e.key))
          MapEntry(etiquetasGuardadas[e.key] ?? e.key, e.value),
    ];

    String fecha(dynamic ts) {
      if (ts is! Timestamp) return '';
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    // Datos personales (colección users)
    final u = userSnap.data() ?? <String, dynamic>{};
    final datos = <MapEntry<String, String>>[
      MapEntry('Correo', (u['correo'] ?? '').toString()),
      MapEntry('Carnet', (u['carnet'] ?? '').toString()),
      MapEntry('Carrera', (u['carrera'] ?? '').toString()),
      MapEntry('Estado de la cuenta', (u['estado'] ?? 'Activo').toString()),
    ];

    // Inscripciones del estudiante, las más recientes primero
    final inscripciones = inscSnap.docs.map((d) => d.data()).toList()
      ..sort((a, b) {
        final ta = a['fechaInscripcion'];
        final tb = b['fechaInscripcion'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(t,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF0F2C59))),
        );

    Widget par(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Text(v.isEmpty ? '—' : v,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nombre),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titulo('Datos del estudiante'),
                for (final d in datos) par(d.key, d.value),
                const Divider(),
                titulo('Ficha deportiva'),
                if (!fichaSnap.exists)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('Aún no ha completado su ficha. Se le pedirá '
                        'al inscribirse en su primera disciplina.'),
                  )
                else ...[
                  for (final f in filas) par(f.key, f.value),
                  if (fecha(data?['actualizado']).isNotEmpty)
                    Text(
                        'Última actualización: ${fecha(data?['actualizado'])}',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 12)),
                ],
                const Divider(),
                titulo('Disciplinas inscritas'),
                if (inscripciones.isEmpty)
                  const Text('No tiene inscripciones.')
                else
                  for (final m in inscripciones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m['nombreDeporte'] ?? 'Disciplina'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${m['estado'] ?? 'Confirmada'}'
                            '  ·  ${m['horario'] ?? ''}'
                            '  ·  ${m['pagado'] == true ? 'Pagado' : 'Sin pago'}',
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text('No se pudo cargar el perfil: $e'),
      backgroundColor: Colors.red,
    ));
  }
}
