import 'package:flutter/material.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  static const _navy = Color(0xFF102F61);
  static const _orange = Color(0xFFFF5500);
  static const _background = Color(0xFFF5F7FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior limpia (Uso de Logo.png)
            const _RegistrationNavbar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _navy,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            '✦  CONFIGURACIÓN DE PERFIL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text.rich(
                          TextSpan(
                            text: '¿QUIÉN ',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                            children: [
                              TextSpan(
                                text: 'ERES',
                                style: TextStyle(color: _orange),
                              ),
                              TextSpan(text: ' EN VIRTUMET?'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(
                          width: 560,
                          child: Text(
                            'Selecciona tu rol institucional para personalizar tu experiencia. Te ayudaremos a encontrar las mejores oportunidades deportivas según tu perfil.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF5D687A),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.chevron_left, size: 15),
                          label: const Text('Volver al inicio de sesión'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF5D687A),
                            textStyle: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 680;
                            final cards = [
                              _RoleCard(
                                title: 'Soy Estudiante',
                                badge: 'ATLETA UNIVERSITARIO',
                                description:
                                    'Descubre disciplinas, únete a equipos y alcanza tus metas deportivas mientras avanzas en tu carrera académica.',
                                benefits: const [
                                  'Inscripción a 15+ disciplinas',
                                  'Obtención de créditos deportivos',
                                  'Seguimiento de rendimiento personal',
                                ],
                                icon: Icons.school_outlined,
                                imageUrl:
                                    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=900&q=80',
                                buttonLabel: 'CONTINUAR COMO ESTUDIANTE',
                                onPressed: () => _openForm(context, 'Estudiante'),
                              ),
                              _RoleCard(
                                title: 'Soy Entrenador / Docente',
                                badge: 'STAFF TÉCNICO',
                                description:
                                    'Gestiona tus grupos, supervisa el progreso de tus atletas y lidera el espíritu deportivo de la universidad.',
                                benefits: const [
                                  'Gestión de plantillas y asistencia',
                                  'Planificación de entrenamientos',
                                  'Reportes de desempeño institucional',
                                ],
                                icon: Icons.shield_outlined,
                                imageUrl:
                                    'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=900&q=80',
                                buttonLabel: 'CONTINUAR COMO ENTRENADOR',
                                onPressed: () => _openForm(context, 'Entrenador'),
                              ),
                            ];
                            if (stacked) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  cards[0],
                                  const SizedBox(height: 16),
                                  cards[1],
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 84),
                        const _RegistrationFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openForm(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleRegistrationForm(role: role),
      ),
    );
  }
}

// =============================================================================
// NAVBAR SUPERIOR (SELECCIÓN DE ROLES)
// =============================================================================
class _RegistrationNavbar extends StatelessWidget {
  const _RegistrationNavbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2EC))),
      ),
      child: Row(
        children: [
          Image.asset(
            'lib/assets/Logo.png',
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: RegistrationPage._navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VirtuMet',
                  style: TextStyle(
                    color: RegistrationPage._navy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String badge;
  final String description;
  final List<String> benefits;
  final IconData icon;
  final String imageUrl;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.title,
    required this.badge,
    required this.description,
    required this.benefits,
    required this.icon,
    required this.imageUrl,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE1E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFB9C3D2),
                    child: const Icon(Icons.sports, color: Colors.white, size: 54),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: .65)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RegistrationPage._orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: RegistrationPage._navy, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: RegistrationPage._navy,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF5D687A),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...benefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: RegistrationPage._orange,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Color(0xFF4E5A6D),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RegistrationPage._navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationFooter extends StatelessWidget {
  const _RegistrationFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Color(0xFFD7DEE9)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '●  UNIMET Athletic Division',
              style: TextStyle(color: Color(0xFF667995), fontSize: 10),
            ),
            Text(
              '◉ IDENTIDAD VALIDADA    ⚒ +1,200 MIEMBROS    ♙ DEPORTE DE ÉLITE',
              style: TextStyle(color: Color(0xFF9BA6B7), fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// FORMULARIO DE REGISTRO (CON Logo.png EN LA IZQUIERDA Y BOTÓN ATRÁS ABAJO)
// =============================================================================
class RoleRegistrationForm extends StatefulWidget {
  final String role;
  const RoleRegistrationForm({super.key, required this.role});

  @override
  State<RoleRegistrationForm> createState() => _RoleRegistrationFormState();
}

class _RoleRegistrationFormState extends State<RoleRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Controladores Estudiante
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _edadController = TextEditingController();
  final _pesoController = TextEditingController();
  final _carnetController = TextEditingController();
  final _carreraController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();

  // Controladores Entrenador
  final _nombreApellidoCoachController = TextEditingController();
  final _disciplinaExperienciaController = TextEditingController();
  final _certificacionController = TextEditingController();

  // Controladores Generales
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool get _isCoach => widget.role.toLowerCase().contains('entrenador');

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _carnetController.dispose();
    _carreraController.dispose();
    _fechaNacimientoController.dispose();
    _nombreApellidoCoachController.dispose();
    _disciplinaExperienciaController.dispose();
    _certificacionController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Row(
          children: [
            // =================================================================
            // LADO IZQUIERDO: BANNER VISUAL OSCURO
            // =================================================================
            if (isDesktop)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    image: DecorationImage(
                      image: NetworkImage(
                        _isCoach
                            ? 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80'
                            : 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1200&q=80',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: const ColorFilter.mode(
                        Color(0xF50A192F),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5500),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isCoach ? 'COMUNIDAD UNIMET' : 'ÚNETE A LA ÉLITE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            fontFamily: 'Arial',
                            color: Colors.white,
                          ),
                          children: _isCoach
                              ? const [
                                  TextSpan(text: 'Dirige el talento.\n'),
                                  TextSpan(
                                    text: 'Eleva el rendimiento.',
                                    style: TextStyle(color: Color(0xFFFF5500)),
                                  ),
                                ]
                              : const [
                                  TextSpan(text: 'TU CAMINO AL\n'),
                                  TextSpan(
                                    text: 'ÉXITO DEPORTIVO\n',
                                    style: TextStyle(color: Color(0xFFFF5500)),
                                  ),
                                  TextSpan(text: 'COMIENZA AQUÍ.'),
                                ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 460,
                        child: Text(
                          _isCoach
                              ? 'Gestiona tus atletas, planifica entrenamientos y lleva los equipos de la Universidad Metropolitana a la cima deportiva.'
                              : 'Regístrate para acceder al catálogo completo de disciplinas, torneos inter-facultades y seguimiento de tus créditos deportivos.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_isCoach) ...[
                        _buildLeftFeature('GESTIÓN DE PLANTILLAS Y ASISTENCIA'),
                        const SizedBox(height: 16),
                        _buildLeftFeature('PLANIFICACIÓN DE ENTRENAMIENTOS'),
                        const SizedBox(height: 16),
                        _buildLeftFeature('REPORTES DE DESEMPEÑO INSTITUCIONAL'),
                      ] else ...[
                        _buildLeftFeature('ACCESO A INSTALACIONES DE PRIMER NIVEL'),
                        const SizedBox(height: 16),
                        _buildLeftFeature('INSCRIPCIÓN SIMPLIFICADA A DISCIPLINAS'),
                        const SizedBox(height: 16),
                        _buildLeftFeature('GESTIÓN DE FICHA MÉDICA DIGITAL'),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),

            // =================================================================
            // LADO DERECHO: FORMULARIO CON Logo.png EN LA IZQUIERDA
            // =================================================================
            Expanded(
              flex: 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LOGO EN LA IZQUIERDA (Logo.png)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'lib/assets/Logo.png',
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // BOTÓN DE VOLVER ATRÁS (DEBAJO DEL LOGO)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            alignment: Alignment.centerLeft,
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2C59)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 16),

                          // Título y Subtítulo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isCoach
                                    ? 'Registro — Entrenador'
                                    : 'REGISTRO DE ESTUDIANTE',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F2C59),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_isCoach)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5500)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Revisión 48 h',
                                    style: TextStyle(
                                      color: Color(0xFFFF5500),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isCoach
                                ? 'Solicitud sujeta a validación institucional.'
                                : 'Completa tus datos para crear tu perfil de atleta universitario.',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // CAMPOS SEGÚN EL ROL
                          if (_isCoach) ...[
                            // Campos de Entrenador
                            _buildFormField(
                              label: 'NOMBRE Y APELLIDO *',
                              hint: 'Carlos Rivas',
                              controller: _nombreApellidoCoachController,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CORREO INSTITUCIONAL *',
                              hint: 'carlos.rivas@unimet.edu.ve',
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'DISCIPLINA Y EXPERIENCIA *',
                              hint: 'Fútbol sala - 8 años',
                              controller: _disciplinaExperienciaController,
                              icon: Icons.sports_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CERTIFICACIÓN *',
                              hint: 'Licencia CONMEBOL B - PDF',
                              controller: _certificacionController,
                              icon: Icons.card_membership_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CONTRASEÑA *',
                              hint: '••••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Alerta de revisión 48 horas
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline,
                                      size: 18, color: Color(0xFF0F2C59)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'La Coordinación de Deportes verificará tus credenciales en 48 horas hábiles.',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Campos de Estudiante
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'NOMBRE',
                                    hint: 'Ej. Juan',
                                    controller: _nombreController,
                                    icon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'APELLIDO',
                                    hint: 'Ej. Pérez',
                                    controller: _apellidoController,
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'EDAD *',
                                    hint: '20',
                                    controller: _edadController,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.calendar_today_outlined,
                                    isHighlighted: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'PESO (KG) *',
                                    hint: '72.5',
                                    controller: _pesoController,
                                    keyboardType: TextInputType.number,
                                    icon: Icons.fitness_center_outlined,
                                    isHighlighted: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'NÚMERO DE CARNET',
                              hint: '20241100XX',
                              controller: _carnetController,
                              icon: Icons.credit_card_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CARRERA UNIVERSITARIA',
                              hint: 'Ej. Ingeniería de Sistemas',
                              controller: _carreraController,
                              icon: Icons.school_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'FECHA DE NACIMIENTO',
                              hint: 'dd/mm/aaaa',
                              controller: _fechaNacimientoController,
                              icon: Icons.calendar_month_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CORREO INSTITUCIONAL *',
                              hint: 'usuario@correo.unimet.ve',
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'CONTRASEÑA *',
                              hint: '••••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Botón Crear Cuenta
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5500),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _isCoach
                                            ? 'Solicitud de entrenador enviada a revisión.'
                                            : 'Formulario de estudiante enviado con éxito.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'CREAR CUENTA',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftFeature(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5500).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFFFF5500),
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isHighlighted = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2C59),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            isHighlighted: isHighlighted,
            suffixIcon: suffixIcon,
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.trim().isEmpty)) {
              return 'Campo requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isHighlighted = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: isHighlighted ? const Color(0xFFFFF8F5) : const Color(0xFFF6F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 18),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: isHighlighted
            ? const BorderSide(color: Color(0xFFFF5500), width: 1.2)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: isHighlighted
            ? const BorderSide(color: Color(0xFFFF5500), width: 1.2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
      ),
    );
  }
}