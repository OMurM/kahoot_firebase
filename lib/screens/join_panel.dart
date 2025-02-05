// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _quizCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> joinQuiz() async {
    final quizCode = _quizCodeController.text.trim();
    final playerName = _playerNameController.text.trim();

    if (quizCode.isEmpty || playerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both quiz code and name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.from('participants').insert({
        'room_code': quizCode,
        'participant_name': playerName,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined quiz')),
      );
      
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining quiz: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              decoration: const InputDecoration(labelText: 'Enter Quiz Code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _playerNameController,
              decoration: const InputDecoration(labelText: 'Enter Your Name'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: joinQuiz,
                    child: const Text('Join Quiz'),
                  ),
          ],
        ),
      ),
    );
  }
}
