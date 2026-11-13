import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_common.dart';
import 'ficha_estudiante.dart';

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
          // Tocar al estudiante abre su perfil y su ficha
          Expanded(
            child: InkWell(
              onTap: () => mostrarFichaDeEstudiante(
                context,
                uid: doc.id,
                nombre: userDisplayName(m),
              ),
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
          ),
          // Ficha deportiva personal del estudiante (solo lectura)
          OutlinedButton.icon(
            onPressed: () => mostrarFichaDeEstudiante(
              context,
              uid: doc.id,
              nombre: userDisplayName(m),
            ),
            icon: const Icon(Icons.assignment_ind_outlined, size: 18),
            label: const Text('Ver ficha'),
          ),
          const SizedBox(width: 8),
          // Historial de pagos del estudiante (inscripciones pagadas)
          OutlinedButton.icon(
            onPressed: () => _mostrarPagos(
              context,
              uid: doc.id,
              nombre: userDisplayName(m),
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Ver pagos'),
          ),
          // Envía al estudiante el enlace oficial para elegir una clave nueva
          IconButton(
            tooltip: 'Enviar enlace para restablecer contraseña',
            icon: const Icon(Icons.lock_reset, color: kNavy),
            onPressed: () => _restablecerClave(
              context,
              correo: '${m['correo'] ?? m['email'] ?? ''}',
              nombre: userDisplayName(m),
            ),
          ),
          const SizedBox(width: 4),
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
          IconButton(
            tooltip: 'Enviar enlace para restablecer contraseña',
            icon: const Icon(Icons.lock_reset, color: kNavy),
            onPressed: () => _restablecerClave(
              context,
              correo: '${m['correo'] ?? m['email'] ?? ''}',
              nombre: userDisplayName(m),
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

/// Muestra el historial de pagos de un estudiante, leyendo sus inscripciones
/// (colección `inscripciones`, campo `estudianteId`).
/// - "Total pagado" suma solo las inscripciones pagadas que siguen vigentes.
/// - Las canceladas con pago se muestran aparte como "pago sin reembolsar",
///   porque el reembolso por PayPal aún no es automático.
Future<void> _mostrarPagos(
  BuildContext context, {
  required String uid,
  required String nombre,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Pagos de $nombre'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('inscripciones')
              .where('estudianteId', isEqualTo: uid)
              .get(),
          builder: (context, snap) {
            if (snap.hasError) return Text('Error: ${snap.error}');
            if (!snap.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snap.data!.docs
                .map((d) => d.data() as Map<String, dynamic>)
                .toList()
              ..sort((a, b) {
                final ta = a['fechaInscripcion'];
                final tb = b['fechaInscripcion'];
                if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                return 0;
              });
            if (docs.isEmpty) {
              return const Text('Este estudiante aún no tiene inscripciones.');
            }

            double monto(Map<String, dynamic> m) {
              final v = m['montoPagado'] ?? m['precio'] ?? 0;
              return v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
            }

            String fecha(dynamic t) {
              if (t is! Timestamp) return '';
              final d = t.toDate();
              return '${d.day.toString().padLeft(2, '0')}/'
                  '${d.month.toString().padLeft(2, '0')}/${d.year}';
            }

            double totalVigente = 0;
            double totalSinReembolso = 0;
            for (final m in docs) {
              if (m['pagado'] != true) continue;
              if ((m['estado'] ?? 'Confirmada') == 'Cancelada') {
                totalSinReembolso += monto(m);
              } else {
                totalVigente += monto(m);
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total pagado (inscripciones vigentes): '
                    '\$${totalVigente.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  if (totalSinReembolso > 0)
                    Text(
                      'Pagos de inscripciones canceladas sin reembolsar: '
                      '\$${totalSinReembolso.toStringAsFixed(2)} USD',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  const Divider(height: 24),
                  for (final m in docs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _filaPago(m, monto(m), fecha(m['fechaInscripcion'])),
                    ),
                ],
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
  );
}

Widget _filaPago(Map<String, dynamic> m, double monto, String fecha) {
  final cancelada = (m['estado'] ?? 'Confirmada') == 'Cancelada';
  final pagado = m['pagado'] == true;
  final String detalle;
  final Color color;
  if (!pagado) {
    detalle = 'Sin pago registrado';
    color = Colors.black45;
  } else if (cancelada) {
    detalle = 'Pagado \$${monto.toStringAsFixed(2)} ${m['moneda'] ?? 'USD'}'
        '  ·  Cancelada · pago sin reembolsar';
    color = Colors.redAccent;
  } else {
    detalle = 'Pagado \$${monto.toStringAsFixed(2)} ${m['moneda'] ?? 'USD'}'
        '  ·  ${m['metodoPago'] ?? 'PayPal'}';
    color = Colors.green;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${m['nombreDeporte'] ?? 'Disciplina'}'
        '${fecha.isEmpty ? '' : '  ·  $fecha'}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(detalle,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      if (pagado && m['paypalOrderId'] != null)
        Text('Orden ${m['paypalOrderId']}',
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
    ],
  );
}

/// Envía a un usuario el correo oficial de Firebase para elegir una contraseña
/// nueva. El administrador nunca ve ni define la contraseña: solo dispara el
/// envío. Solo llega si el correo de la cuenta es un buzón real.
Future<void> _restablecerClave(
  BuildContext context, {
  required String correo,
  required String nombre,
}) async {
  final email = correo.trim();
  if (email.isEmpty || !email.contains('@')) {
    showMsg(context, '$nombre no tiene un correo registrado.', error: true);
    return;
  }
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restablecer contraseña'),
      content: Text(
        'Se enviará a $email un enlace para que $nombre elija una '
        'contraseña nueva. Solo le llegará si ese correo es real.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kOrange),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Enviar enlace'),
        ),
      ],
    ),
  );
  if (confirmar != true) return;
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (context.mounted) {
      showMsg(context, 'Enlace enviado a $email.');
    }
  } on FirebaseAuthException catch (e) {
    if (context.mounted) {
      showMsg(context, 'No se pudo enviar el enlace (${e.code}).', error: true);
    }
  } catch (e) {
    if (context.mounted) {
      showMsg(context, 'No se pudo enviar el enlace: $e', error: true);
    }
  }
}
