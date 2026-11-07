import 'package:flutter/material.dart';

// Paleta compartida con el resto de VirtuMet
const Color kNavy = Color(0xFF0F2C59);
const Color kOrange = Color(0xFFFF5500);
const Color kBg = Color(0xFFF3F5F8);

void showMsg(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : kNavy,
    ),
  );
}

/// Tarjeta blanca con sombra suave, usada en todas las vistas del admin.
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kNavy,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Convierte un TimeOfDay a "HH:mm" (sin depender del locale).
String fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Interpreta "HH:mm" -> TimeOfDay (null si no es válido).
TimeOfDay? parseTime(String s) {
  final parts = s.trim().split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

/// Nombre visible de un documento de `users`, según el rol.
String userDisplayName(Map<String, dynamic> u) {
  if (u['rol'] == 'Estudiante') {
    final n = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
    return n.isEmpty ? (u['correo'] ?? 'Sin nombre').toString() : n;
  }
  final n = (u['nombreApellido'] ?? '').toString().trim();
  return n.isEmpty ? (u['correo'] ?? 'Sin nombre').toString() : n;
}

/// Contenedor estándar de una pestaña del panel admin (mismo padding que el resumen).
class AdminPage extends StatelessWidget {
  final List<Widget> children;
  const AdminPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Pestañas de prioridad baja que aún no se implementan.
class AdminComingSoon extends StatelessWidget {
  final String title;
  const AdminComingSoon({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      children: [
        SectionTitle(title: title, subtitle: 'Módulo de prioridad baja, próximamente.'),
        const SizedBox(height: 16),
        const AdminCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text('Esta sección se completará en una iteración posterior.'),
            ),
          ),
        ),
      ],
    );
  }
}
