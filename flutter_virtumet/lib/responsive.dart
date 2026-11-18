import 'package:flutter/material.dart';

/// Ayudas para adaptar la interfaz a teléfono, tablet y escritorio.
/// Puntos de corte: móvil < 700 px, compacto (barra con menú) < 980 px.

/// Teléfono (pantalla angosta).
bool esMovil(BuildContext context) => MediaQuery.sizeOf(context).width < 700;

/// Pantalla donde la barra superior completa ya no cabe (teléfono y tablet vertical).
bool esCompacto(BuildContext context) => MediaQuery.sizeOf(context).width < 980;

/// Margen lateral de las páginas: 16 px en teléfono, 24 en tablet, 40 en escritorio.
double margenPagina(BuildContext context) {
  final ancho = MediaQuery.sizeOf(context).width;
  if (ancho < 700) return 16;
  if (ancho < 980) return 24;
  return 40;
}

/// Margen de los diálogos: más estrecho en teléfono para aprovechar el ancho.
EdgeInsets margenDialogo(BuildContext context) => EdgeInsets.symmetric(
      horizontal: esMovil(context) ? 12 : 40,
      vertical: 24,
    );

/// Igual que un Row, pero en teléfono apila los hijos en una columna.
/// Los Expanded/Flexible se "desenvuelven" y los SizedBox(width) pasan a ser
/// separaciones verticales, así se puede usar en lugar de Row sin más cambios.
class FilaAdaptable extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double espacioVertical;

  const FilaAdaptable({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.espacioVertical = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (!esMovil(context)) {
      return Row(crossAxisAlignment: crossAxisAlignment, children: children);
    }
    final items = <Widget>[];
    for (final c in children) {
      if (c is Flexible) {
        // Expanded es un Flexible: se usa directamente el contenido
        items.add(c.child);
      } else if (c is SizedBox && c.child == null && c.width != null) {
        items.add(SizedBox(height: espacioVertical));
      } else {
        items.add(c);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}
