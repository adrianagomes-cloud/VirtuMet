import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Selector de "Lugar / Instalación" para el formulario de disciplinas.
///
/// Las opciones salen solas de dos fuentes, sin repetirse:
///  - la colección `canchas` (las canchas creadas con "+ Nueva cancha"), y
///  - el campo `lugar` de las disciplinas que ya existen.
/// Al crear una cancha nueva se guarda en `canchas` y aparece enseguida en la
/// lista de todas las disciplinas.
///
/// El valor elegido se escribe en [controller], así que el formulario sigue
/// leyendo `controller.text` como antes (validación de choques y guardado).
class CanchaSelector extends StatefulWidget {
  final TextEditingController controller;

  /// Mismo estilo de campo que usa el resto del formulario.
  final InputDecoration Function(IconData icon, {String? hint})
      decorationBuilder;

  const CanchaSelector({
    super.key,
    required this.controller,
    required this.decorationBuilder,
  });

  @override
  State<CanchaSelector> createState() => _CanchaSelectorState();
}

/// Una cancha de la lista, con lo necesario para administrarla.
class _CanchaItem {
  final String nombre;
  final String clave;
  final List<DocumentReference> refs; // documentos en `canchas` (si existen)
  final List<String> usadaPor; // disciplinas que la usan
  _CanchaItem(this.nombre, this.clave, this.refs, this.usadaPor);
}

class _CanchaSelectorState extends State<CanchaSelector> {
  static const Color blueDark = Color(0xFF0F2C59);
  static const String _nueva = '__nueva_cancha__';
  static const String _administrar = '__administrar_canchas__';

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _canchasStream =
      FirebaseFirestore.instance.collection('canchas').snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _deportesStream =
      FirebaseFirestore.instance.collection('deportes').snapshots();

  // clave normalizada -> nombre para mostrar (se actualiza en cada build)
  Map<String, String> _opciones = {};
  // Se incrementa para recrear el campo y que no quede mostrando una opción de acción.
  int _rev = 0;
  // canchas "reales" (en `canchas` o usadas por una disciplina), para administrar
  List<_CanchaItem> _items = [];

  /// "Cancha  Techada 1 " y "cancha techada 1" cuentan como la misma cancha.
  String _clave(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  void _elegir(String nombre) {
    setState(() {
      widget.controller.text = nombre;
      _rev++;
    });
  }

  Future<void> _crearNueva() async {
    final ctrl = TextEditingController();
    String? error;
    final String? nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Nueva cancha',
              style: TextStyle(color: blueDark, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 340,
            child: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej. Cancha Techada 3',
                errorText: error,
              ),
              onSubmitted: (_) {
                if (ctrl.text.trim().isEmpty) {
                  setD(() => error = 'Escribe el nombre de la cancha');
                } else {
                  Navigator.pop(ctx, ctrl.text);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  setD(() => error = 'Escribe el nombre de la cancha');
                  return;
                }
                Navigator.pop(ctx, ctrl.text);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (nombre == null) {
      setState(() => _rev++); // cancelado: vuelve a mostrar la cancha elegida
      return;
    }

    final String limpio = nombre.trim().replaceAll(RegExp(r'\s+'), ' ');
    final existente = _opciones[_clave(limpio)];
    if (existente != null) {
      // Ya existía (quizá con otras mayúsculas): se elige la que ya está.
      _elegir(existente);
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('canchas').add({
        'nombre': limpio,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Si no se pudo guardar en `canchas`, igual queda elegida: al guardar la
      // disciplina el lugar también aparecerá en la lista.
    }
    if (!mounted) return;
    _elegir(limpio);
  }

  /// Ventana para ver las canchas y eliminar las que no se usan.
  Future<void> _administrarCanchas() async {
    final items = List<_CanchaItem>.from(_items)
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Administrar canchas',
              style: TextStyle(color: blueDark, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 440,
            height: 360,
            child: items.isEmpty
                ? const Center(child: Text('No hay canchas registradas.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final bool enUso = it.usadaPor.isNotEmpty;
                      final bool borrable = it.refs.isNotEmpty && !enUso;
                      String detalle;
                      if (enUso) {
                        detalle = 'En uso: ${it.usadaPor.join(', ')}';
                      } else {
                        detalle = 'Sin disciplinas';
                      }
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(it.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(detalle,
                            style: const TextStyle(fontSize: 12)),
                        trailing: borrable
                            ? IconButton(
                                tooltip: 'Eliminar cancha',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: ctx,
                                    builder: (c2) => AlertDialog(
                                      title: const Text('Eliminar cancha'),
                                      content: Text(
                                          '¿Eliminar "${it.nombre}" de la lista de canchas?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c2, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white),
                                          onPressed: () =>
                                              Navigator.pop(c2, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;
                                  try {
                                    for (final r in it.refs) {
                                      await r.delete();
                                    }
                                    // Si era la cancha elegida en el formulario, se limpia.
                                    if (_clave(widget.controller.text) ==
                                        it.clave) {
                                      widget.controller.text = '';
                                    }
                                    setD(() => items.removeAt(i));
                                  } catch (_) {
                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No se pudo eliminar la cancha.'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                },
                              )
                            : Tooltip(
                                message: enUso
                                    ? 'Cambia el lugar de esas disciplinas para poder eliminarla'
                                    : 'Se quita sola de la lista cuando ninguna disciplina la usa',
                                child: const Icon(Icons.lock_outline,
                                    size: 18, color: Colors.grey),
                              ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lugar / Instalación',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12, color: blueDark),
        ),
        const SizedBox(height: 6),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _canchasStream,
          builder: (context, snapCanchas) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _deportesStream,
              builder: (context, snapDeportes) {
                final Map<String, String> mapa = {};
                final Map<String, List<DocumentReference>> refs = {};
                final Map<String, List<String>> usos = {};
                void agregar(dynamic valor) {
                  final String n = (valor ?? '')
                      .toString()
                      .trim()
                      .replaceAll(RegExp(r'\s+'), ' ');
                  if (n.isEmpty) return;
                  mapa.putIfAbsent(_clave(n), () => n);
                }

                for (final d in snapCanchas.data?.docs ?? const []) {
                  agregar(d.data()['nombre']);
                  final c = _clave((d.data()['nombre'] ?? '').toString());
                  if (c.isNotEmpty) {
                    refs.putIfAbsent(c, () => []).add(d.reference);
                  }
                }
                for (final d in snapDeportes.data?.docs ?? const []) {
                  agregar(d.data()['lugar']);
                  final c = _clave((d.data()['lugar'] ?? '').toString());
                  if (c.isNotEmpty) {
                    usos
                        .putIfAbsent(c, () => [])
                        .add((d.data()['nombre'] ?? 'Disciplina').toString());
                  }
                }
                // Canchas reales (sin contar el valor suelto del formulario)
                _items = mapa.entries
                    .map((e) => _CanchaItem(
                        e.value, e.key, refs[e.key] ?? [], usos[e.key] ?? []))
                    .toList();
                // Disciplina antigua con un lugar que no está en la lista.
                agregar(widget.controller.text);
                _opciones = mapa;

                final nombres = mapa.values.toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                final String? actual = mapa[_clave(widget.controller.text)];

                return DropdownButtonFormField<String>(
                  // La key recrea el campo cuando cambia la selección.
                  key: ValueKey('${actual ?? ''}#$_rev'),
                  initialValue: actual,
                  isExpanded: true,
                  decoration: widget.decorationBuilder(
                    Icons.location_on,
                    hint: 'Seleccionar cancha',
                  ),
                  items: [
                    ...nombres.map((n) => DropdownMenuItem<String>(
                          value: n,
                          child: Text(n, style: const TextStyle(fontSize: 13)),
                        )),
                    const DropdownMenuItem<String>(
                      value: _administrar,
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined,
                              size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('Administrar canchas…',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: _nueva,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 16, color: Color(0xFFFF5500)),
                          SizedBox(width: 6),
                          Text('Nueva cancha…',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFF5500),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    if (v == _nueva) {
                      _crearNueva();
                    } else if (v == _administrar) {
                      _administrarCanchas();
                    } else {
                      _elegir(v);
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
