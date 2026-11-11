import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Mini buscador de imágenes (Wikimedia Commons, sin clave de API) para el formulario de disciplinas.
///
/// Uso:
///   final url = await showImageSearchDialog(context, inicial: 'Voleibol');
///   if (url != null) { ...guardar la URL elegida... }
///
/// Devuelve la URL de la imagen elegida, o null si se cancela.
Future<String?> showImageSearchDialog(BuildContext context,
    {String inicial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ImageSearchDialog(inicial: inicial),
  );
}

class _FotoResultado {
  final String miniatura; // para la cuadrícula
  final String url; // la que se guarda en Firestore
  final String autor; // título del archivo
  const _FotoResultado(this.miniatura, this.url, this.autor);
}

class _ImageSearchDialog extends StatefulWidget {
  final String inicial;
  const _ImageSearchDialog({required this.inicial});

  @override
  State<_ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<_ImageSearchDialog> {
  static const Color navy = Color(0xFF0F2C59);
  static const Color orange = Color(0xFFFF5500);
  static const int _porPagina = 18;

  late final TextEditingController _ctrl;
  final List<_FotoResultado> _fotos = [];
  bool _cargando = false;
  bool _hayMas = false;
  String? _error;
  String _consulta = '';
  int _offset = 0;
  String? _seleccion;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.inicial);
    if (widget.inicial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscar());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar({bool masResultados = false}) async {
    final q = masResultados ? _consulta : _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _cargando = true;
      _error = null;
      if (!masResultados) {
        _fotos.clear();
        _offset = 0;
        _consulta = q;
        _seleccion = null;
      }
    });
    try {
      // Wikimedia Commons: API pública, sin clave. "origin=*" habilita CORS.
      // filetype:bitmap deja solo fotos (excluye SVG, PDF, audio, etc.).
      final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'origin': '*',
        'generator': 'search',
        'gsrnamespace': '6',
        'gsrsearch': '$q filetype:bitmap',
        'gsrlimit': '$_porPagina',
        'gsroffset': '$_offset',
        'prop': 'imageinfo',
        'iiprop': 'url|mime',
        'iiurlwidth': '800',
      });
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw Exception('Error ${resp.statusCode} del servicio de imágenes');
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final pages =
          ((json['query']?['pages'] as Map?) ?? {}).values.toList();
      // El API devuelve las páginas sin orden: se ordenan por relevancia.
      pages.sort((a, b) =>
          ((a['index'] ?? 0) as num).compareTo((b['index'] ?? 0) as num));
      final nuevas = <_FotoResultado>[];
      for (final p in pages) {
        final infos = p['imageinfo'] as List?;
        if (infos == null || infos.isEmpty) continue;
        final info = (infos.first as Map).cast<String, dynamic>();
        final mime = (info['mime'] ?? '').toString();
        if (mime != 'image/jpeg' && mime != 'image/png') continue;
        final url = (info['thumburl'] ?? info['url'] ?? '').toString();
        if (url.isEmpty) continue;
        final titulo = (p['title'] ?? '')
            .toString()
            .replaceFirst('File:', '')
            .replaceFirst(RegExp(r'\.[A-Za-z]+$'), '');
        nuevas.add(_FotoResultado(url, url, titulo));
      }
      final cont = json['continue']?['gsroffset'];
      if (!mounted) return;
      setState(() {
        _fotos.addAll(nuevas);
        _hayMas = cont != null;
        if (cont is int) _offset = cont;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error =
            'No se pudo buscar imágenes. Revisa tu conexión e intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Buscar imagen',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscar(),
                    decoration: InputDecoration(
                      hintText: 'Ej: voleibol, natación, ajedrez…',
                      prefixIcon: const Icon(Icons.search, color: navy),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _cargando ? null : () => _buscar(),
                  child: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Expanded(child: _resultados()),
            const SizedBox(height: 6),
            const Text('Imágenes de Wikimedia Commons (licencias libres)',
                style: TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed:
              _seleccion == null ? null : () => Navigator.pop(context, _seleccion),
          child: const Text('Usar esta imagen'),
        ),
      ],
    );
  }

  Widget _resultados() {
    if (_fotos.isEmpty) {
      if (_cargando) return const Center(child: CircularProgressIndicator());
      if (_consulta.isEmpty) {
        return const Center(
            child: Text('Escribe una disciplina y pulsa Buscar.',
                style: TextStyle(color: Colors.black45)));
      }
      if (_error == null) {
        return const Center(
            child: Text('Sin resultados. Prueba con otra palabra.',
                style: TextStyle(color: Colors.black45)));
      }
      return const SizedBox.shrink();
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: _fotos.length + ((_hayMas || _cargando) ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _fotos.length) {
          return Center(
            child: _cargando
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: () => _buscar(masResultados: true),
                    child: const Text('Más resultados'),
                  ),
          );
        }
        final f = _fotos[i];
        final elegida = f.url == _seleccion;
        return GestureDetector(
          onTap: () => setState(() => _seleccion = f.url),
          onDoubleTap: () => Navigator.pop(context, f.url),
          child: Tooltip(
            message: f.autor,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: elegida ? orange : Colors.transparent, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      f.miniatura,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    if (elegida)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: orange,
                          child:
                              Icon(Icons.check, size: 15, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
