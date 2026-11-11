import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'precio_utils.dart';
import 'image_search_dialog.dart';
import 'cancha_selector.dart';

class AdminSportsView extends StatefulWidget {
  const AdminSportsView({super.key});

  @override
  State<AdminSportsView> createState() => _AdminSportsViewState();
}

class _AdminSportsViewState extends State<AdminSportsView> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  String _searchQuery = '';
  final String _selectedCategory = 'Todas las disciplinas';

  final List<String> _categories = [
    'Todas las disciplinas',
    'De equipo',
    'Individuales',
    'Bienestar',
  ];

  // ===========================================================================
  // HORARIO ESTRUCTURADO (días + hora de inicio + hora de fin)
  // ===========================================================================
  static const List<String> _diasSemana = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  /// Convierte una hora a texto legible, por ejemplo "3:00 PM".
  String _fmtHora(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final periodo = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $periodo';
  }

  /// Convierte una hora a "HH:mm" (24 h) para guardarla en Firestore.
  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Lee un texto "HH:mm" guardado en Firestore. Devuelve null si no es válido.
  TimeOfDay? _parseHora(String? s) {
    if (s == null) return null;
    final partes = s.split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  int _aMinutos(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Busca otras disciplinas que coincidan en día y hora con la que se está
  /// guardando, y que usen el mismo lugar o el mismo entrenador.
  /// Solo compara disciplinas que ya tengan horario estructurado.
  Future<List<String>> _buscarChoques({
    String? excluirId,
    required String lugar,
    String? entrenador,
    required Set<String> dias,
    required TimeOfDay inicio,
    required TimeOfDay fin,
  }) async {
    final snap = await FirebaseFirestore.instance.collection('deportes').get();
    final a1 = _aMinutos(inicio);
    final a2 = _aMinutos(fin);
    final avisos = <String>[];

    for (final otra in snap.docs) {
      if (otra.id == excluirId) continue;
      final m = otra.data();
      if ((m['estado'] ?? 'Activo') == 'Inactivo') continue;

      final otrosDias =
          ((m['horarioDias'] as List?) ?? []).map((e) => e.toString()).toSet();
      final otroInicio = _parseHora(m['horaInicio']?.toString());
      final otroFin = _parseHora(m['horaFin']?.toString());
      if (otroInicio == null ||
          otroFin == null ||
          otrosDias.intersection(dias).isEmpty) {
        continue;
      }

      final b1 = _aMinutos(otroInicio);
      final b2 = _aMinutos(otroFin);
      final seSolapan = a1 < b2 && b1 < a2;
      if (!seSolapan) continue;

      final nombreOtra = (m['nombre'] ?? 'otra disciplina').toString();
      final otroLugar = (m['lugar'] ?? '').toString().trim();
      if (lugar.isNotEmpty && otroLugar.toLowerCase() == lugar.toLowerCase()) {
        avisos.add('"$nombreOtra" usa el mismo lugar ($otroLugar) a esa hora.');
      }
      if (entrenador != null &&
          entrenador != 'Sin Entrenador' &&
          (m['entrenador'] ?? '').toString() == entrenador) {
        avisos.add('El entrenador ya da "$nombreOtra" a esa hora.');
      }
    }
    return avisos;
  }

  // ===========================================================================
  // CREAR / EDITAR DISCIPLINA (MEDIANTE ENLACE / URL)
  // ===========================================================================
  void _openDisciplineForm({DocumentSnapshot? doc}) {
    final isEditing = doc != null;
    final data = isEditing ? (doc.data() as Map<String, dynamic>) : {};

    final codigoCtrl = TextEditingController(text: data['codigo'] ?? '');
    final nombreCtrl = TextEditingController(text: data['nombre'] ?? '');
    final cupoMaxCtrl = TextEditingController(
        text: (data['cuposMaximos'] ?? data['cupoMaximo'] ?? 20).toString());
    // Horario estructurado: días + hora de inicio + hora de fin.
    final String horarioPrevio = (data['horario'] ?? '').toString();
    final Set<String> diasSel = ((data['horarioDias'] as List?) ?? [])
        .map((e) => e.toString())
        .toSet();
    TimeOfDay? horaIni = _parseHora(data['horaInicio']?.toString());
    TimeOfDay? horaFin = _parseHora(data['horaFin']?.toString());
    String? horarioError;
    final lugarCtrl = TextEditingController(text: data['lugar'] ?? '');
    final precioCtrl = TextEditingController(
        text: precioATexto(precioDeDisciplina(Map<String, dynamic>.from(data))));
    String? precioError;
    String? cupoError;
    final imageCtrl = TextEditingController(
        text: data['imageUrl'] ??
            'https://images.unsplash.com/photo-1517649763962-0c623266200a?auto=format&fit=crop&w=800&q=80');

    String categoriaVal = data['categoria'] ?? 'De equipo';
    String estadoVal = data['estado'] ?? 'Activo';
    String? entrenadorVal = data['entrenador'] as String?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: blueDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sports, color: blueDark),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Editar Disciplina' : 'Nueva Disciplina',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: 'Código Único',
                              controller: codigoCtrl,
                              hint: 'EJ. DE-001',
                              icon: Icons.qr_code,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFormField(
                              label: 'Cupo Máximo',
                              controller: cupoMaxCtrl,
                              hint: 'EJ. 20',
                              icon: Icons.people,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      if (cupoError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              cupoError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        label: 'Nombre de la Disciplina',
                        controller: nombreCtrl,
                        hint: 'EJ. Fútbol Sala - Mayores',
                        icon: Icons.sports_soccer,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        label:
                            'Precio de inscripción (USD) - mínimo ${formatPrecio(kPrecioMinimo)}',
                        controller: precioCtrl,
                        hint: 'EJ. 50',
                        icon: Icons.attach_money,
                        isNumber: true,
                      ),
                      if (precioError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            precioError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Categoría',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: blueDark),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _categories.contains(categoriaVal)
                                      ? categoriaVal
                                      : 'De equipo',
                                  decoration: _inputDecoration(Icons.category),
                                  items: _categories
                                      .where((c) => c != 'Todas las disciplinas')
                                      .map((cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDialogState(() => categoriaVal = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: blueDark),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: estadoVal,
                                  decoration: _inputDecoration(Icons.toggle_on),
                                  items: ['Activo', 'Mantenimiento', 'Inactivo']
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDialogState(() => estadoVal = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entrenador Asignado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: blueDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, snapshot) {
                              List<String> entrenadores = [];

                              if (snapshot.hasData && snapshot.data != null) {
                                for (var userDoc in snapshot.data!.docs) {
                                  final uData =
                                      userDoc.data() as Map<String, dynamic>;
                                  final String rol = (uData['rol'] ??
                                          uData['role'] ??
                                          '')
                                      .toString()
                                      .toLowerCase()
                                      .trim();

                                  if (rol.contains('entrenador') ||
                                      rol.contains('profesor') ||
                                      rol.contains('maestro')) {
                                    String nombreFinal = (uData['nombreApellido'] ??
                                            uData['nombreCompleto'] ??
                                            uData['nombre'] ??
                                            '')
                                        .toString()
                                        .trim();

                                    if (nombreFinal.isEmpty) {
                                      nombreFinal = (uData['correo'] ??
                                              uData['email'] ??
                                              '')
                                          .toString()
                                          .trim();
                                    }

                                    if (nombreFinal.isNotEmpty) {
                                      entrenadores.add(nombreFinal);
                                    }
                                  }
                                }
                              }

                              entrenadores = entrenadores.toSet().toList();

                              if (entrenadorVal != null &&
                                  entrenadorVal!.isNotEmpty &&
                                  !entrenadores.contains(entrenadorVal)) {
                                entrenadores.add(entrenadorVal!);
                              }

                              final String? selectedItem =
                                  (entrenadorVal != null &&
                                          entrenadores.contains(entrenadorVal))
                                      ? entrenadorVal
                                      : (entrenadores.isNotEmpty
                                          ? entrenadores.first
                                          : null);

                              // El dropdown muestra este valor por defecto, así que
                              // también debe guardarse (si no, se guarda "Sin Entrenador").
                              entrenadorVal ??= selectedItem;

                              return DropdownButtonFormField<String>(
                                initialValue: selectedItem,
                                decoration: _inputDecoration(
                                  Icons.person_outline,
                                  hint: 'Seleccionar entrenador',
                                ),
                                items: entrenadores.isEmpty
                                    ? [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            'Sin entrenadores registrados',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey),
                                          ),
                                        )
                                      ]
                                    : entrenadores
                                        .map((ent) => DropdownMenuItem(
                                              value: ent,
                                              child: Text(
                                                ent,
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ))
                                        .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => entrenadorVal = v);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CanchaSelector(
                        controller: lugarCtrl,
                        decorationBuilder: (icon, {hint}) =>
                            _inputDecoration(icon, hint: hint),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Horario (elige los días y las horas)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _diasSemana.map((d) {
                            return FilterChip(
                              label: Text(d),
                              selected: diasSel.contains(d),
                              selectedColor:
                                  orangePrimary.withValues(alpha: 0.2),
                              onSelected: (v) {
                                setDialogState(() {
                                  if (v) {
                                    diasSel.add(d);
                                  } else {
                                    diasSel.remove(d);
                                  }
                                  horarioError = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: horaIni ??
                                      const TimeOfDay(hour: 8, minute: 0),
                                );
                                if (t != null) {
                                  setDialogState(() {
                                    horaIni = t;
                                    horarioError = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(horaIni == null
                                  ? 'Hora de inicio'
                                  : 'Inicio: ${_fmtHora(horaIni!)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: horaFin ??
                                      const TimeOfDay(hour: 10, minute: 0),
                                );
                                if (t != null) {
                                  setDialogState(() {
                                    horaFin = t;
                                    horarioError = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time_filled,
                                  size: 18),
                              label: Text(horaFin == null
                                  ? 'Hora de fin'
                                  : 'Fin: ${_fmtHora(horaFin!)}'),
                            ),
                          ),
                        ],
                      ),
                      if (horarioPrevio.isNotEmpty &&
                          diasSel.isEmpty &&
                          horaIni == null &&
                          horaFin == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Horario actual: $horarioPrevio. Elige días y horas solo si quieres reemplazarlo.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ),
                        ),
                      if (horarioError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              horarioError!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        label: 'URL Imagen Promocional',
                        controller: imageCtrl,
                        hint: 'https://images.unsplash.com/...',
                        icon: Icons.image_outlined,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: orangePrimary,
                            side: const BorderSide(color: orangePrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.image_search, size: 18),
                          label: const Text('Buscar imagen'),
                          onPressed: () async {
                            final url = await showImageSearchDialog(ctx,
                                inicial: nombreCtrl.text.trim());
                            if (url != null) {
                              setDialogState(() => imageCtrl.text = url);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;

                    // El precio de cada disciplina debe ser de al menos 50 USD.
                    final double? precio = double.tryParse(
                        precioCtrl.text.trim().replaceAll(',', '.'));
                    if (precio == null || precio < kPrecioMinimo) {
                      setDialogState(() => precioError =
                          'El precio debe ser un número de al menos ${formatPrecio(kPrecioMinimo)} USD.');
                      return;
                    }
                    if (precioError != null) {
                      setDialogState(() => precioError = null);
                    }

                    // CUPO MÁXIMO: al menos 1 y nunca menor que los inscritos
                    // activos que ya tiene la disciplina.
                    final int cupoNuevo =
                        int.tryParse(cupoMaxCtrl.text.trim()) ?? 0;
                    if (cupoNuevo < 1) {
                      setDialogState(() =>
                          cupoError = 'El cupo máximo debe ser al menos 1.');
                      return;
                    }
                    if (isEditing) {
                      final activos = await _contarInscritosActivos(doc.id);
                      if (!ctx.mounted) return;
                      if (cupoNuevo < activos) {
                        setDialogState(() => cupoError =
                            'Hay $activos inscritos activos: el cupo no puede ser menor.');
                        return;
                      }
                    }
                    if (cupoError != null) {
                      setDialogState(() => cupoError = null);
                    }

                    // HORARIO: si es disciplina nueva (o el admin tocó días/horas)
                    // se exige día(s) + hora de inicio + hora de fin válidas.
                    // Si edita una disciplina antigua sin tocar el horario,
                    // se conserva el texto que ya tenía.
                    final bool tocoHorario = diasSel.isNotEmpty ||
                        horaIni != null ||
                        horaFin != null;
                    final bool horarioEstructurado =
                        tocoHorario || !isEditing || horarioPrevio.isEmpty;
                    String horarioTexto = horarioPrevio;
                    final diasOrdenados =
                        _diasSemana.where(diasSel.contains).toList();

                    if (horarioEstructurado) {
                      if (diasSel.isEmpty || horaIni == null || horaFin == null) {
                        setDialogState(() => horarioError =
                            'Elige al menos un día, la hora de inicio y la hora de fin.');
                        return;
                      }
                      if (_aMinutos(horaFin!) <= _aMinutos(horaIni!)) {
                        setDialogState(() => horarioError =
                            'La hora de fin debe ser posterior a la hora de inicio.');
                        return;
                      }
                      horarioTexto =
                          '${diasOrdenados.join(' / ')} · ${_fmtHora(horaIni!)} - ${_fmtHora(horaFin!)}';

                      // AVISO DE CHOQUE DE HORARIOS (mismo lugar o mismo entrenador)
                      final choques = await _buscarChoques(
                        excluirId: doc?.id,
                        lugar: lugarCtrl.text.trim(),
                        entrenador: entrenadorVal,
                        dias: diasSel,
                        inicio: horaIni!,
                        fin: horaFin!,
                      );
                      if (!ctx.mounted) return;
                      if (choques.isNotEmpty) {
                        final guardarIgual = await showDialog<bool>(
                          context: ctx,
                          builder: (c2) => AlertDialog(
                            title: const Text('Posible choque de horarios'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: choques
                                  .map((a) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text('• $a'),
                                      ))
                                  .toList(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c2, false),
                                child: const Text('Corregir horario'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c2, true),
                                child: const Text('Guardar de todos modos'),
                              ),
                            ],
                          ),
                        );
                        if (guardarIgual != true) return;
                      }
                    }

                    // BUSCAR EL UID DEL ENTRENADOR SELECCIONADO PARA EVITAR DESVINCULACIONES
                    String selectedEntrenadorUid = '';
                    if (entrenadorVal != null && entrenadorVal != 'Sin Entrenador') {
                      final userQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .get();
                      
                      for (var uDoc in userQuery.docs) {
                        final uData = uDoc.data();
                        final String fullName = (uData['nombreApellido'] ??
                                uData['nombreCompleto'] ??
                                uData['nombre'] ?? '')
                            .toString()
                            .trim();
                        final String emailName = (uData['correo'] ?? uData['email'] ?? '')
                            .toString()
                            .trim();

                        if (fullName == entrenadorVal || emailName == entrenadorVal) {
                          selectedEntrenadorUid = uDoc.id;
                          break;
                        }
                      }
                    }

                    final payload = {
                      'codigo': codigoCtrl.text.trim().toUpperCase(),
                      'nombre': nombreCtrl.text.trim(),
                      'cupoMaximo': int.tryParse(cupoMaxCtrl.text.trim()) ?? 20,
                      'cuposMaximos':
                          int.tryParse(cupoMaxCtrl.text.trim()) ?? 20,
                      'horario': horarioTexto,
                      if (horarioEstructurado) ...{
                        'horarioDias': diasOrdenados,
                        'horaInicio': _hhmm(horaIni!),
                        'horaFin': _hhmm(horaFin!),
                      },
                      'lugar': lugarCtrl.text.trim(),
                      'precio': precio,
                      'moneda': 'USD',
                      'entrenador': entrenadorVal ?? 'Sin Entrenador',
                      'entrenadorUid': selectedEntrenadorUid,
                      'categoria': categoriaVal,
                      'estado': estadoVal,
                      'imageUrl': imageCtrl.text.trim().isEmpty
                          ? 'https://images.unsplash.com/photo-1517649763962-0c623266200a?auto=format&fit=crop&w=800&q=80'
                          : imageCtrl.text.trim(),
                      'actualizadoEn': FieldValue.serverTimestamp(),
                    };

                    if (isEditing) {
                      await FirebaseFirestore.instance
                          .collection('deportes')
                          .doc(doc.id)
                          .update(payload);
                    } else {
                      payload['cuposInscritos'] = 0;
                      await FirebaseFirestore.instance
                          .collection('deportes')
                          .add(payload);
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(
                      isEditing ? 'Guardar Cambios' : 'Crear Oferta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Cuenta las inscripciones activas (no canceladas) de una disciplina,
  /// leyendo la colección `inscripciones` (más fiable que el contador guardado).
  Future<int> _contarInscritosActivos(String deporteId) async {
    final snap = await FirebaseFirestore.instance
        .collection('inscripciones')
        .where('deporteId', isEqualTo: deporteId)
        .get();
    return snap.docs
        .where((d) => (d.data()['estado'] ?? 'Confirmada') != 'Cancelada')
        .length;
  }

  Future<void> _deleteDiscipline(String docId, String nombre) async {
    // No se puede eliminar una disciplina que todavía tiene estudiantes
    // inscritos: sus inscripciones quedarían apuntando a algo que no existe.
    final activos = await _contarInscritosActivos(docId);
    if (!mounted) return;
    if (activos > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text(
              '"$nombre" tiene $activos inscripción(es) activa(s). '
              'Cancela las inscripciones desde "Fichas e Inscripciones" '
              'o cambia el estado de la disciplina a Inactivo.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Deseas eliminar la disciplina "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('deportes')
                  .doc(docId)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GESTIÓN DE DISCIPLINAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: orangePrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Catálogo Deportivo de la UNIMET',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: blueDark,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openDisciplineForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Registrar Nueva Disciplina',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 46,
            child: TextField(
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase().trim());
              },
              decoration: InputDecoration(
                hintText: 'Buscar por disciplina, código, entrenador o lugar...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 20, color: blueDark),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('deportes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(color: orangePrimary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                final codigo = (data['codigo'] ?? '').toString().toLowerCase();
                final entrenador =
                    (data['entrenador'] ?? '').toString().toLowerCase();
                final lugar = (data['lugar'] ?? '').toString().toLowerCase();

                return nombre.contains(_searchQuery) ||
                    codigo.contains(_searchQuery) ||
                    entrenador.contains(_searchQuery) ||
                    lugar.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.sports_soccer_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay disciplinas en la plataforma.',
                        style: TextStyle(
                            color: blueDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.82,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  return _buildDisciplineCard(filteredDocs[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String codigo = data['codigo'] ?? 'DE-000';
    final String nombre = data['nombre'] ?? 'Sin Nombre';
    final String categoria = data['categoria'] ?? 'De equipo';
    final int cupoMaximo =
        (data['cuposMaximos'] ?? data['cupoMaximo'] ?? 20) as int;
    final int cuposInscritos = (data['cuposInscritos'] ?? 0) as int;
    final int cuposDisponibles =
        (cupoMaximo - cuposInscritos).clamp(0, cupoMaximo);

    final String horario = data['horario'] ?? 'Por definir';
    final String lugar = data['lugar'] ?? 'Instalaciones UNIMET';
    final String entrenador = data['entrenador'] ?? 'Sin Entrenador';
    final String imageUrl = data['imageUrl'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _cardFallbackHeader(),
                      )
                    : _cardFallbackHeader(),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: blueDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: blueDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: orangePrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$cuposDisponibles / $cupoMaximo cupos',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: orangePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _iconDetailRow(Icons.access_time_rounded, horario),
                  const SizedBox(height: 6),
                  _iconDetailRow(Icons.location_on_outlined, lugar),
                  const SizedBox(height: 6),
                  _iconDetailRow(
                      Icons.person_outline_rounded, 'Entrenador: $entrenador'),
                  const SizedBox(height: 6),
                  _iconDetailRow(Icons.attach_money_rounded,
                      'Precio: ${formatPrecio(precioDeDisciplina(data))} USD'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFCBD5E1), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _openDisciplineForm(doc: doc),
                          icon: const Icon(Icons.edit_outlined,
                              size: 16, color: blueDark),
                          label: const Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: blueDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () => _deleteDiscipline(doc.id, nombre),
                        tooltip: 'Eliminar disciplina',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFallbackHeader() {
    return Container(
      height: 140,
      color: blueDark,
      child: const Center(
        child: Icon(Icons.sports, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _iconDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12, color: blueDark),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13, color: blueDark),
          decoration: _inputDecoration(icon, hint: hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      prefixIcon: Icon(icon, size: 18, color: blueDark),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    );
  }
}