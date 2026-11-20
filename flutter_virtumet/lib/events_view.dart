import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'responsive.dart';

const List<String> _mesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const List<String> _mesesLargos = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Fecha de un evento. Usa `fechaTimestamp` y, si falta, `fechaKey` (yyyy-MM-dd).
DateTime? fechaEvento(Map<String, dynamic> data) {
  final ts = data['fechaTimestamp'];
  if (ts is Timestamp) return ts.toDate();
  final key = data['fechaKey'];
  if (key is String) return DateTime.tryParse(key);
  return null;
}

/// Eventos de hoy en adelante, del más cercano al más lejano.
List<Map<String, dynamic>> eventosProximos(
    Iterable<Map<String, dynamic>> eventos) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final lista = eventos.where((e) {
    final f = fechaEvento(e);
    return f != null && !f.isBefore(hoy);
  }).toList();
  lista.sort((a, b) => fechaEvento(a)!.compareTo(fechaEvento(b)!));
  return lista;
}

/// Texto corto de fecha y hora, por ejemplo "26 de noviembre de 2026 · 3:00 PM".
String textoFechaEvento(Map<String, dynamic> data) {
  final f = fechaEvento(data);
  if (f == null) return '';
  final texto = '${f.day} de ${_mesesLargos[f.month - 1]} de ${f.year}';
  final hora = (data['hora'] ?? '').toString().trim();
  return hora.isEmpty ? texto : '$texto · $hora';
}

/// Pestaña "Eventos" de solo lectura para estudiantes y entrenadores.
/// Muestra los eventos que publica el administrador (colección `eventos`):
/// primero los próximos y debajo los más recientes que ya pasaron.
class EventsView extends StatelessWidget {
  const EventsView({super.key});

  static const navy = Color(0xFF0F2C59);
  static const orange = Color(0xFFFF5500);
  static const grey = Color(0xFF6C757D);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: margenPagina(context), vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENTOS',
              style: TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Calendario institucional',
              style: TextStyle(
                  color: navy, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('eventos').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error al cargar eventos: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final todos = snapshot.data!.docs.map((d) => d.data()).toList();
              final proximos = eventosProximos(todos);
              final pasados =
                  todos.where((e) => !proximos.contains(e)).toList();
              pasados.sort((a, b) {
                final fa = fechaEvento(a);
                final fb = fechaEvento(b);
                if (fa == null && fb == null) return 0;
                if (fa == null) return 1;
                if (fb == null) return -1;
                return fb.compareTo(fa);
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proximos.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: const Text(
                        'No hay eventos próximos por ahora. Cuando la '
                        'administración publique uno, aparecerá aquí.',
                        style: TextStyle(color: grey, fontSize: 14),
                      ),
                    )
                  else
                    ...proximos.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _EventoCard(data: e),
                        )),
                  if (pasados.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Eventos anteriores',
                        style: TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...pasados.take(10).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _EventoCard(data: e, pasado: true),
                        )),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool pasado;

  const _EventoCard({required this.data, this.pasado = false});

  Widget _chip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 12, color: EventsView.navy)),
          ),
        ],
      ),
    );
  }

  Widget _insignia(DateTime? fecha, Color acento) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: acento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: fecha == null
          ? Icon(Icons.event_outlined, color: acento)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fecha.day.toString(),
                    style: TextStyle(
                        color: acento,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(_mesesCortos[fecha.month - 1].toUpperCase(),
                    style: TextStyle(
                        color: acento,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = (data['titulo'] ?? '').toString();
    final deporte = (data['deporte'] ?? '').toString();
    final lugar = (data['lugar'] ?? '').toString().trim();
    final hora = (data['hora'] ?? '').toString().trim();
    final descripcion = (data['descripcion'] ?? '').toString().trim();
    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
    final fecha = fechaEvento(data);
    final movil = esMovil(context);
    final Color acento = pasado ? EventsView.grey : EventsView.orange;

    final Widget contenido = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _insignia(fecha, acento),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: EventsView.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (deporte.isNotEmpty)
                      _chip(Icons.sports_soccer_outlined, deporte, acento),
                    if (hora.isNotEmpty)
                      _chip(Icons.schedule, hora, EventsView.grey),
                    if (lugar.isNotEmpty)
                      _chip(Icons.place_outlined, lugar, EventsView.grey),
                  ],
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(descripcion,
                      style: const TextStyle(
                          color: EventsView.grey, fontSize: 13, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final Widget? imagen = imageUrl.isEmpty
        ? null
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          );

    final Widget cuerpo;
    if (movil) {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagen != null) SizedBox(height: 170, child: imagen),
          contenido,
        ],
      );
    } else {
      cuerpo = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagen != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 0, 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 220, height: 150, child: imagen),
              ),
            ),
          Expanded(child: contenido),
        ],
      );
    }

    return Opacity(
      opacity: pasado ? 0.65 : 1,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: cuerpo,
      ),
    );
  }
}
