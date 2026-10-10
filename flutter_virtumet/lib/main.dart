import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VirtuMet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // AQUÍ CAMBIAS EL "home" POR TU PROPIA PANTALLA PRINCIPAL
      home: const HomeScreen(), 
    );
  }
}



// Ejemplo de tu propia pantalla principal (puedes moverla a su propio archivo en la carpeta lib/)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VirtuMet'),
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido a VirtuMet!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
