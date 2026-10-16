import 'package:flutter/material.dart';
import 'login_page.dart';
import 'registration_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Colores corporativos de VirtuMet
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Barra de Navegación Superior
            const _Navbar(),

            // 2. Sección Principal (Hero Banner)
            const _HeroSection(),

            // 3. Sección: Comunidad y Liderazgo
            const _FeatureSection2(),

            // 4. Sección: Tecnología y Deporte (Grilla de Tarjetas)
            const _TechGridSection(),

            // 5. Banner de Llamado a la Acción (CTA Azul)
            const _CtaBannerSection(),

            // 6. Franja Institucional (UNIMET / Logos)
            const _SponsorsSection(),

            // 7. Pie de Página (Footer)
            const _FooterSection(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 1. NAVBAR (BARRA DE NAVEGACIÓN SUPERIOR CON LOGO OFICIAL)
// =============================================================================
class _Navbar extends StatelessWidget {
  const _Navbar();

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
          // Logo Oficial VirtuMet en PNG
          Image.asset(
            'lib/assets/Logo.png',
            height: 70,
            fit: BoxFit.contain,
          ),
          const Spacer(),

          // Menú de Enlaces
          _navLink('Inicio'),
          _navLink('Servicios'),
          _navLink('Deportes'),

          const SizedBox(width: 30),

          // Botón Ingresar (Conectado a LoginPage)
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

  static Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {}, 
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
// 2. HERO SECTION (HERO BANNER PRINCIPAL)
// =============================================================================
class _HeroSection extends StatelessWidget {
  const _HeroSection();

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
          // Badge Novedad
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

          // Título Principal
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

          // Subtítulo
          const SizedBox(
            width: 700,
            child: Text(
              'Descubre un ecosistema diseñado para potenciar tu talento físico y académico. VirtuMet conecta a la comunidad atlética de la UNIMET con una gestión integral.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),

          // Botones de Acción
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón EMPEZAR AHORA > (Conectado a LoginPage)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
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
                onPressed: () {}, 
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

          // Barra de Estadísticas
          Wrap(
            spacing: 50,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: const [
              _StatItem(number: '2,500+', label: 'ATLETAS ACTIVOS'),
              _StatItem(number: '18', label: 'DISCIPLINAS'),
              _StatItem(number: '45', label: 'ENTRENADORES'),
            ],
          ),
        ],
      ),
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
        Text(number, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: LandingPage.orangePrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// =============================================================================
// 3. SECCIÓN: COMUNIDAD Y LIDERAZGO
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
              // Columna Izquierda: Imagen
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

              // Columna Derecha: Texto
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
                      onPressed: () {}, 
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
// 4. SECCIÓN: GRILLA DE TECNOLOGÍA Y DEPORTE
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
          const Text('EL PODER DE LA PLATAFORMA', style: TextStyle(color: LandingPage.orangePrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('TECNOLOGÍA Y DEPORTE EN ARMONÍA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: LandingPage.blueDark)),
          const SizedBox(height: 12),
          const Text('Combinamos la innovación digital con la infraestructura física para una experiencia sin límites.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 50),

          // Tarjetas de Funcionalidades
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
// 5. BANNER DE LLAMADO A LA ACCIÓN (CTA AZUL)
// =============================================================================
class _CtaBannerSection extends StatelessWidget {
  const _CtaBannerSection();

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
                // Botón REGÍSTRATE AHORA > (Conectado a selección de rol)
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
                  onPressed: () {}, 
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
// 6. FRANJA INSTITUCIONAL (PATROCINADORES / UNIMET)
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
// 7. PIE DE PÁGINA (FOOTER CON LOGO OFICIAL)
// =============================================================================
class _FooterSection extends StatelessWidget {
  const _FooterSection();

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
              // Columna 1: Logo Oficial & Info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'lib/assets/Logo.png',
                      height: 90,
                      fit: BoxFit.contain,
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

              // Columna 2 y 3: Enlaces
              _footerColumn('PLATAFORMA', ['Inicio', 'Catálogo', 'Inscripciones']),
              _footerColumn('ASISTENCIA', ['Soporte', 'Preguntas Frecuentes', 'Contacto']),
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

  static Widget _footerColumn(String title, List<String> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          ...links.map((link) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(link, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          )),
        ],
      ),
    );
  }
}