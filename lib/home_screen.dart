import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final String repositoryUrl = 'https://github.com/C-Chanona/gemini-chatbot';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la Universidad
            Image.asset('assets/logo_up.png', // Asegúrate de tener este archivo en tu carpeta assets
                height: 100),

            const SizedBox(height: 20),

            // Información de la carrera, materia, grupo, etc.
            const Text(
              'Ingeniería en Software',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Materia: Programacion para Móviles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              '9-B',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Carlos Eduardo Chanona Aquino',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              '221233',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Enlace al repositorio
            ElevatedButton(
              onPressed: () async {
                if (await canLaunch(repositoryUrl)) {
                  await launch(repositoryUrl);
                } else {
                  throw 'No se pudo abrir el enlace $repositoryUrl';
                }
              },
              child: const Text('Ver Repositorio del Proyecto'),
            ),
          ],
        ),
      ),
    );
  }
}
