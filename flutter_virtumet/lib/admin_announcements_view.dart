import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnnouncementsView extends StatefulWidget {
  const AdminAnnouncementsView({super.key});

  @override
  State<AdminAnnouncementsView> createState() => _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<AdminAnnouncementsView> {
  static const navy = Color(0xFF0F2C59);
  static const orange = Color(0xFFFF5500);

  Future<void> _openForm({DocumentSnapshot? document}) async {
    final data = document?.data() as Map<String, dynamic>?;
    final titleController =
        TextEditingController(text: (data?['titulo'] ?? '').toString());
    final messageController =
        TextEditingController(text: (data?['mensaje'] ?? '').toString());
    var priority = (data?['prioridad'] ?? 'Normal').toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(document == null ? 'Nuevo aviso' : 'Editar aviso'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mensaje'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: const [
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Importante', child: Text('Importante')),
                    DropdownMenuItem(value: 'Urgente', child: Text('Urgente')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => priority = value ?? priority),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final message = messageController.text.trim();
                if (title.isEmpty || message.isEmpty) return;

                final payload = {
                  'titulo': title,
                  'mensaje': message,
                  'prioridad': priority,
                  'estado': 'Activo',
                  'actualizadoEn': FieldValue.serverTimestamp(),
                };
                if (document == null) {
                  payload['creadoEn'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance
                      .collection('avisos')
                      .add(payload);
                } else {
                  await document.reference.update(payload);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _delete(DocumentSnapshot document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar aviso'),
        content: const Text('El aviso dejará de mostrarse a los estudiantes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await document.reference.delete();
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
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo aviso'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('avisos')
                .orderBy('creadoEn', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error al cargar avisos: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('Todavía no hay avisos publicados.'),
                  ),
                );
              }
              return Column(
                children: docs.map((document) {
                  final data = document.data() as Map<String, dynamic>;
                  final title = (data['titulo'] ?? 'Aviso').toString();
                  final message = (data['mensaje'] ?? '').toString();
                  final priority = (data['prioridad'] ?? 'Normal').toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        priority == 'Urgente'
                            ? Icons.warning_rounded
                            : Icons.campaign_outlined,
                        color: priority == 'Urgente' ? Colors.red : orange,
                      ),
                      title: Text(title,
                          style: const TextStyle(
                              color: navy, fontWeight: FontWeight.bold)),
                      subtitle: Text('$priority · $message'),
                      isThreeLine: true,
                      trailing: Wrap(
                        children: [
                          IconButton(
                              onPressed: () => _openForm(document: document),
                              icon: const Icon(Icons.edit_outlined,
                                  color: navy)),
                          IconButton(
                              onPressed: () => _delete(document),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red)),
                        ],
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
