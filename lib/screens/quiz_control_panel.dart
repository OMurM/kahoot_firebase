// screens/quiz_control_panel.dart
// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_question.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  _HostScreenState createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  String? quizCode;
  List<Map<String, dynamic>> participants = [];
  bool isGameStarted = false;

  Future<void> _startQuiz() async {
    if (quizCode != null) {
      print("Quiz code already exists: $quizCode");
      return;
    }

    var uuid = Uuid();
    String code = uuid.v4().substring(0, 4).toUpperCase();

    setState(() {
      quizCode = code;
    });

    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .insert({'room_code': code, 'is_game_started': false})
          .select();

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to insert quiz code')),
          );
        }
        return;
      }

      _listenForParticipants();
    } catch (error) {
      print("Error inserting data: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting data: $error')),
        );
      }
    }
  }

  void _listenForParticipants() {
    if (quizCode == null) return;

    Supabase.instance.client
        .from('participants')
        .stream(primaryKey: ['id'])
        .eq('room_code', quizCode!)
        .listen((data) {
      if (mounted) {
        setState(() {
          participants = data;
        });
      }
    });
  }

  Future<void> _startGame() async {
    if (quizCode == null || participants.isEmpty || isGameStarted) return;

    try {
      print("Starting the game for room code: $quizCode");

      final response = await Supabase.instance.client
          .from('rooms')
          .update({'is_game_started': true})
          .eq('room_code', quizCode!)
          .select();

      if (response.isEmpty) {
        print("No response or empty response.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start game: No response')),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          isGameStarted = true;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizQuestionScreen(
              roomCode: quizCode!,
              isHost: true,
              playerName: 'Host',
              isGameStarted: true,
            ),
          ),
        );

        print("Navigating to QuizQuestionScreen");
      }
    } catch (error) {
      print("Error starting the game: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting the game: $error')),
        );
      }
    }
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
              child: const Text('Generate Quiz Code'),
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
              SizedBox(
                height: 200,
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
                onPressed: participants.isNotEmpty && !isGameStarted
                    ? () {
                        print('Starting the game');
                        _startGame();
                      }
                    : null,
                child: const Text('Start Game'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
