import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_common.dart';
import 'ficha_estudiante.dart';

/// Plantilla de Ficha Deportiva (requisito "Gestión de Plantillas y Fichas").
/// El admin define los campos; el estudiante los completa antes de finalizar
/// su inscripción. Se guarda en un único documento: config/fichaDeportiva
///   { campos: [ {id, etiqueta, tipo, obligatorio} ], actualizado }
/// tipo: 'texto' | 'numero' | 'si_no'
class AdminFichasView extends StatefulWidget {
  const AdminFichasView({super.key});

  @override
  State<AdminFichasView> createState() => _AdminFichasViewState();
}

class _Campo {
  String id;
  String etiqueta;
  String tipo;
  bool obligatorio;
  _Campo(this.id, this.etiqueta, this.tipo, this.obligatorio);

  Map<String, dynamic> toMap() => {
        'id': id,
        'etiqueta': etiqueta,
        'tipo': tipo,
        'obligatorio': obligatorio,
      };
}

class _AdminFichasViewState extends State<AdminFichasView> {
  final _ref = FirebaseFirestore.instance.collection('config').doc('fichaDeportiva');
  final _nuevo = TextEditingController();
  List<_Campo> _campos = [];
  bool _loading = true;
  bool _saving = false;

  static const _porDefecto = [
    ['tipoSangre', 'Tipo de sangre', 'texto'],
    ['alergias', 'Alergias conocidas', 'texto'],
    ['condiciones', 'Condiciones médicas relevantes', 'texto'],
    ['contactoNombre', 'Contacto de emergencia (nombre)', 'texto'],
    ['contactoTelefono', 'Contacto de emergencia (teléfono)', 'texto'],
    ['aptoFisico', 'Declaro estar apto para la actividad física', 'si_no'],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nuevo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snap = await _ref.get();
      final raw = (snap.data()?['campos'] as List?) ?? [];
      _campos = raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _Campo(
          (m['id'] ?? '').toString(),
          (m['etiqueta'] ?? '').toString(),
          (m['tipo'] ?? 'texto').toString(),
          m['obligatorio'] == true,
        );
      }).toList();
      if (_campos.isEmpty) {
        _campos = _porDefecto.map((c) => _Campo(c[0], c[1], c[2], true)).toList();
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo cargar la plantilla: $e', error: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _agregar() {
    final txt = _nuevo.text.trim();
    if (txt.isEmpty) return;
    // id estable derivado de la etiqueta + marca de tiempo para evitar choques
    final id = 'campo_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _campos.add(_Campo(id, txt, 'texto', false));
      _nuevo.clear();
    });
  }

  Future<void> _guardar() async {
    if (_campos.isEmpty) {
      showMsg(context, 'La plantilla debe tener al menos un campo.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _ref.set({
        'campos': _campos.map((c) => c.toMap()).toList(),
        'actualizado': FieldValue.serverTimestamp(),
      });
      if (mounted) showMsg(context, 'Plantilla de ficha guardada.');
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo guardar: $e', error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AdminPage(
      children: [
        SectionTitle(
          title: 'Plantilla de Ficha Deportiva',
          subtitle:
              'Campos que cada estudiante debe completar antes de finalizar su inscripción.',
          trailing: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kOrange),
            onPressed: _saving ? null : _guardar,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
        const SizedBox(height: 16),
        AdminCard(
          child: Column(
            children: [
              for (int i = 0; i < _campos.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_campos[i].id),
                          initialValue: _campos[i].etiqueta,
                          decoration: const InputDecoration(
                            labelText: 'Etiqueta',
                            isDense: true,
                          ),
                          onChanged: (v) => _campos[i].etiqueta = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _campos[i].tipo,
                        items: const [
                          DropdownMenuItem(value: 'texto', child: Text('Texto')),
                          DropdownMenuItem(value: 'numero', child: Text('Número')),
                          DropdownMenuItem(value: 'si_no', child: Text('Sí / No')),
                        ],
                        onChanged: (v) => setState(() => _campos[i].tipo = v ?? 'texto'),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Oblig.', style: TextStyle(fontSize: 11)),
                          Switch(
                            value: _campos[i].obligatorio,
                            activeThumbColor: kOrange,
                            onChanged: (v) => setState(() => _campos[i].obligatorio = v),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Quitar campo',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _campos.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nuevo,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo campo',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _agregar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _agregar,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SectionTitle(
          title: 'Inscripciones',
          subtitle: 'Estudiantes inscritos por disciplina (en tiempo real).',
        ),
        const SizedBox(height: 16),
        const _InscripcionesList(),
      ],
    );
  }
}

/// Lista de inscripciones (colección `inscripciones`, escrita por el catálogo
/// del estudiante). Muestra estado y permite cancelar una inscripción.
class _InscripcionesList extends StatefulWidget {
  const _InscripcionesList();

  @override
  State<_InscripcionesList> createState() => _InscripcionesListState();
}

class _InscripcionesListState extends State<_InscripcionesList> {
  // Filtros de la vista: texto de búsqueda y estado ('Todas' | 'Confirmada' | 'Cancelada')
  String _busqueda = '';
  String _filtroEstado = 'Todas';

  Future<void> _cancelar(BuildContext context, QueryDocumentSnapshot d) async {
    final m = d.data() as Map<String, dynamic>;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: Text(
          '¿Cancelar la inscripción de ${m['nombreEstudiante'] ?? 'este estudiante'} '
          'en ${m['nombreDeporte'] ?? 'la disciplina'}? Se liberará el cupo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final db = FirebaseFirestore.instance;
      final deporteId = m['deporteId']?.toString();
      await db.runTransaction((transaction) async {
        DocumentSnapshot? deporte;
        if (deporteId != null && deporteId.isNotEmpty) {
          deporte =
              await transaction.get(db.collection('deportes').doc(deporteId));
        }
        transaction.update(d.reference, {'estado': 'Cancelada'});
        if (deporte != null && deporte.exists) {
          final data = deporte.data() as Map<String, dynamic>?;
          final inscritos = data?['cuposInscritos'];
          final inscritosActuales =
              inscritos is num ? inscritos.toInt() : int.tryParse('$inscritos') ?? 0;
          if (inscritosActuales > 0) {
            transaction.update(deporte.reference, {
              'cuposInscritos': FieldValue.increment(-1),
            });
          }
        }
      });
      if (context.mounted) showMsg(context, 'Inscripción cancelada y cupo liberado.');
    } catch (e) {
      if (context.mounted) showMsg(context, 'No se pudo cancelar: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inscripciones').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Text('Error: ${snap.error}');
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final todas = snap.data!.docs.toList();
        if (todas.isEmpty) {
          return const AdminCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aún no hay inscripciones.'),
              ),
            ),
          );
        }

        String estadoDe(QueryDocumentSnapshot d) =>
            ((d.data() as Map)['estado'] ?? 'Confirmada').toString();

        // Aplicar filtros (estado + búsqueda por estudiante, correo o disciplina)
        final q = _busqueda.trim().toLowerCase();
        final docs = todas.where((d) {
          final m = d.data() as Map<String, dynamic>;
          if (_filtroEstado != 'Todas' && estadoDe(d) != _filtroEstado) {
            return false;
          }
          if (q.isEmpty) return true;
          final texto =
              '${m['nombreEstudiante'] ?? ''} ${m['correoEstudiante'] ?? ''} ${m['nombreDeporte'] ?? ''}'
                  .toLowerCase();
          return texto.contains(q);
        }).toList();

        // Agrupar por disciplina
        final grupos = <String, List<QueryDocumentSnapshot>>{};
        for (final d in docs) {
          final nombre =
              ((d.data() as Map)['nombreDeporte'] ?? 'Sin disciplina').toString();
          grupos.putIfAbsent(nombre, () => []).add(d);
        }
        final nombres = grupos.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        // Dentro de cada grupo: activas primero, luego canceladas; más recientes arriba
        int porFecha(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
          final ta = (a.data() as Map)['fechaInscripcion'];
          final tb = (b.data() as Map)['fechaInscripcion'];
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          return 0;
        }

        for (final n in nombres) {
          grupos[n]!.sort((a, b) {
            final ca = estadoDe(a) == 'Cancelada' ? 1 : 0;
            final cb = estadoDe(b) == 'Cancelada' ? 1 : 0;
            if (ca != cb) return ca.compareTo(cb);
            return porFecha(a, b);
          });
        }

        final totalActivas = todas.where((d) => estadoDe(d) != 'Cancelada').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de búsqueda y filtros
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar estudiante, correo o disciplina',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                ),
                for (final f in const ['Todas', 'Confirmada', 'Cancelada'])
                  ChoiceChip(
                    label: Text(f == 'Confirmada'
                        ? 'Confirmadas'
                        : f == 'Cancelada'
                            ? 'Canceladas'
                            : 'Todas'),
                    selected: _filtroEstado == f,
                    selectedColor: kOrange.withOpacity(0.2),
                    onSelected: (_) => setState(() => _filtroEstado = f),
                  ),
                Text(
                  '${todas.length} inscripciones · $totalActivas activas',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const AdminCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay inscripciones que coincidan con el filtro.'),
                  ),
                ),
              ),
            for (final n in nombres) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 18, color: kNavy),
                    const SizedBox(width: 8),
                    Text(
                      n,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: kNavy),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${grupos[n]!.where((d) => estadoDe(d) != 'Cancelada').length} activas'
                      '${grupos[n]!.any((d) => estadoDe(d) == 'Cancelada') ? ' · ${grupos[n]!.where((d) => estadoDe(d) == 'Cancelada').length} canceladas' : ''}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              for (final d in grupos[n]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _row(context, d),
                ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, QueryDocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>;
    final estado = (m['estado'] ?? 'Confirmada').toString();
    final cancelada = estado == 'Cancelada';
    final color = cancelada ? Colors.redAccent : Colors.green;
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m['nombreEstudiante'] ?? 'Estudiante'}  ·  ${m['nombreDeporte'] ?? 'Disciplina'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${m['correoEstudiante'] ?? ''}  ·  ${m['horario'] ?? ''}  ·  ${m['lugar'] ?? ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                if (m['pagado'] == true)
                  Text(
                    'Pagado: \$${((m['montoPagado'] ?? m['precio'] ?? 0) as num).toStringAsFixed(2)} ${m['moneda'] ?? 'USD'}'
                    '  ·  ${m['metodoPago'] ?? 'PayPal'}  ·  Orden ${m['paypalOrderId'] ?? '-'}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  )
                else
                  const Text(
                    'Sin pago registrado',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(estado, style: TextStyle(color: color)),
            side: BorderSide(color: color),
            backgroundColor: Colors.white,
          ),
          IconButton(
            tooltip: 'Ver ficha del estudiante',
            icon: const Icon(Icons.assignment_ind_outlined, color: kNavy),
            onPressed: () => mostrarFichaDeEstudiante(
              context,
              uid: (m['estudianteId'] ?? '').toString(),
              nombre: (m['nombreEstudiante'] ?? 'Estudiante').toString(),
            ),
          ),
          if (!cancelada)
            IconButton(
              tooltip: 'Cancelar inscripción',
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: () => _cancelar(context, d),
            ),
        ],
      ),
    );
  }
}
