import 'package:flutter/material.dart';

/// Sección interactiva de Preguntas Frecuentes de la página de inicio.
///
/// - Las preguntas se agrupan por categoría (chips) y se pueden buscar por texto.
/// - Cada pregunta es un acordeón: al tocarla se despliega la respuesta y se
///   cierra la que estaba abierta.
/// - Por defecto se ve solo una franja discreta ("¿Tienes dudas?"); la sección
///   completa se despliega cuando el visitante lo pide (botón, enlace "Preguntas"
///   del menú o "Preguntas Frecuentes" del pie de página).
/// - El contenido está en la lista [kFaqs]; para agregar o cambiar una pregunta
///   solo hay que editar esa lista.
class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => FaqSectionState();
}

class FaqItem {
  final String categoria;
  final String pregunta;
  final String respuesta;
  const FaqItem(this.categoria, this.pregunta, this.respuesta);
}

const List<FaqItem> kFaqs = [
  // ---------------------------------------------------------------- Inscripción
  FaqItem(
    'Inscripción',
    '¿Cómo me inscribo en una disciplina?',
    '1) Regístrate o ingresa con tu cuenta de estudiante. '
        '2) Entra al Catálogo Deportivo y elige la disciplina. '
        '3) Presiona "Inscribirme", completa tu ficha deportiva si todavía no la tienes '
        'y realiza el pago. Al confirmarse el pago, tu inscripción aparece en "Mis Actividades".',
  ),
  FaqItem(
    'Inscripción',
    '¿Puedo ver la disciplina antes de inscribirme?',
    'Sí. El catálogo es público: muestra horario, lugar, entrenador, precio y cupos disponibles. '
        'Ya dentro de tu cuenta también puedes presionar "Reseñas" para leer las opiniones de otros '
        'estudiantes antes de decidir.',
  ),
  FaqItem(
    'Inscripción',
    '¿Qué pasa si no quedan cupos?',
    'Cada disciplina tiene un número máximo de cupos. Cuando se llenan, el botón de inscripción '
        'se desactiva. Si alguien cancela, el cupo se libera y vuelve a estar disponible.',
  ),
  FaqItem(
    'Inscripción',
    '¿Puedo inscribirme en más de una disciplina?',
    'Sí, puedes inscribirte en varias. Procura que los horarios no coincidan entre sí. '
        'Lo que no se permite es inscribirte dos veces en la misma disciplina.',
  ),
  FaqItem(
    'Inscripción',
    '¿Qué es la ficha deportiva?',
    'Es un formulario con tus datos de salud y de contacto de emergencia (tipo de sangre, alergias, '
        'condiciones médicas, etc.). Se llena una sola vez, antes de tu primera inscripción, y se '
        'reutiliza en las siguientes. La administración puede consultarla para tu seguridad durante la actividad.',
  ),
  FaqItem(
    'Inscripción',
    '¿Dónde veo los horarios, el lugar y el entrenador de cada disciplina?',
    'En la tarjeta de cada disciplina del catálogo: días y hora de la clase, '
        'cancha o lugar, entrenador asignado y cupos disponibles.',
  ),
  // ---------------------------------------------------------------------- Pagos
  FaqItem(
    'Pagos',
    '¿Cuánto cuesta una disciplina?',
    'El precio (en USD) aparece en la tarjeta de cada disciplina del catálogo. '
        'Se paga una vez, al inscribirte, con PayPal.',
  ),
  FaqItem(
    'Pagos',
    '¿Cómo se paga la inscripción?',
    'El pago se hace en línea con PayPal durante el proceso de inscripción. El precio de cada '
        'disciplina aparece en su tarjeta del catálogo.',
  ),
  FaqItem(
    'Pagos',
    '¿Dónde veo que mi pago fue registrado?',
    'En "Mis Actividades" aparece tu inscripción con su estado. La administración también '
        'conserva el registro del pago (monto y número de orden de PayPal).',
  ),
  FaqItem(
    'Pagos',
    '¿Qué hago si me cancelaron la inscripción y ya pagué?',
    'La cancelación libera tu cupo, pero el reembolso no es automático: se gestiona con la '
        'administración de deportes. Ten a la mano tu número de orden de PayPal.',
  ),
  // --------------------------------------------------------------------- Cuenta
  FaqItem(
    'Cuenta',
    '¿Olvidé mi contraseña? ¿Cómo la recupero?',
    'En la pantalla de Ingresar presiona "¿Olvidaste tu contraseña?", escribe el correo '
        'de tu cuenta y te llegará un enlace para elegir una contraseña nueva. Revisa también '
        'la carpeta de spam. Si el correo de tu cuenta no es real o ya no tienes acceso a él, '
        'escribe a la administración de deportes desde Soporte.',
  ),
  FaqItem(
    'Cuenta',
    '¿Quién puede registrarse en VirtuMet?',
    'La plataforma es de acceso institucional para estudiantes y personal de la UNIMET. '
        'Al registrarte debes indicar tus datos académicos, como carnet y carrera.',
  ),
  FaqItem(
    'Cuenta',
    '¿Por qué no puedo inscribirme si mi cuenta aparece inactiva?',
    'La administración puede dejar una cuenta como "Inactiva" (por ejemplo, si no está solvente). '
        'Mientras esté inactiva no es posible inscribirse. Comunícate con la administración '
        'de deportes para reactivarla.',
  ),
  FaqItem(
    'Cuenta',
    'Me registré como entrenador, ¿por qué no puedo entrar todavía?',
    'Las cuentas de entrenador deben ser validadas por la administración. '
        'Quedan en estado "Pendiente" hasta que se revisen tu disciplina y tu certificación.',
  ),
  FaqItem(
    'Cuenta',
    '¿Puedo cambiar mi foto de perfil?',
    'Sí. En tu perfil presiona "Cambiar foto" y sube una imagen desde tu computadora, '
        'o usa un enlace o el buscador de imágenes.',
  ),
  // ------------------------------------------------------------------ Actividad
  FaqItem(
    'Actividades',
    '¿Cómo me entero de cambios o cancelaciones de clases?',
    'En el apartado "Avisos" de tu panel. Allí la administración publica avisos normales, '
        'importantes y urgentes; los importantes y urgentes además aparecen destacados en la '
        'tarjeta "Avisos" de tu página de inicio.',
  ),
  FaqItem(
    'Actividades',
    '¿Puedo dejar una reseña de la disciplina o del entrenador?',
    'Sí. Puedes calificar la disciplina y al entrenador con estrellas y un '
        'comentario opcional. Las reseñas ayudan a otros estudiantes a elegir.',
  ),
  FaqItem(
    'Actividades',
    '¿Qué es el muro de Comunidad?',
    'Es un espacio dentro de la plataforma para que estudiantes, entrenadores y la administración '
        'compartan publicaciones y novedades del deporte universitario.',
  ),
];

class FaqSectionState extends State<FaqSection> {
  static const Color _naranja = Color(0xFFFF5500);
  static const Color _azul = Color(0xFF0F2C59);

  String _categoria = 'Todas';
  String _busqueda = '';
  int? _abierta; // índice (dentro de la lista filtrada) de la pregunta desplegada
  bool _expandida = false; // false = franja discreta, true = sección completa

  /// Despliega la sección completa (la llama la página de inicio).
  void abrir() {
    if (!_expandida) setState(() => _expandida = true);
  }

  void _cerrar() => setState(() {
        _expandida = false;
        _abierta = null;
        _busqueda = '';
        _categoria = 'Todas';
      });

  Widget _franja(bool angosto) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: angosto ? 16 : 60),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Icon(Icons.help_outline, size: 18, color: Colors.black45),
            const Text('¿Tienes dudas antes de inscribirte?',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            TextButton(
              onPressed: abrir,
              child: const Text(
                'Ver preguntas frecuentes',
                style: TextStyle(color: _naranja, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _categorias =>
      ['Todas', ...{for (final f in kFaqs) f.categoria}];

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.trim().toLowerCase();
    final visibles = kFaqs.where((f) {
      if (_categoria != 'Todas' && f.categoria != _categoria) return false;
      if (q.isEmpty) return true;
      return '${f.pregunta} ${f.respuesta}'.toLowerCase().contains(q);
    }).toList();

    final bool angosto = MediaQuery.of(context).size.width < 700;

    if (!_expandida) return _franja(angosto);

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: EdgeInsets.symmetric(
        vertical: 60,
        horizontal: angosto ? 16 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'PREGUNTAS FRECUENTES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: _naranja,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '¿Tienes dudas antes de inscribirte?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _azul,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Esto es lo que más nos preguntan estudiantes y entrenadores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Busca tu pregunta (por ejemplo: pago, cupos, ficha)',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _busqueda = v;
                  _abierta = null;
                }),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _categorias)
                    ChoiceChip(
                      label: Text(c),
                      selected: _categoria == c,
                      selectedColor: _naranja.withValues(alpha: 0.18),
                      onSelected: (_) => setState(() {
                        _categoria = c;
                        _abierta = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (visibles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No encontramos preguntas con esa búsqueda. '
                    'Prueba con otra palabra o escribe a la administración de deportes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                for (int i = 0; i < visibles.length; i++)
                  _item(i, visibles[i]),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _cerrar,
                  icon: const Icon(Icons.keyboard_arrow_up, color: Colors.black45),
                  label: const Text('Ocultar preguntas',
                      style: TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, FaqItem f) {
    final bool abierta = _abierta == i;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: abierta ? _naranja : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _abierta = abierta ? null : i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        f.pregunta,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: _azul,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: abierta ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: abierta ? _naranja : Colors.black45),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: abierta
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            f.respuesta,
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
