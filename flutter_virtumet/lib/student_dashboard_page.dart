import 'package:flutter/material.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Estudiante - VirtuMet'),
        backgroundColor: const Color(0xFFFF5500),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido al Panel de Estudiantes!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}