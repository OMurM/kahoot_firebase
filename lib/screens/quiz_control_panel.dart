import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  String? quizCode;
  List<Map<String, dynamic>> participants = [];
  StreamSubscription? _participantsSubscription;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startQuiz() async {
    var uuid = Uuid();
    String code = uuid.v4().substring(0, 4).toUpperCase();

    setState(() {
      quizCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quiz Code generado: $quizCode')),
    );

    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .insert({'room_code': code})
          .select();

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo insertar el código en la DB')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código insertado correctamente')),
        );
        _listenForParticipants();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al insertar datos: $error')),
      );
    }
  }

  void _listenForParticipants() {
    if (quizCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: quizCode es null, no se puede escuchar participantes')),
      );
      return;
    }

    _participantsSubscription = Supabase.instance.client
        .from('participants')
        .stream(primaryKey: ['id'])
        .eq('room_code', quizCode!.trim().toUpperCase())
        .listen((data) {
      if (_gameStarted) {
        _participantsSubscription?.cancel();
        return;
      }

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron participantes')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Participantes actualizados: ${data.length}')),
        );
      }

      setState(() {
        participants = List.from(data);
      });
    });
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });

    _participantsSubscription?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz has started!')),
    );
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host Quiz')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quiz Control Panel',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startQuiz,
              child: const Text('Start Quiz'),
            ),
            const SizedBox(height: 20),
            if (quizCode != null) ...[
              const Text(
                'Quiz Code:',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                quizCode!,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Participants:',
                style: TextStyle(fontSize: 20),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(participants[index]['participant_name']),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: participants.isNotEmpty ? _startGame : null,
                child: const Text('Start Game'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
