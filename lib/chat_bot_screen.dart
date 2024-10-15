import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  late GenerativeModel _model;
  bool _isConnected = true;

  // Define el número máximo de mensajes a enviar como contexto
  static const int maxContextMessages = 10;

  @override
  void initState() {
    super.initState();
    // Inicializa el modelo con la API_KEY desde el .env
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: dotenv.env['API_KEY'] ?? '', // Cargar API_KEY del archivo .env
    );
    _loadMessages(); // Cargar mensajes guardados al iniciar
    _checkConnectivity(); // Verificar conectividad al iniciar
    Connectivity().onConnectivityChanged.listen((results) => _updateConnectivityStatus(results));
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    setState(() {
      _isConnected = results.isNotEmpty && results.first != ConnectivityResult.none;
    });
    print('Connectivity changed: $_isConnected');
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMessages = prefs.getString('chat_messages');
    if (savedMessages != null) {
      setState(() {
        messages = List<Map<String, String>>.from(
          json.decode(savedMessages).map(
                (item) => Map<String, String>.from(item),
          ),
        );
      });
      print('Mensajes cargados: $messages');
    } else {
      print('No hay mensajes guardados');
    }
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedMessages = json.encode(messages);
    await prefs.setString('chat_messages', encodedMessages);
    print('Mensajes guardados: $messages');
  }

  Future<void> sendMessage(String message) async {
    setState(() {
      messages.add({'user': message}); // Agrega el mensaje del usuario
    });
    _saveMessages(); // Guarda el historial actualizado

    try {
      // Prepara el contexto a enviar al modelo
      final List<Content> content = [];

      // Agrega los mensajes anteriores al contexto, respetando el límite
      int start = messages.length - maxContextMessages < 0
          ? 0
          : messages.length - maxContextMessages;
      for (int i = start; i < messages.length; i++) {
        final msg = messages[i];
        if (msg.containsKey('user')) {
          content.add(Content.text('Usuario: ${msg['user']}'));
        } else {
          content.add(Content.text('Bot: ${msg['bot']}'));
        }
      }

      // Agrega el mensaje actual del usuario
      content.add(Content.text('Usuario: $message'));

      // Genera una respuesta desde el modelo de Google Gemini
      final response = await _model.generateContent(content);

      setState(() {
        messages.add({'bot': response.text ?? 'No response available.'});
      });
      _saveMessages(); // Guarda el historial actualizado con la respuesta del bot
    } catch (error) {
      setState(() {
        messages.add({'bot': 'Error: No se pudo obtener una respuesta.'});
      });
      _saveMessages(); // Guarda el historial incluso si ocurre un error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini-Chatbot')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg.containsKey('user');
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.green : Colors.blue[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isUser ? msg['user']! : msg['bot']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribir mensaje...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isConnected
                      ? () {
                          if (_controller.text.isNotEmpty) {
                            sendMessage(_controller.text); // Envía el mensaje
                            _controller.clear(); // Limpia el campo de texto
                          }
                        }
                      : null, // Deshabilitar botón si no está conectado
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
