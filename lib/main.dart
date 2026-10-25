import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primaryColor: Colors.orange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.example.jarvis/service');

  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isThinking = false;
  String _lastWords = 'Нажмите микрофон и отдайте приказ, сэр.';

  // Настройки DeepSeek API
  final String _apiKey = "sk-4439b4053b054e0b8aa2f60c72a9b095"; 
  final String _apiUrl = "https://api.deepseek.com/chat/completions";

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setPitch(0.68); // Глубокий, солидный тон
    await _flutterTts.setSpeechRate(0.52);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.finalResult && _lastWords.isNotEmpty) {
              _isListening = false;
              _processCommandWithLLM(_lastWords);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Запрос к DeepSeek API
  Future<void> _processCommandWithLLM(String command) async {
    setState(() {
      _isThinking = true;
      _lastWords = "Запрос: \"$command\"\n[DeepSeek думает...]";
    });

    if (_apiKey == "YOUR_DEEPSEEK_API_KEY_HERE") {
      setState(() {
        _isThinking = false;
      });
      _speak("Сэр, не указан API-ключ DeepSeek. Введите его в настройках кода.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "deepseek-chat", // Основная языковая модель DeepSeek (V3)
          "messages": [
            {
              "role": "system",
              "content": "You are JARVIS, an elite AI assistant. Respond in Russian. Be extremely concise, composed, loyal, and address the user as 'сэр' (sir). Keep responses short, suitable for voice playback (max 1-2 sentences)."
            },
            {
              "role": "user",
              "content": command
            }
          ],
          "max_tokens": 100,
          "stream": false
        }),
      );

      setState(() {
        _isThinking = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String answer = data['choices'][0]['message']['content'].trim();
        
        setState(() {
          _lastWords = answer;
        });
        
        _speak(answer);
      } else {
        debugPrint("API Error: ${response.body}");
        _speak("Сэр, ошибка ответа сервера DeepSeek.");
      }
    } catch (e) {
      setState(() {
        _isThinking = false;
      });
      _speak("Сэр, сбой выполнения системного запроса.");
      debugPrint("DeepSeek Error: $e");
    }
  }

  Future<void> _startService() async {
    try {
      await platform.invokeMethod('startService');
      _speak("Фоновый протокол активирован, сэр.");
    } on PlatformException catch (e) {
      debugPrint("Failed to start service: '${e.message}'.");
    }
  }

  Future<void> _stopService() async {
    try {
      await platform.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugPrint("Failed to stop service: '${e.message}'.");
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await platform.invokeMethod('requestBatteryOptimization');
    } on PlatformException catch (e) {
      debugPrint("Failed to request battery opt: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jarvis Core (DeepSeek)'),
        backgroundColor: const Color(0xFF111111),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Нейроядро: DeepSeek',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: _isThinking
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : Text(
                        _lastWords,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
              ),
              const SizedBox(height: 30),
              FloatingActionButton(
                onPressed: _isThinking ? null : _listen,
                backgroundColor: Colors.orange,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _startService,
                  child: const Text('Запустить фоновый сервис'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _stopService,
                  child: const Text('Остановить сервис'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _requestBatteryOptimization,
                  child: const Text('Исключить из оптимизации батареи'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
