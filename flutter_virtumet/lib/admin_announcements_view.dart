import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Avisos administrables (CRUD sobre la colección `avisos` de Firestore).
///
/// Campos de cada aviso:
///   titulo, mensaje, prioridad (Normal | Importante | Urgente),
///   estado (Activo | Inactivo), creadoEn, actualizadoEn, creadoPor.
///
/// El admin puede crear, editar, activar/desactivar y eliminar avisos.
/// Los estudiantes solo ven los avisos en estado "Activo"
/// (ver student_announcements_view.dart).
class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  static const navy = Color(0xFF0F2C59);
  static const orange = Color(0xFFFF5500);

  final CollectionReference<Map<String, dynamic>> _avisos =
      FirebaseFirestore.instance.collection('avisos');

  Color _colorPrioridad(String p) {
    switch (p) {
      case 'Urgente':
        return Colors.red;
      case 'Importante':
        return orange;
      default:
        return navy;
    }
  }

  String _fecha(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _msg(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  /// Abre el formulario para crear (doc == null) o editar un aviso.
  Future<void> _abrirFormulario({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AvisoDialog(inicial: doc?.data()),
    );
    if (resultado == null) return;

    try {
      final datos = <String, dynamic>{
        'titulo': resultado['titulo'],
        'mensaje': resultado['mensaje'],
        'prioridad': resultado['prioridad'],
        'actualizadoEn': FieldValue.serverTimestamp(),
      };
      if (doc == null) {
        // Aviso nuevo: nace activo
        datos['estado'] = 'Activo';
        datos['creadoEn'] = FieldValue.serverTimestamp();
        datos['creadoPor'] = FirebaseAuth.instance.currentUser?.email ?? '';
        await _avisos.add(datos);
        _msg('Aviso publicado.');
      } else {
        // Al editar se conserva el estado actual (Activo / Inactivo)
        await doc.reference.update(datos);
        _msg('Aviso actualizado.');
      }
    } catch (e) {
      _msg('No se pudo guardar el aviso: $e', error: true);
    }
  }

  Future<void> _cambiarEstado(DocumentSnapshot<Map<String, dynamic>> doc, bool activo) async {
    try {
      await doc.reference.update({
        'estado': activo ? 'Activo' : 'Inactivo',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _msg('No se pudo cambiar el estado: $e', error: true);
    }
  }

  Future<void> _eliminar(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final titulo = (doc.data()?['titulo'] ?? 'este aviso').toString();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar aviso'),
        content: Text('Se eliminará "$titulo" definitivamente. '
            'Si solo quieres ocultarlo a los estudiantes, desactívalo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await doc.reference.delete();
      _msg('Aviso eliminado.');
    } catch (e) {
      _msg('No se pudo eliminar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVISOS',
                      style: TextStyle(
                          color: orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  SizedBox(height: 4),
                  Text('Comunicados para estudiantes',
                      style: TextStyle(
                          color: navy,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo aviso'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: orange, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Los estudiantes solo ven los avisos activos. Desactiva un aviso para ocultarlo sin borrarlo.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _avisos.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error al cargar avisos: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Más recientes primero (se ordena aquí para no exigir índices)
              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final ta = a.data()['creadoEn'];
                  final tb = b.data()['creadoEn'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  if (ta is Timestamp) return -1;
                  if (tb is Timestamp) return 1;
                  return 0;
                });
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Todavía no hay avisos. Pulsa "Nuevo aviso" para publicar el primero.'),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final prioridad = (data['prioridad'] ?? 'Normal').toString();
                  final activo = (data['estado'] ?? 'Activo') == 'Activo';
                  final color = _colorPrioridad(prioridad);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Opacity(
                      opacity: activo ? 1 : 0.55,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              prioridad == 'Urgente'
                                  ? Icons.warning_rounded
                                  : Icons.campaign_outlined,
                              color: color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (data['titulo'] ?? 'Aviso').toString(),
                                          style: const TextStyle(
                                              color: navy,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(prioridad,
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text((data['mensaje'] ?? '').toString()),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if (_fecha(data['creadoEn']).isNotEmpty)
                                        'Publicado el ${_fecha(data['creadoEn'])}',
                                      if ((data['creadoPor'] ?? '').toString().isNotEmpty)
                                        'por ${data['creadoPor']}',
                                    ].join(' '),
                                    style: const TextStyle(
                                        color: Colors.black45, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(activo ? 'Activo' : 'Inactivo'),
                            Switch(
                              value: activo,
                              activeThumbColor: orange,
                              onChanged: (v) => _cambiarEstado(doc, v),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: () => _abrirFormulario(doc: doc),
                              icon: const Icon(Icons.edit_outlined, color: navy),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminar(doc),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Formulario de aviso (crear / editar). Es un widget propio para que los
/// controladores se liberen solos al cerrarse.
class _AvisoDialog extends StatefulWidget {
  final Map<String, dynamic>? inicial;
  const _AvisoDialog({this.inicial});

  @override
  State<_AvisoDialog> createState() => _AvisoDialogState();
}

class _AvisoDialogState extends State<_AvisoDialog> {
  late final TextEditingController _titulo;
  late final TextEditingController _mensaje;
  late String _prioridad;
  bool _intentoGuardar = false;

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController(text: (widget.inicial?['titulo'] ?? '').toString());
    _mensaje = TextEditingController(text: (widget.inicial?['mensaje'] ?? '').toString());
    _prioridad = (widget.inicial?['prioridad'] ?? 'Normal').toString();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  void _guardar() {
    setState(() => _intentoGuardar = true);
    final titulo = _titulo.text.trim();
    final mensaje = _mensaje.text.trim();
    if (titulo.isEmpty || mensaje.isEmpty) return;
    Navigator.pop(context, {
      'titulo': titulo,
      'mensaje': mensaje,
      'prioridad': _prioridad,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Nuevo aviso' : 'Editar aviso'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titulo,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  errorText: _intentoGuardar && _titulo.text.trim().isEmpty
                      ? 'El título es obligatorio'
                      : null,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mensaje,
                maxLines: 4,
                maxLength: 400,
                decoration: InputDecoration(
                  labelText: 'Mensaje *',
                  errorText: _intentoGuardar && _mensaje.text.trim().isEmpty
                      ? 'El mensaje es obligatorio'
                      : null,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final p in const ['Normal', 'Importante', 'Urgente'])
                      ChoiceChip(
                        label: Text(p),
                        selected: _prioridad == p,
                        onSelected: (_) => setState(() => _prioridad = p),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              foregroundColor: Colors.white),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
