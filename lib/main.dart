import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/services.dart';
import 'package:i_know_ball/utilities/firebase.dart';
import 'utilities/nflapi.dart';
import 'utilities/timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

// MainApp is the root widget of the application
class _MainAppState extends State<MainApp> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final now = DateTime.now();
  bool isLoading = true;

  late String dbDate;

  Future<void> loadDb() async {
    dbDate = await readData('lastUpdate');
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadDb();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Update the player info in the database here if it has been long enough
    print(now);
    print(DateTime.parse(dbDate));
    print(now.difference(DateTime.parse(dbDate)).inDays);

    //DateTime lastUpdate = DateTime.parse(dbDate.toString());

    //print(now.difference(lastUpdate));

    return FutureBuilder(
      future: readData('test'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          print('snapshot data: ${snapshot.data}');

          return MaterialApp(
            title: 'Baller App',
            theme: ThemeData(
              fontFamily: 'CustomFont', // Set the default font family
              primaryColorLight: Colors.blue,
              primaryColor: Colors.blue, // Set the primary color to blue
            ),
            initialRoute: '/',
            debugShowCheckedModeBanner: false, // Remove the debug banner
            routes: {
              '/': (context) => const HomeScreen(),
              '/gameScreen': (context) => const GameScreen(),
            },
          );
        } else {
          return const MainScaffold(
            body: Center(
              child: Text('No data available'),
            ),
          );
        }
      },
    );
  }
}

// MainScaffold is a reusable scaffold widget with an AppBar
class MainScaffold extends StatelessWidget {
  final Widget body;

  const MainScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I know Ball'),
        backgroundColor: Colors.blueAccent,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.sports_football, color: Colors.white),
          )
        ],
      ),
      body: body,
    );
  }
}

// HomeScreen is the initial screen of the app
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 200,
              child: Text(
                'I Know Ball is a simple trivia game in which the only goal is to get the answer right. But be quick! You only have ten seconds before time runs out. Good luck!',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/gameScreen');
              },
              child: const Text("Play"),
            ),
          ],
        ),
      ),
    );
  }
}

// GameScreen is the main game screen where the trivia game is played
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameWindowState();
}

class _GameWindowState extends State<GameScreen> {
  var answers = [true, false, false, false];
  bool wrong = false;
  final CountDownController _controller = CountDownController();
  List<Question>? questions;
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // Load initial questions when the screen is initialized
  }

  // Load initial questions
  Future<void> _loadQuestions() async {
    questions = await generateQuestions();
    setState(() {});
  }

  // Add more questions to the existing list
  Future<void> addQuestions() async {
    List<Question> newQuestions = await generateQuestions();
    setState(() {
      questions!.addAll(newQuestions);
    });
  }

  // Set the wrong flag to true
  void changeWrong() {
    setState(() {
      wrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while questions are being loaded
    if (questions == null || questions!.isEmpty) {
      _loadQuestions();
      return const Center(child: CircularProgressIndicator());
    } else if (questions!.length == 1) {
      addQuestions(); // Add more questions when only one question is left
    }

    // Show the game over screen if the wrong flag is set
    if (wrong) {
      // Set high score
      if (score > highScore) {
        highScore = score;
      }
      // Reset score
      score = 0;

      // GAME OVER SCREEN
      return MainScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Game Over"),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    wrong = false;
                  });
                },
                child: const Text("Restart"),
              ),
            ],
          ),
        ),
      );
    } else {
      // ACTIVE GAME WINDOW
      return MainScaffold(
        body: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 60, height: 30, child: Text("Score: $score")),
                SizedBox(
                  width: 100,
                  height: 30,
                  child: Timer(
                    controller: _controller,
                    whenExpired: changeWrong,
                  ),
                ),
                SizedBox(
                    width: 100,
                    height: 30,
                    child: Text("High Score: $highScore")),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(questions![0].text),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: List.generate(4, (index) {
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        if (questions![0].options[index].correct == true) {
                          questions!.removeAt(0);
                          score += 1;
                          setState(() {
                            _controller.restart();
                          });
                        } else {
                          setState(() {
                            wrong = true;
                          });
                        }
                      },
                      child: Text(questions![0].options[index].player.name +
                          '\n hint: ' +
                          questions![0].options[index].correct.toString()),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    }
  }
}
