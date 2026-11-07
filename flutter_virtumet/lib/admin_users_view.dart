import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_common.dart';

/// Gestión de usuarios (requisito "Gestión de usuarios"):
///  - Estudiantes: activar / inactivar (campo `estado`, por defecto 'Activo').
///    Un estudiante Inactivo no pasa la validación de solvencia al inscribirse.
///  - Entrenadores: aprobar / rechazar (campo `estadoValidacion`,
///    que el registro deja en 'Pendiente').
class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _rol = 'Estudiante';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      children: [
        const SectionTitle(
          title: 'Gestión de Usuarios',
          subtitle: 'Cambia el estado de los estudiantes y valida a los entrenadores.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final r in ['Estudiante', 'Entrenador'])
              ChoiceChip(
                label: Text(r == 'Estudiante' ? 'Estudiantes' : 'Entrenadores'),
                selected: _rol == r,
                onSelected: (_) => setState(() => _rol = r),
              ),
            SizedBox(
              width: 280,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, correo o carnet',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('rol', isEqualTo: _rol)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Error: ${snap.error}');
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data!.docs.where((d) {
              if (_search.isEmpty) return true;
              final m = d.data() as Map<String, dynamic>;
              final hay =
                  '${userDisplayName(m)} ${m['correo'] ?? ''} ${m['carnet'] ?? ''}'
                      .toLowerCase();
              return hay.contains(_search);
            }).toList()
              ..sort((a, b) => userDisplayName(a.data() as Map<String, dynamic>)
                  .compareTo(userDisplayName(b.data() as Map<String, dynamic>)));

            if (docs.isEmpty) {
              return const AdminCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay usuarios que mostrar.'),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _rol == 'Estudiante'
                        ? _StudentRow(doc: d)
                        : _TrainerRow(doc: d),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _StudentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final m = doc.data() as Map<String, dynamic>;
    final bool activo = (m['estado'] ?? 'Activo') == 'Activo';
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: kNavy,
            child: Icon(Icons.school_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userDisplayName(m),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${m['correo'] ?? ''}  ·  Carnet ${m['carnet'] ?? '—'}  ·  ${m['carrera'] ?? ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(activo ? 'Activo' : 'Inactivo'),
          Switch(
            value: activo,
            activeThumbColor: kOrange,
            onChanged: (v) async {
              try {
                await doc.reference.update({'estado': v ? 'Activo' : 'Inactivo'});
                if (context.mounted) {
                  showMsg(context, '${userDisplayName(m)} ahora está ${v ? 'activo' : 'inactivo'}.');
                }
              } catch (e) {
                if (context.mounted) showMsg(context, 'Error: $e', error: true);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TrainerRow extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _TrainerRow({required this.doc});

  Future<void> _set(BuildContext context, String estado) async {
    try {
      await doc.reference.update({'estadoValidacion': estado});
      if (context.mounted) showMsg(context, 'Entrenador marcado como $estado.');
    } catch (e) {
      if (context.mounted) showMsg(context, 'Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = doc.data() as Map<String, dynamic>;
    final String estado = (m['estadoValidacion'] ?? 'Pendiente').toString();
    final Color color = estado == 'Aprobado'
        ? Colors.green
        : estado == 'Rechazado'
            ? Colors.redAccent
            : Colors.orange;
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: kOrange,
            child: Icon(Icons.sports, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userDisplayName(m),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${m['correo'] ?? ''}  ·  ${m['disciplinaExperiencia'] ?? ''}  ·  ${m['certificacion'] ?? ''}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(estado, style: TextStyle(color: color)),
            side: BorderSide(color: color),
            backgroundColor: Colors.white,
          ),
          if (estado != 'Aprobado')
            IconButton(
              tooltip: 'Aprobar',
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _set(context, 'Aprobado'),
            ),
          if (estado != 'Rechazado')
            IconButton(
              tooltip: 'Rechazar',
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: () => _set(context, 'Rechazado'),
            ),
        ],
      ),
    );
  }
}
