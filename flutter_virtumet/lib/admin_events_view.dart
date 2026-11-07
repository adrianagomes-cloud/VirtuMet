import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEventsView extends StatefulWidget {
  const AdminEventsView({super.key});

  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF8F9FA);

  @override
  State<AdminEventsView> createState() => _AdminEventsViewState();
}

class _AdminEventsViewState extends State<AdminEventsView> {
  DateTime _selectedDate = DateTime.now();

  String _formatDateKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ===========================================================================
  // MODAL PARA CREAR UN NUEVO EVENTO
  // ===========================================================================
  void _showCreateEventDialog(BuildContext context, {DateTime? initialDate}) {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final lugarCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();

    DateTime eventDate = initialDate ?? _selectedDate;
    String? selectedSport;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String fechaTexto =
                '${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year}';

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.event_available, color: AdminEventsView.blueDark),
                  SizedBox(width: 10),
                  Text(
                    'Programar Nuevo Evento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AdminEventsView.blueDark,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Deporte / Disciplina *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AdminEventsView.blueDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('deportes')
                              .snapshots(),
                          builder: (context, snapshot) {
                            List<String> deportesList = [];
                            if (snapshot.hasData && snapshot.data != null) {
                              deportesList = snapshot.data!.docs
                                  .map((doc) => (doc.data()
                                              as Map<String, dynamic>)['nombre']
                                          ?.toString() ??
                                      doc.id)
                                  .where((name) => name.isNotEmpty)
                                  .toList();
                            }

                            if (deportesList.isEmpty) {
                              deportesList = [
                                'Fútbol Sala',
                                'Baloncesto',
                                'Voleibol',
                                'Tenis de Campo',
                                'Atletismo',
                                'General / Inter-facultades'
                              ];
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedSport,
                              decoration: InputDecoration(
                                hintText: 'Selecciona una disciplina',
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              items: deportesList.map((deporte) {
                                return DropdownMenuItem(
                                  value: deporte,
                                  child: Text(deporte,
                                      style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() => selectedSport = val);
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Selecciona un deporte'
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Nombre / Título del Evento *',
                          hint: 'Ej: Torneo Interescuelas C-2026',
                          controller: tituloCtrl,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa el título'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'URL de la Imagen (Opcional)',
                          hint: 'Ej: https://images.unsplash.com/photo-1574629810360-7efbbe195018',
                          controller: imageUrlCtrl,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha del Evento *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AdminEventsView.blueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: eventDate,
                                        firstDate: DateTime(2024),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => eventDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(fechaTexto,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 18,
                                              color: AdminEventsView.blueDark),
                                        ],
                                      ),
                                    ),
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
                                    'Hora del Evento *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AdminEventsView.blueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: horaCtrl,
                                    readOnly: true,
                                    onTap: () async {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            const TimeOfDay(hour: 10, minute: 0),
                                      );
                                      if (pickedTime != null) {
                                        horaCtrl.text =
                                            pickedTime.format(context);
                                      }
                                    },
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: '10:00 AM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      suffixIcon: const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: AdminEventsView.blueDark),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Indica la hora'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Lugar / Ubicación *',
                          hint: 'Ej: Cancha Principal - Campus UNIMET',
                          controller: lugarCtrl,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa el lugar'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Descripción / ¿De qué se trata? *',
                          hint: 'Detalla las reglas, categorías o propósito del evento...',
                          controller: descripcionCtrl,
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa la descripción'
                              : null,
                        ),
                      ],
                    ),
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
                    backgroundColor: AdminEventsView.orangePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final String fechaKey = _formatDateKey(eventDate);

                    await FirebaseFirestore.instance.collection('eventos').add({
                      'titulo': tituloCtrl.text.trim(),
                      'deporte': selectedSport,
                      'descripcion': descripcionCtrl.text.trim(),
                      'lugar': lugarCtrl.text.trim(),
                      'hora': horaCtrl.text.trim(),
                      'imageUrl': imageUrlCtrl.text.trim(),
                      'fechaKey': fechaKey,
                      'fechaTimestamp': Timestamp.fromDate(eventDate),
                      'creadoEn': FieldValue.serverTimestamp(),
                    });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Evento registrado exitosamente!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Guardar Evento',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL PARA EDITAR / MODIFICAR UN EVENTO EXISTENTE
  // ===========================================================================
  void _showEditEventDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final formKey = GlobalKey<FormState>();

    final tituloCtrl = TextEditingController(text: data['titulo'] ?? '');
    final descripcionCtrl = TextEditingController(text: data['descripcion'] ?? '');
    final lugarCtrl = TextEditingController(text: data['lugar'] ?? '');
    final horaCtrl = TextEditingController(text: data['hora'] ?? '');
    final imageUrlCtrl = TextEditingController(
        text: data['imageUrl'] ?? data['imagen'] ?? data['fotoUrl'] ?? '');

    DateTime eventDate = _selectedDate;
    if (data['fechaTimestamp'] != null && data['fechaTimestamp'] is Timestamp) {
      eventDate = (data['fechaTimestamp'] as Timestamp).toDate();
    } else if (data['fechaKey'] != null) {
      try {
        final parts = (data['fechaKey'] as String).split('-');
        if (parts.length == 3) {
          eventDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }

    String? selectedSport = data['deporte']?.toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final String fechaTexto =
                '${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year}';

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_calendar, color: AdminEventsView.blueDark),
                  SizedBox(width: 10),
                  Text(
                    'Modificar Evento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AdminEventsView.blueDark,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Deporte / Disciplina *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AdminEventsView.blueDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('deportes')
                              .snapshots(),
                          builder: (context, snapshot) {
                            List<String> deportesList = [];
                            if (snapshot.hasData && snapshot.data != null) {
                              deportesList = snapshot.data!.docs
                                  .map((doc) => (doc.data()
                                              as Map<String, dynamic>)['nombre']
                                          ?.toString() ??
                                      doc.id)
                                  .where((name) => name.isNotEmpty)
                                  .toList();
                            }

                            if (deportesList.isEmpty) {
                              deportesList = [
                                'Fútbol Sala',
                                'Baloncesto',
                                'Voleibol',
                                'Tenis de Campo',
                                'Atletismo',
                                'General / Inter-facultades'
                              ];
                            }

                            if (selectedSport != null &&
                                !deportesList.contains(selectedSport)) {
                              deportesList.add(selectedSport!);
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedSport,
                              decoration: InputDecoration(
                                hintText: 'Selecciona una disciplina',
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              items: deportesList.map((deporte) {
                                return DropdownMenuItem(
                                  value: deporte,
                                  child: Text(deporte,
                                      style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() => selectedSport = val);
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Selecciona un deporte'
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Nombre / Título del Evento *',
                          hint: 'Ej: Torneo Interescuelas C-2026',
                          controller: tituloCtrl,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa el título'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'URL de la Imagen (Directa de la foto)',
                          hint: 'Ej: https://images.unsplash.com/photo-1574629810360-7efbbe195018',
                          controller: imageUrlCtrl,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha del Evento *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AdminEventsView.blueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: eventDate,
                                        firstDate: DateTime(2024),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setModalState(() => eventDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(fechaTexto,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          const Icon(
                                              Icons.calendar_month_outlined,
                                              size: 18,
                                              color: AdminEventsView.blueDark),
                                        ],
                                      ),
                                    ),
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
                                    'Hora del Evento *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AdminEventsView.blueDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: horaCtrl,
                                    readOnly: true,
                                    onTap: () async {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            const TimeOfDay(hour: 10, minute: 0),
                                      );
                                      if (pickedTime != null) {
                                        horaCtrl.text =
                                            pickedTime.format(context);
                                      }
                                    },
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: '10:00 AM',
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      suffixIcon: const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: AdminEventsView.blueDark),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFCBD5E1)),
                                      ),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Indica la hora'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Lugar / Ubicación *',
                          hint: 'Ej: Cancha Principal - Campus UNIMET',
                          controller: lugarCtrl,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa el lugar'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Descripción / ¿De qué se trata? *',
                          hint: 'Detalla las reglas, categorías o propósito del evento...',
                          controller: descripcionCtrl,
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingresa la descripción'
                              : null,
                        ),
                      ],
                    ),
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
                    backgroundColor: AdminEventsView.blueDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final String fechaKey = _formatDateKey(eventDate);

                    await FirebaseFirestore.instance
                        .collection('eventos')
                        .doc(docId)
                        .update({
                      'titulo': tituloCtrl.text.trim(),
                      'deporte': selectedSport,
                      'descripcion': descripcionCtrl.text.trim(),
                      'lugar': lugarCtrl.text.trim(),
                      'hora': horaCtrl.text.trim(),
                      'imageUrl': imageUrlCtrl.text.trim(),
                      'fechaKey': fechaKey,
                      'fechaTimestamp': Timestamp.fromDate(eventDate),
                    });

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Evento actualizado correctamente!'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar Cambios',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEvent(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('eventos').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento eliminado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fechaSeleccionadaKey = _formatDateKey(_selectedDate);

    return Container(
      width: double.infinity,
      color: AdminEventsView.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Eventos y Calendario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminEventsView.blueDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Selecciona un día en el calendario para agendar o revisar competencias y actividades.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminEventsView.orangePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showCreateEventDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Crear Nuevo Evento',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 360,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFCBD5E1), width: 1.2),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: AdminEventsView.blueDark),
                        SizedBox(width: 8),
                        Text(
                          'Calendario Deportivo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AdminEventsView.blueDark,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    CalendarDatePicker(
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      onDateChanged: (newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AdminEventsView.blueDark),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showCreateEventDialog(context,
                            initialDate: _selectedDate),
                        icon: const Icon(Icons.event_note,
                            color: AdminEventsView.blueDark, size: 18),
                        label: Text(
                          'Agendar para el ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            color: AdminEventsView.blueDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event,
                                  color: AdminEventsView.orangePrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Eventos del ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AdminEventsView.blueDark,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('eventos')
                                .where('fechaKey',
                                    isEqualTo: fechaSeleccionadaKey)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No hay eventos programados para este día.',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildEventCard(
                                      doc.id, data, context);
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.list_alt,
                                  color: AdminEventsView.blueDark),
                              SizedBox(width: 8),
                              Text(
                                'Todos los Eventos Registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AdminEventsView.blueDark,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('eventos')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'Aún no se han registrado eventos globales en el sistema.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildEventCard(
                                      doc.id, data, context);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET TARJETA DE EVENTO CON BOTONES DE EDICIÓN Y ELIMINACIÓN
  Widget _buildEventCard(
      String docId, Map<String, dynamic> data, BuildContext context) {
    final String titulo = (data['titulo'] ?? 'Evento').toString();
    final String deporte = (data['deporte'] ?? 'General').toString();
    final String lugar = (data['lugar'] ?? 'Por definir').toString();
    final String hora = (data['hora'] ?? '').toString();
    final String descripcion = (data['descripcion'] ?? '').toString();
    final String fechaKey = (data['fechaKey'] ?? '').toString();

    final String imageUrl = (data['imageUrl'] ??
            data['imagen'] ??
            data['fotoUrl'] ??
            '')
        .toString()
        .trim();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackIcon(deporte),
                  )
                : _buildFallbackIcon(deporte),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AdminEventsView.blueDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AdminEventsView.blueDark, size: 20),
                          tooltip: 'Modificar evento',
                          onPressed: () =>
                              _showEditEventDialog(context, docId, data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          tooltip: 'Eliminar evento',
                          onPressed: () => _deleteEvent(docId),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 14, color: AdminEventsView.orangePrimary),
                    const SizedBox(width: 4),
                    Text(
                      '$fechaKey ${hora.isNotEmpty ? '• $hora' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AdminEventsView.orangePrimary),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lugar,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(String deporte) {
    return Container(
      width: 80,
      height: 80,
      color: AdminEventsView.blueDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            deporte,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AdminEventsView.blueDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}