import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'registration_page.dart';
import 'landing_catalog_section.dart';
import 'faq_section.dart';
import 'support_chat.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1F2937);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _catalogKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey<FaqSectionState> _faqKey = GlobalKey<FaqSectionState>();

  // Regresa al inicio superior de la página
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Desplaza la página hasta el catálogo de disciplinas
  void _scrollToCatalog() {
    final ctx = _catalogKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // Desplaza la página hasta la sección de Servicios / Tecnología
  void _scrollToServices() {
    final ctx = _servicesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // Desplaza la página hasta Preguntas Frecuentes
  void _scrollToFaq() {
    // Primero se despliega la sección y, ya con su tamaño final, se hace el scroll
    _faqKey.currentState?.abrir();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _faqKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 1. Barra de Navegación (Solo Inicio y Servicios)
            _Navbar(
              onInicio: _scrollToTop,
              onServicios: _scrollToServices,
              onPreguntas: _scrollToFaq,
            ),

            // 2. Banner Principal (Hero)
            _HeroSection(onVerDisciplinas: _scrollToCatalog),

            // 3. Catálogo público en tiempo real
            KeyedSubtree(
              key: _catalogKey,
              child: const LandingCatalogSection(),
            ),

            // 4. Comunidad y Liderazgo (Explorar Más lleva a Registro)
            const _FeatureSection2(),

            // 5. Servicios / Tecnología y Deporte
            KeyedSubtree(
              key: _servicesKey,
              child: const _TechGridSection(),
            ),

            // 5.1 Preguntas Frecuentes (interactivas)
            FaqSection(key: _faqKey),

            // 6. Banner CTA
            _CtaBannerSection(onExplorarCatalogo: _scrollToCatalog),

            // 7. Franja Institucional
            const _SponsorsSection(),

            // 8. Pie de Página
            _FooterSection(
              onInicio: _scrollToTop,
              onServicios: _scrollToServices,
              onCatalogo: _scrollToCatalog,
              onPreguntas: _scrollToFaq,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 1. NAVBAR (Navegación Limpia)
// =============================================================================
class _Navbar extends StatelessWidget {
  final VoidCallback onInicio;
  final VoidCallback onServicios;
  final VoidCallback onPreguntas;

  const _Navbar({
    required this.onInicio,
    required this.onServicios,
    required this.onPreguntas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onInicio,
            child: Image.asset(
              'lib/assets/Logo.png',
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),

          _navLink('Inicio', onTap: onInicio),
          _navLink('Servicios', onTap: onServicios),
          _navLink('Preguntas', onTap: onPreguntas),
          _navLink('Soporte', onTap: () => showSupportChat(context)),

          const SizedBox(width: 30),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: LandingPage.blueDark),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ingresar', style: TextStyle(color: LandingPage.blueDark)),
          ),
        ],
      ),
    );
  }

  static Widget _navLink(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: LandingPage.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. HERO SECTION
// =============================================================================
class _HeroSection extends StatelessWidget {
  final VoidCallback onVerDisciplinas;
  const _HeroSection({required this.onVerDisciplinas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?auto=format&fit=crop&w=1600&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0xCC0F2C59),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: LandingPage.orangePrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'NOVEDAD • Inscripciones Abiertas 2026-C',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
              children: [
                TextSpan(text: 'IMPULSANDO LA EXCELENCIA\n'),
                TextSpan(text: 'DEPORTIVA UNIVERSITARIA', style: TextStyle(color: LandingPage.orangePrimary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const SizedBox(
            width: 700,
            child: Text(
              'Descubre un ecosistema diseñado para potenciar tu talento físico y académico. VirtuMet conecta a la comunidad atlética de la UNIMET con una gestión integral.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LandingPage.orangePrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('EMPEZAR AHORA >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: onVerDisciplinas,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('VER DISCIPLINAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 60),

          const _RealTimeHeroStats(),
        ],
      ),
    );
  }
}

class _RealTimeHeroStats extends StatelessWidget {
  const _RealTimeHeroStats();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        int totalEstudiantes = 0;
        int totalEntrenadores = 0;

        if (usersSnapshot.hasData && usersSnapshot.data != null) {
          for (var doc in usersSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String rol =
                (data['rol'] ?? data['role'] ?? '').toString().toLowerCase().trim();

            if (rol == 'entrenador' || rol == 'profesor' || rol == 'maestro') {
              totalEntrenadores++;
            } else if (rol == 'estudiante' || rol == 'atleta' || rol == 'alumno') {
              totalEstudiantes++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('deportes').snapshots(),
          builder: (context, sportsSnapshot) {
            final int totalDeportes = sportsSnapshot.data?.docs.length ?? 0;
            final bool isLoading = !usersSnapshot.hasData || !sportsSnapshot.hasData;

            return Wrap(
              spacing: 50,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _StatItem(
                  number: isLoading ? '...' : '$totalEstudiantes',
                  label: 'ATLETAS ACTIVOS',
                ),
                _StatItem(
                  number: isLoading ? '...' : '$totalDeportes',
                  label: 'DISCIPLINAS',
                ),
                _StatItem(
                  number: isLoading ? '...' : '$totalEntrenadores',
                  label: 'ENTRENADORES',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;
  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: LandingPage.orangePrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. COMUNIDAD Y LIDERAZGO
// =============================================================================
class _FeatureSection2 extends StatelessWidget {
  const _FeatureSection2();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
      color: LandingPage.bgLight,
      child: Center(
        child: SizedBox(
          width: 1100,
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: LandingPage.blueDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.groups, color: LandingPage.orangePrimary, size: 20),
                            SizedBox(width: 8),
                            Text('Comunidad Activa UNIMET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 50),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.diversity_3, color: LandingPage.blueDark, size: 36),
                    const SizedBox(height: 16),
                    const Text(
                      'COMUNIDAD Y LIDERAZGO',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LandingPage.blueDark),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fomentamos el trabajo en equipo, la disciplina y el desarrollo de habilidades directivas a través de la convivencia sana y la competencia universitaria.',
                      style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    _bulletPoint('Personal Certificado'),
                    _bulletPoint('Espacio de Convivencia'),
                    _bulletPoint('Eventos e Integración'),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationPage()),
                        );
                      },
                      child: const Text('EXPLORAR MÁS >', style: TextStyle(color: LandingPage.orangePrimary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: LandingPage.orangePrimary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: LandingPage.textDark)),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. SECCIÓN DE SERVICIOS (TECNOLOGÍA Y DEPORTE EN ARMONÍA)
// =============================================================================
class _TechGridSection extends StatelessWidget {
  const _TechGridSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
      color: Colors.white,
      child: Column(
        children: [
          const Text('NUESTROS SERVICIOS', style: TextStyle(color: LandingPage.orangePrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('TECNOLOGÍA Y DEPORTE EN ARMONÍA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: LandingPage.blueDark)),
          const SizedBox(height: 12),
          const Text('Combinamos la innovación digital con la infraestructura física para una experiencia sin límites.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 50),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(icon: Icons.sports, title: 'Gestión Deportiva', desc: 'Control de disciplinas, cupos en tiempo real e inscripciones.'),
              _FeatureCard(icon: Icons.fitness_center, title: 'Entrenamiento Élite', desc: 'Seguimiento de asistencia y rendimiento por entrenador.'),
              _FeatureCard(icon: Icons.event, title: 'Eventos & Torneos', desc: 'Muro de anuncios, eventos y calendarios integrados.'),
              _FeatureCard(icon: Icons.verified_user, title: 'Control Digital', desc: 'Ficha médica de emergencia y solvencia automática.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: LandingPage.blueDark, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LandingPage.blueDark)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. BANNER CTA
// =============================================================================
class _CtaBannerSection extends StatelessWidget {
  final VoidCallback onExplorarCatalogo;
  const _CtaBannerSection({required this.onExplorarCatalogo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
        decoration: BoxDecoration(
          color: LandingPage.blueDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                children: [
                  TextSpan(text: '¿LISTO PARA LLEVAR TU PASIÓN AL '),
                  TextSpan(text: 'SIGUIENTE NIVEL?', style: TextStyle(color: LandingPage.orangePrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Únete hoy a la comunidad VirtuMet y descubre por qué somos la plataforma líder en gestión deportiva académica.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingPage.orangePrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('REGÍSTRATE AHORA >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onExplorarCatalogo,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('EXPLORAR CATÁLOGO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Acceso institucional exclusivo para estudiantes y personal UNIMET.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 6. FRANJA INSTITUCIONAL
// =============================================================================
class _SponsorsSection extends StatelessWidget {
  const _SponsorsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      color: Colors.white,
      child: Column(
        children: [
          const Text('RESPALDADO POR LA COMUNIDAD METROPOLITANA', style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _SponsorTag('UNIMET'),
              SizedBox(width: 30),
              _SponsorTag('ATHLETICS'),
              SizedBox(width: 30),
              _SponsorTag('DEPORTES UNIMET'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SponsorTag extends StatelessWidget {
  final String text;
  const _SponsorTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black26, fontSize: 16));
  }
}

// =============================================================================
// 7. PIE DE PÁGINA
// =============================================================================
class _FooterSection extends StatelessWidget {
  final VoidCallback onInicio;
  final VoidCallback onServicios;
  final VoidCallback onCatalogo;
  final VoidCallback onPreguntas;

  const _FooterSection({
    required this.onInicio,
    required this.onServicios,
    required this.onCatalogo,
    required this.onPreguntas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 60),
      color: const Color(0xFF0B192C),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onInicio,
                      child: Image.asset(
                        'lib/assets/Logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plataforma digital para la gestión y promoción del deporte universitario en la Universidad Metropolitana.',
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PLATAFORMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    InkWell(onTap: onInicio, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Inicio', style: TextStyle(color: Colors.white54, fontSize: 13)))),
                    InkWell(onTap: onServicios, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Servicios', style: TextStyle(color: Colors.white54, fontSize: 13)))),
                    InkWell(onTap: onCatalogo, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Catálogo', style: TextStyle(color: Colors.white54, fontSize: 13)))),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ASISTENCIA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                    const SizedBox(height: 12),
                    InkWell(onTap: () => showSupportChat(context), child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Soporte', style: TextStyle(color: Colors.white54, fontSize: 13)))),
                    InkWell(onTap: onPreguntas, child: const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Preguntas Frecuentes', style: TextStyle(color: Colors.white54, fontSize: 13)))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Contacto', style: TextStyle(color: Colors.white54, fontSize: 13))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          const Text('© 2026 VirtuMet UNIMET. Todos los derechos reservados.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}