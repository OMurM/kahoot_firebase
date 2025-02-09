// screens/join_panel.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_question.dart'; // Ensure this is imported

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _quizCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  bool _isLoading = false;
  final bool _isGameStarted = false;

  Future<void> joinQuiz() async {
    final quizCode = _quizCodeController.text.trim().toUpperCase();
    final playerName = _playerNameController.text.trim();

    if (quizCode.isEmpty || playerName.isEmpty) {
      showError('Please enter both quiz code and name');
      return;
    }

    if (quizCode.length != 4) {
      showError('Quiz code must be 4 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roomResponse = await Supabase.instance.client
          .from('rooms')
          .select('is_game_started')
          .eq('room_code', quizCode)
          .single();

      if (roomResponse.isEmpty) {
        showError('Invalid quiz code');
        return;
      }

      final existingPlayers = await Supabase.instance.client
          .from('participants')
          .select()
          .eq('room_code', quizCode)
          .eq('participant_name', playerName);

      if (existingPlayers.isNotEmpty) {
        showError('Name already taken in this quiz');
        return;
      }

      await Supabase.instance.client.from('participants').insert({
        'room_code': quizCode,
        'participant_name': playerName,
      });

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizQuestionScreen(
            roomCode: quizCode,
            isHost: false,
            playerName: playerName,
            isGameStarted: _isGameStarted,
          ),
        ),
      );

    } on PostgrestException catch (e) {
      showError('Quiz error: ${e.message}');
    } catch (error) {
      showError('Connection error: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _quizCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Quiz Code',
                hintText: '4-digit code',
              ),
              maxLength: 4,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(
                labelText: 'Enter Your Name',
                hintText: 'Max 15 characters',
              ),
              maxLength: 15,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: joinQuiz,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Join Quiz',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
