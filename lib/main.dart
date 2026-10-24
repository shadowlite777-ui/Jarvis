import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  String _lastWords = 'Нажмите микрофон и скажите: "Джарвис, привет"';
  String _selectedLocaleId = 'ru_RU';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  // Настройка голоса «Джарвиса»
  void _initTts() async {
    _flutterTts = FlutterTts();
    
    // Пытаемся найти русский язык для синтеза
    await _flutterTts.setLanguage("ru-RU");
    
    // Тон Джарвиса: делаем голос глуше и солиднее (норма 1.0, ниже — грубее)
    await _flutterTts.setPitch(0.68); 
    // Четкий, размеренный темп речи
    await _flutterTts.setSpeechRate(0.52);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Инициализация слуха с автоопределением русской локали
  void _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('onStatus: $val'),
      onError: (val) => debugPrint('onError: $val'),
    );
    
    if (available) {
      var locales = await _speech.locales();
      // Ищем локаль, содержащую 'ru' (например ru_RU или ru-RU)
      var russians = locales.where((l) => l.localeId.toLowerCase().contains('ru')).toList();
      if (russians.isNotEmpty) {
        setState(() {
          _selectedLocaleId = russians.first.localeId;
        });
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: _selectedLocaleId,
          onResult: (val) => setState(() {
            _lastWords = val.recognizedWords;
            if (val.finalResult && _lastWords.isNotEmpty) {
              _isListening = false;
              _processCommand(_lastWords);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Обработка команд в стиле Джарвиса
  void _processCommand(String command) {
    String lowerCmd = command.toLowerCase();
    if (lowerCmd.contains('привет') || lowerCmd.contains('джарвис')) {
      _speak("Сэр, системы функционируют нормально. Чем могу помочь?");
    } else if (lowerCmd.contains('статус') || lowerCmd.contains('как дела')) {
      _speak("Все подсистемы активны, сэр. Ядро работает в штатном режиме.");
    } else {
      _speak("Команда принята, сэр. Распознано: $command");
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
        title: const Text('Jarvis Core System'),
        backgroundColor: const Color(0xFF111111),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Идентификация речи (RU)',
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
                child: Text(
                  _lastWords,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 30),
              FloatingActionButton(
                onPressed: _listen,
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
