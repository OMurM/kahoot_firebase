import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizQuestionScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final bool isHost;
  final bool isGameStarted;

  const QuizQuestionScreen({
    required this.roomCode,
    required this.playerName,
    required this.isHost,
    required this.isGameStarted,
    super.key,
  });

  @override
  _QuizQuestionScreenState createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  Map<String, dynamic>? _currentQuestion;
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _waitingForStart = true;  // Tracks if the player is waiting for the game to start

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _setupRealtime();
  }

  Future<void> _fetchQuestions() async {
    final response = await Supabase.instance.client
        .from('questions')
        .select()
        .order('created_at');

    if (mounted) {
      setState(() {
        _questions = response;
        _isLoading = false;
        if (_questions.isNotEmpty) {
          _currentQuestion = _questions[_currentQuestionIndex];
        }
      });
    }
  }

  void _setupRealtime() {
    // Listen for changes in the room status to check if the game has started
    Supabase.instance.client
        .from('rooms')
        .stream(primaryKey: ['room_code'])
        .eq('room_code', widget.roomCode)
        .listen((data) {
      if (data.isNotEmpty && data[0]['is_started'] == true) {
        // Game has started, stop waiting and start the quiz
        setState(() {
          _waitingForStart = false;
          _currentQuestionIndex = 0;
          _currentQuestion = _questions[_currentQuestionIndex];
        });
      }
    });
  }

  Future<void> _updateCurrentQuestion(int index) async {
    await Supabase.instance.client
        .from('rooms')
        .update({'current_question': index})
        .eq('room_code', widget.roomCode);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex];
      });
      if (widget.isHost) {
        _updateCurrentQuestion(_currentQuestionIndex);
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _currentQuestion = _questions[_currentQuestionIndex];
      });
      if (widget.isHost) {
        _updateCurrentQuestion(_currentQuestionIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    if (_waitingForStart && !widget.isHost) {
      // Non-host players wait for the game to start
      return Scaffold(
        appBar: AppBar(title: const Text('Waiting for Host to Start the Game')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Waiting for the host to start the game...",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Host view doesn't show the waiting state, they directly start the quiz
    if (widget.isHost && _waitingForStart) {
      // If the host hasn't started, show the option to start the game
      return Scaffold(
        appBar: AppBar(title: const Text('Host: Start the Game')),
        body: Center(
          child: ElevatedButton(
            onPressed: _startGame,
            child: const Text('Start Game'),
          ),
        ),
      );
    }

    // Game started, show the quiz question
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Question')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display only question label, no options yet
            Text(
              widget.isHost ? 'Question ${_currentQuestionIndex + 1}' : 'Answer the Question',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // Show only option labels: A, B, C, D
            _buildOption('A'),
            _buildOption('B'),
            _buildOption('C'),
            _buildOption('D'),
            if (widget.isHost) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _previousQuestion,
                    child: const Text('Previous Question'),
                  ),
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text('Next Question'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String optionLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        onPressed: () => _handleAnswer(optionLabel),
        child: Text(optionLabel),
      ),
    );
  }

  void _handleAnswer(String selectedOption) async {
    if (widget.isHost) return;

    try {
      await Supabase.instance.client.from('answers').insert({
        'room_code': widget.roomCode,
        'question_id': _currentQuestion?['id'],
        'participant_name': widget.playerName,
        'selected_option': selectedOption,
        'is_correct': selectedOption == _currentQuestion?['correct_option'],
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting answer: $error')),
      );
    }
  }

  void _startGame() async {
    await Supabase.instance.client
        .from('rooms')
        .update({'is_started': true})
        .eq('room_code', widget.roomCode);

    setState(() {
      _waitingForStart = false;
    });
  }
}
