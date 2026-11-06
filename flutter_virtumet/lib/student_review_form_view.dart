import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentReviewFormView extends StatefulWidget {
  final String deporteId;
  final String deporteNombre;
  final String profesorUid;
  final String profesorNombre;

  const StudentReviewFormView({
    super.key,
    required this.deporteId,
    required this.deporteNombre,
    required this.profesorUid,
    required this.profesorNombre,
  });

  @override
  State<StudentReviewFormView> createState() => _StudentReviewFormViewState();
}

class _StudentReviewFormViewState extends State<StudentReviewFormView> {
  int _profesorRating = 5;
  int _sportRating = 5;
  final TextEditingController _profesorCommentController = TextEditingController();
  final TextEditingController _sportCommentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reviews').add({
        'estudianteUid': user?.uid ?? '',
        'estudianteCorreo': user?.email ?? '',
        'deporteId': widget.deporteId,
        'deporteNombre': widget.deporteNombre,
        'profesorUid': widget.profesorUid,
        'profesorNombre': widget.profesorNombre,
        'profesorRating': _profesorRating,
        'profesorComment': _profesorCommentController.text.trim(),
        'sportRating': _sportRating,
        'sportComment': _sportCommentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Reseña enviada con éxito!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar reseña: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarSelector(int rating, Function(int) onRatingChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFE2B714),
              size: 22,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // TARJETA 1: DESEMPEÑO DEL PROFESOR
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Desempeño del Profesor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2C59)),
                    ),
                    _buildStarSelector(_profesorRating, (val) => setState(() => _profesorRating = val)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.profesorNombre,
                  style: const TextStyle(color: Color(0xFF6C757D), fontSize: 11),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _profesorCommentController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Comentario opcional sobre el profesor...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFFF5500))),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),

          // TARJETA 2: DISCIPLINA / DEPORTE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Disciplina / Deporte',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2C59)),
                    ),
                    _buildStarSelector(_sportRating, (val) => setState(() => _sportRating = val)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.deporteNombre,
                  style: const TextStyle(color: Color(0xFF6C757D), fontSize: 11),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _sportCommentController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Comentario opcional sobre instalaciones o dinámica...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFFF5500))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BOTÓN NARANJA "ENVIAR RESEÑA"
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5500),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Enviar Reseña',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}