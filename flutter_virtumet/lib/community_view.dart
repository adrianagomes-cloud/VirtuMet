import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

typedef UserProfileMap = Map<String, String>;

class CommunityView extends StatefulWidget {
  /// Valores esperados: 'teacher', 'student', 'admin'
  final String userRole;

  const CommunityView({
    super.key,
    required this.userRole,
  });

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color textGrey = Color(0xFF6C757D);

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _selectedSportFilter = 'Todos';
  String _searchQuery = '';

  bool get _isTeacher => widget.userRole == 'teacher';
  bool get _isAdmin => widget.userRole == 'admin';

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'VM';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatTimestamp(dynamic createdAt, String fallback) {
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Hace un momento';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return fallback.isNotEmpty ? fallback : 'Reciente';
  }

  Future<UserProfileMap> _getCurrentUserProfile() async {
    final uid = _currentUser?.uid ?? '';
    String nombre = _currentUser?.displayName ?? '';
    String fotoUrl = _currentUser?.photoURL ?? '';

    if (uid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          nombre = (data['nombreApellido'] ??
                  data['nombreCompleto'] ??
                  data['nombre'] ??
                  nombre)
              .toString()
              .trim();
          fotoUrl = (data['fotoUrl'] ?? data['photoUrl'] ?? fotoUrl)
              .toString()
              .trim();
        }
      } catch (_) {}
    }

    if (nombre.isEmpty) {
      if (_isAdmin) {
        nombre = 'Administrador UNIMET';
      } else if (_isTeacher) {
        nombre = 'Entrenador UNIMET';
      } else {
        nombre = 'Estudiante UNIMET';
      }
    }

    return {'uid': uid, 'nombre': nombre, 'fotoUrl': fotoUrl};
  }

  void _openCreatePostDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreatePostDialog(
        getUserProfile: _getCurrentUserProfile,
      ),
    );
  }

  Future<void> _toggleLike(String postId, List<String> currentLikes) async {
    final uid = _currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final ref =
        FirebaseFirestore.instance.collection('comunidad_posts').doc(postId);
    if (currentLikes.contains(uid)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

  Future<void> _confirmDeletePost(String postId, String autorNombre) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Eliminar publicación',
              style: TextStyle(
                color: blueDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Seguro que deseas eliminar esta publicación de $autorNombre y todos sus comentarios? Esta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final postRef =
          FirebaseFirestore.instance.collection('comunidad_posts').doc(postId);
      final commentsSnap = await postRef.collection('comentarios').get();
      for (final doc in commentsSnap.docs) {
        await doc.reference.delete();
      }
      await postRef.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicación eliminada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar publicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: orangePrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'COMUNIDAD DEPORTIVA',
                                style: TextStyle(
                                  color: orangePrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Muro de la Comunidad VirtuMet',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: blueDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isTeacher
                              ? 'Comparte fotos de tus entrenamientos, torneos y momentos con tus atletas.'
                              : _isAdmin
                                  ? 'Supervisa las publicaciones de entrenadores y comentarios de los estudiantes.'
                                  : 'Explora los momentos deportivos publicados por los entrenadores y deja tus comentarios.',
                          style: const TextStyle(fontSize: 14, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  if (_isTeacher) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      onPressed: _openCreatePostDialog,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: const Text(
                        'Nueva Publicación',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('deportes')
                    .snapshots(),
                builder: (context, sportsSnap) {
                  final Set<String> sportNames = {'Todos'};
                  for (final doc in sportsSnap.data?.docs ?? []) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombre'] ?? '').toString().trim();
                    if (nombre.isNotEmpty) sportNames.add(nombre);
                  }
                  sportNames.add('General');

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase().trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por entrenador, deporte o descripción...',
                            hintStyle:
                                const TextStyle(fontSize: 13, color: textGrey),
                            prefixIcon: const Icon(Icons.search,
                                size: 20, color: textGrey),
                            filled: true,
                            fillColor: bgLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: sportNames.map((sport) {
                              final bool selected =
                                  _selectedSportFilter == sport;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(sport),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedSportFilter = sport;
                                    });
                                  },
                                  selectedColor: blueDark,
                                  backgroundColor: bgLight,
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : blueDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: selected
                                          ? blueDark
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comunidad_posts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(color: orangePrimary),
                      ),
                    );
                  }

                  final rawDocs = snapshot.data?.docs ?? [];

                  final sortedDocs = [...rawDocs]..sort((a, b) {
                      final ma = a.data() as Map<String, dynamic>;
                      final mb = b.data() as Map<String, dynamic>;
                      final ta = ma['createdAt'];
                      final tb = mb['createdAt'];
                      if (ta is Timestamp && tb is Timestamp) {
                        return tb.compareTo(ta);
                      }
                      if (ta == null && tb is Timestamp) return -1;
                      if (ta is Timestamp && tb == null) return 1;
                      return 0;
                    });

                  final filteredDocs = sortedDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final deporte =
                        (data['deporte'] ?? 'General').toString().trim();
                    final autor =
                        (data['autorNombre'] ?? '').toString().toLowerCase();
                    final desc =
                        (data['descripcion'] ?? '').toString().toLowerCase();

                    final matchesSport = _selectedSportFilter == 'Todos' ||
                        deporte.toLowerCase() ==
                            _selectedSportFilter.toLowerCase();
                    final matchesSearch = _searchQuery.isEmpty ||
                        autor.contains(_searchQuery) ||
                        desc.contains(_searchQuery) ||
                        deporte.toLowerCase().contains(_searchQuery);

                    return matchesSport && matchesSearch;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 60, horizontal: 24),
                      decoration: _cardDecoration,
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 54,
                              color: blueDark.withValues(alpha: 0.35)),
                          const SizedBox(height: 14),
                          const Text(
                            'Aún no hay publicaciones en la comunidad',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: blueDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isTeacher
                                ? 'Sé el primero en compartir una foto de tu disciplina haciendo clic en "Nueva Publicación".'
                                : 'Cuando los entrenadores publiquen fotos de sus disciplinas aparecerán aquí.',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontSize: 13, color: textGrey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: filteredDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildInstagramPostCard(doc.id, data);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramPostCard(String postId, Map<String, dynamic> data) {
    final String autorUid = (data['autorUid'] ?? '').toString();
    final String autorNombre =
        (data['autorNombre'] ?? 'Entrenador UNIMET').toString();
    final String autorFotoUrl = (data['autorFotoUrl'] ?? '').toString();
    final String deporte = (data['deporte'] ?? 'General').toString();
    final String descripcion = (data['descripcion'] ?? '').toString();
    final String imagenUrl = (data['imagenUrl'] ?? '').toString();
    final String fechaTexto = (data['fechaTexto'] ?? '').toString();
    final List<String> likes = List<String>.from(data['likes'] ?? []);

    final String currentUid = _currentUser?.uid ?? '';
    final bool isLiked = currentUid.isNotEmpty && likes.contains(currentUid);

    final bool canDelete = _isAdmin ||
        (_isTeacher && currentUid.isNotEmpty && autorUid == currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: orangePrimary.withValues(alpha: 0.16),
                  backgroundImage: autorFotoUrl.isNotEmpty
                      ? NetworkImage(autorFotoUrl)
                      : null,
                  child: autorFotoUrl.isEmpty
                      ? Text(
                          _getInitials(autorNombre),
                          style: const TextStyle(
                            color: orangePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              autorNombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: blueDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: blueDark.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ENTRENADOR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: blueDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(data['createdAt'], fechaTexto),
                        style: const TextStyle(fontSize: 11, color: textGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: orangePrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports,
                          size: 13, color: orangePrimary),
                      const SizedBox(width: 4),
                      Text(
                        deporte,
                        style: const TextStyle(
                          color: orangePrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 21),
                    tooltip: _isAdmin
                        ? 'Eliminar publicación (Administrador)'
                        : 'Eliminar mi publicación',
                    onPressed: () => _confirmDeletePost(postId, autorNombre),
                  ),
                ],
              ],
            ),
          ),
          if (imagenUrl.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 460),
              color: const Color(0xFF0A192F),
              child: _buildPostImage(imagenUrl),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleLike(postId, likes),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked ? Colors.red : blueDark,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${likes.length} Me gusta',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: blueDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 20, color: textGrey),
                    const SizedBox(width: 6),
                    const Text(
                      'Comentarios',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textGrey,
                      ),
                    ),
                  ],
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '$autorNombre  ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blueDark,
                          ),
                        ),
                        TextSpan(text: descripcion),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 16, thickness: 1, color: Color(0xFFE2E8F0)),
          _PostCommentsSection(
            postId: postId,
            userRole: widget.userRole,
            getUserProfile: _getCurrentUserProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _brokenImagePlaceholder(),
        );
      } catch (_) {
        return _brokenImagePlaceholder();
      }
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          height: 260,
          child: Center(
            child: CircularProgressIndicator(color: orangePrimary),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _brokenImagePlaceholder(),
    );
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      height: 220,
      color: bgLight,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 40, color: textGrey),
            SizedBox(height: 6),
            Text('No se pudo cargar la imagen',
                style: TextStyle(fontSize: 12, color: textGrey)),
          ],
        ),
      ),
    );
  }
}

class _PostCommentsSection extends StatefulWidget {
  final String postId;
  final String userRole;
  final Future<UserProfileMap> Function() getUserProfile;

  const _PostCommentsSection({
    required this.postId,
    required this.userRole,
    required this.getUserProfile,
  });

  @override
  State<_PostCommentsSection> createState() => _PostCommentsSectionState();
}

class _PostCommentsSectionState extends State<_PostCommentsSection> {
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color textGrey = Color(0xFF6C757D);

  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  bool _showAllComments = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final profile = await widget.getUserProfile();
      final String rolLabel = widget.userRole == 'admin'
          ? 'Administrador'
          : widget.userRole == 'teacher'
              ? 'Entrenador'
              : 'Estudiante';

      await FirebaseFirestore.instance
          .collection('comunidad_posts')
          .doc(widget.postId)
          .collection('comentarios')
          .add({
        'autorUid': profile['uid'] ?? '',
        'autorNombre': profile['nombre'] ?? 'Usuario',
        'autorRol': rolLabel,
        'texto': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al comentar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('comunidad_posts')
          .doc(widget.postId)
          .collection('comentarios')
          .doc(commentId)
          .delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isAdmin = widget.userRole == 'admin';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('comunidad_posts')
                .doc(widget.postId)
                .collection('comentarios')
                .snapshots(),
            builder: (context, snapshot) {
              final rawDocs = snapshot.data?.docs ?? [];
              final docs = [...rawDocs]..sort((a, b) {
                  final ma = a.data() as Map<String, dynamic>;
                  final mb = b.data() as Map<String, dynamic>;
                  final ta = ma['createdAt'];
                  final tb = mb['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return ta.compareTo(tb);
                  }
                  if (ta == null && tb is Timestamp) return 1;
                  if (ta is Timestamp && tb == null) return -1;
                  return 0;
                });

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Sé el primero en comentar esta publicación.',
                    style: TextStyle(fontSize: 12, color: textGrey),
                  ),
                );
              }

              final visibleDocs = _showAllComments || docs.length <= 3
                  ? docs
                  : docs.sublist(docs.length - 3);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (docs.length > 3 && !_showAllComments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _showAllComments = true),
                        child: Text(
                          'Ver los ${docs.length} comentarios...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ),
                  ...visibleDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final autor = (data['autorNombre'] ?? 'Alumno').toString();
                    final rol = (data['autorRol'] ?? 'Estudiante').toString();
                    final texto = (data['texto'] ?? '').toString();
                    final autorUid = (data['autorUid'] ?? '').toString();

                    final bool canDeleteComment = isAdmin ||
                        (currentUid.isNotEmpty && autorUid == currentUid);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: bgLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$autor ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: blueDark,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '($rol): ',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: orangePrimary,
                                      ),
                                    ),
                                    TextSpan(text: texto),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (canDeleteComment)
                            IconButton(
                              padding: const EdgeInsets.only(left: 4),
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close_rounded,
                                  size: 16, color: textGrey),
                              tooltip: 'Borrar comentario',
                              onPressed: () => _deleteComment(doc.id),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  onSubmitted: (_) => _submitComment(),
                  decoration: InputDecoration(
                    hintText: widget.userRole == 'student'
                        ? 'Escribe un comentario sobre esta publicación...'
                        : 'Responder o comentar...',
                    hintStyle: const TextStyle(fontSize: 12, color: textGrey),
                    filled: true,
                    fillColor: bgLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSending ? null : _submitComment,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                tooltip: 'Publicar comentario',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePostDialog extends StatefulWidget {
  final Future<UserProfileMap> Function() getUserProfile;

  const _CreatePostDialog({required this.getUserProfile});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color textGrey = Color(0xFF6C757D);

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedSport = 'General';
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _useUrlMode = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = file.name;
        _useUrlMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _resolveImageUrl(String uid) async {
    if (_useUrlMode) {
      return _urlController.text.trim();
    }

    if (_pickedBytes == null) return '';

    try {
      final fileName =
          'comunidad/${uid}_${DateTime.now().millisecondsSinceEpoch}_${_pickedFileName ?? 'foto.jpg'}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref
          .putData(
            _pickedBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          )
          .timeout(const Duration(seconds: 8));
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      if (_pickedBytes!.lengthInBytes > 750 * 1024) {
        throw Exception(
            'La imagen pesa más de 750 KB. Elige una foto más ligera o pega un enlace URL.');
      }
      return 'data:image/jpeg;base64,${base64Encode(_pickedBytes!)}';
    }
  }

  Future<void> _publishPost() async {
    final descripcion = _descController.text.trim();
    final hasImage = _useUrlMode
        ? _urlController.text.trim().isNotEmpty
        : _pickedBytes != null;

    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una foto del deporte para publicar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una descripción para acompañar la foto.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final profile = await widget.getUserProfile();
      final uid = profile['uid'] ?? '';
      final imageUrl = await _resolveImageUrl(uid);

      final now = DateTime.now();
      final fechaTexto =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      await FirebaseFirestore.instance.collection('comunidad_posts').add({
        'autorUid': uid,
        'autorNombre': profile['nombre'] ?? 'Entrenador UNIMET',
        'autorFotoUrl': profile['fotoUrl'] ?? '',
        'deporte': _selectedSport,
        'descripcion': descripcion,
        'imagenUrl': imageUrl,
        'likes': <String>[],
        'fechaTexto': fechaTexto,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación compartida en la comunidad!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: orangePrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_a_photo_rounded,
                color: orangePrimary, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Nueva Publicación en Comunidad',
              style: TextStyle(
                color: blueDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            onPressed: _isPublishing ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: textGrey),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Disciplina deportiva',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: blueDark,
                ),
              ),
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('deportes')
                    .snapshots(),
                builder: (context, snap) {
                  final Set<String> sports = {'General'};
                  for (final doc in snap.data?.docs ?? []) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombre'] ?? '').toString().trim();
                    if (nombre.isNotEmpty) sports.add(nombre);
                  }
                  if (!sports.contains(_selectedSport)) {
                    _selectedSport = 'General';
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedSport,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    items: sports
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 14, color: blueDark)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSport = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fotografía del deporte',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: blueDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useUrlMode = !_useUrlMode;
                      });
                    },
                    child: Text(
                      _useUrlMode
                          ? 'Subir archivo desde dispositivo'
                          : 'Usar enlace URL de imagen',
                      style: const TextStyle(
                        fontSize: 12,
                        color: orangePrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_useUrlMode)
                TextField(
                  controller: _urlController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'https://ejemplo.com/foto-entrenamiento.jpg',
                    hintStyle: const TextStyle(fontSize: 12, color: textGrey),
                    filled: true,
                    fillColor: bgLight,
                    prefixIcon: const Icon(Icons.link, color: textGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: _pickImageFromDevice,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_pickedBytes!, fit: BoxFit.cover),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Cambiar foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 40, color: orangePrimary),
                              SizedBox(height: 8),
                              Text(
                                'Haz clic para seleccionar una foto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: blueDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Formatos JPG o PNG desde tu computadora o galería',
                                style: TextStyle(fontSize: 11, color: textGrey),
                              ),
                            ],
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Descripción / Pie de foto',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: blueDark,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Cuenta cómo estuvo el entrenamiento, partido o actividad...',
                  hintStyle: const TextStyle(fontSize: 12, color: textGrey),
                  filled: true,
                  fillColor: bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPublishing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: textGrey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangePrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isPublishing ? null : _publishPost,
          icon: _isPublishing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.publish_rounded, size: 18),
          label: Text(
            _isPublishing ? 'Publicando...' : 'Publicar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}