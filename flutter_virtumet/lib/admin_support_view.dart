import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_common.dart';

/// Bandeja de Soporte del administrador.
///
/// Muestra las consultas que los visitantes enviaron desde el chat de Soporte
/// (colección `soporte_consultas`) y permite responderlas. Al responder, la
/// consulta pasa a 'Respondida' y el visitante ve la respuesta con su código.
class AdminSupportView extends StatefulWidget {
  const AdminSupportView({super.key});

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  String _filtro = 'Pendiente'; // 'Pendiente' | 'Respondida' | 'Todas'

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      children: [
        const SectionTitle(
          title: 'Soporte',
          subtitle:
              'Consultas que los usuarios no pudieron resolver con las respuestas automáticas.',
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('soporte_consultas')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Error: ${snap.error}');
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final todas = snap.data!.docs.toList();
            String estadoDe(QueryDocumentSnapshot d) =>
                ((d.data() as Map)['estado'] ?? 'Pendiente').toString();
            final pendientes =
                todas.where((d) => estadoDe(d) != 'Respondida').length;

            final docs = todas.where((d) {
              if (_filtro == 'Todas') return true;
              final resp = estadoDe(d) == 'Respondida';
              return _filtro == 'Respondida' ? resp : !resp;
            }).toList()
              ..sort((a, b) {
                final ta = (a.data() as Map)['creadoEn'];
                final tb = (b.data() as Map)['creadoEn'];
                // Las recién enviadas aún no tienen fecha del servidor: van arriba.
                if (ta is! Timestamp) return -1;
                if (tb is! Timestamp) return 1;
                return tb.compareTo(ta);
              });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final f in const ['Pendiente', 'Respondida', 'Todas'])
                      ChoiceChip(
                        label: Text(f == 'Pendiente'
                            ? 'Pendientes ($pendientes)'
                            : f == 'Respondida'
                                ? 'Respondidas'
                                : 'Todas'),
                        selected: _filtro == f,
                        selectedColor: kOrange.withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _filtro = f),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  AdminCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_filtro == 'Pendiente'
                            ? 'No hay consultas pendientes. 🎉'
                            : 'No hay consultas para mostrar.'),
                      ),
                    ),
                  )
                else
                  for (final d in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConsultaCard(key: ValueKey(d.id), doc: d),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ConsultaCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _ConsultaCard({super.key, required this.doc});

  @override
  State<_ConsultaCard> createState() => _ConsultaCardState();
}

class _ConsultaCardState extends State<_ConsultaCard> {
  late final TextEditingController _respuesta;
  bool _editando = false;
  bool _guardando = false;

  Map<String, dynamic> get _m => widget.doc.data() as Map<String, dynamic>;
  bool get _respondida => (_m['estado'] ?? 'Pendiente') == 'Respondida';

  @override
  void initState() {
    super.initState();
    _respuesta = TextEditingController(text: (_m['respuesta'] ?? '').toString());
  }

  @override
  void dispose() {
    _respuesta.dispose();
    super.dispose();
  }

  String _fecha(dynamic t) {
    if (t is! Timestamp) return 'ahora mismo';
    final d = t.toDate();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }

  Future<void> _responder() async {
    final txt = _respuesta.text.trim();
    if (txt.isEmpty) {
      showMsg(context, 'Escribe una respuesta antes de enviarla.', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.doc.reference.update({
        'respuesta': txt,
        'estado': 'Respondida',
        'respondidoEn': FieldValue.serverTimestamp(),
        'respondidoPor': FirebaseAuth.instance.currentUser?.email ?? 'admin',
      });
      if (mounted) {
        setState(() => _editando = false);
        showMsg(context, 'Respuesta enviada.');
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo responder: $e', error: true);
    }
    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar consulta'),
        content: const Text('¿Eliminar esta consulta? No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.doc.reference.delete();
      if (mounted) showMsg(context, 'Consulta eliminada.');
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo eliminar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final color = _respondida ? Colors.green : Colors.orange;
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m['nombre'] ?? 'Sin nombre'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${m['correo'] ?? ''}  ·  ${_fecha(m['creadoEn'])}  ·  Código ${m['codigo'] ?? '-'}',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(_respondida ? 'Respondida' : 'Pendiente',
                    style: TextStyle(color: color)),
                side: BorderSide(color: color),
                backgroundColor: Colors.white,
              ),
              IconButton(
                tooltip: 'Eliminar consulta',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _eliminar,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText('${m['mensaje'] ?? ''}',
                style: const TextStyle(height: 1.4)),
          ),
          const SizedBox(height: 12),
          if (_respondida && !_editando) ...[
            const Text('Tu respuesta',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kNavy, fontSize: 13)),
            const SizedBox(height: 4),
            SelectableText('${m['respuesta'] ?? ''}',
                style: const TextStyle(height: 1.4)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _editando = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar respuesta'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _respuesta,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tu respuesta',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  if (_editando)
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => setState(() {
                                _editando = false;
                                _respuesta.text =
                                    (m['respuesta'] ?? '').toString();
                              }),
                      child: const Text('Cancelar'),
                    ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kOrange),
                    onPressed: _guardando ? null : _responder,
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(_respondida ? 'Guardar cambios' : 'Responder'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
