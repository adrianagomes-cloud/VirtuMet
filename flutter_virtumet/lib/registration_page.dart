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
                                    'https://images.unsplash.com/photo-1579952363873-27f3bede9f55?auto=format&fit=crop&w=900&q=80',
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

class _RegistrationNavbar extends StatelessWidget {
  const _RegistrationNavbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFD),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE2EC))),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: RegistrationPage._navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 7),
          const Text(
            'VirtuMet',
            style: TextStyle(
              color: RegistrationPage._navy,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            color: RegistrationPage._orange,
            child: const Text(
              'Catálogo',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
          const SizedBox(width: 12),
          const _NavItem('Mis Inscripciones'),
          const _NavItem('Anuncios'),
          const _NavItem('Comunidad'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  const _NavItem(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF637087), fontSize: 8),
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
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: Color(0xFFE1E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 175,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFB9C3D2),
                    child: const Icon(Icons.sports, color: Colors.white, size: 54),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(.65)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RegistrationPage._orange,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, color: RegistrationPage._navy, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: RegistrationPage._navy,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF5D687A),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 13),
                ...benefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: RegistrationPage._orange,
                          size: 13,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Color(0xFF4E5A6D),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RegistrationPage._navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
              style: TextStyle(color: Color(0xFF667995), fontSize: 8),
            ),
            Text(
              '◉ IDENTIDAD VALIDADA    ⚒ +1,200 MIEMBROS    ♙ DEPORTE DE ÉLITE',
              style: TextStyle(color: Color(0xFF9BA6B7), fontSize: 7),
            ),
          ],
        ),
      ],
    );
  }
}

class RoleRegistrationForm extends StatefulWidget {
  final String role;
  const RoleRegistrationForm({super.key, required this.role});

  @override
  State<RoleRegistrationForm> createState() => _RoleRegistrationFormState();
}

class _RoleRegistrationFormState extends State<RoleRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegistrationPage._background,
      appBar: AppBar(
        title: Text('Registro de ${widget.role}'),
        backgroundColor: RegistrationPage._navy,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crea tu cuenta como ${widget.role.toLowerCase()}',
                        style: const TextStyle(
                          color: RegistrationPage._navy,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Usa tu correo institucional para comenzar.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo institucional',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => value == null || !value.contains('@')
                            ? 'Ingresa un correo válido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Usa al menos 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Formulario listo para conectar con Firebase Auth.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RegistrationPage._orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('CREAR CUENTA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
