import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: GameWindow(),
        ),
      ),
    );
  }
}

class GameWindow extends StatefulWidget {
  const GameWindow({super.key});

  @override
  State<GameWindow> createState() => _GameWindowState();
}

class _GameWindowState extends State<GameWindow> {
  var answers = [true, false, false, false];
  bool wrong = false;
  final CountDownController _controller = CountDownController();

  @override
  Widget build(BuildContext context) {
    if (wrong) {
      return Column(
        children: [
          const Text("Game Over"),
          ElevatedButton(
              onPressed: () => {
                    setState(() {
                      wrong = false;
                    })
                  },
              child: const Text("restart"))
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularCountDownTimer(
              duration: 10,
              initialDuration: 0,
              controller: _controller,
              width: 30,
              height: 30,
              ringColor: Colors.grey[300]!,
              ringGradient: null,
              fillColor: Colors.purpleAccent[100]!,
              fillGradient: null,
              backgroundColor: Colors.purple[500],
              backgroundGradient: null,
              strokeWidth: 8.0,
              strokeCap: StrokeCap.round,
              textStyle: const TextStyle(
                  fontSize: 10.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              textFormat: CountdownTextFormat.S,
              isReverse: true,
              isReverseAnimation: true,
              isTimerTextShown: true,
              autoStart: true,
              onStart: () {
                debugPrint('Countdown Started');
              },
              onComplete: () {
                setState(() {
                  wrong = true;
                });
              },
              onChange: (String timeStamp) {},
              timeFormatterFunction: (defaultFormatterFunction, duration) {
                if (duration.inSeconds == 0) {
                  return "0";
                } else {
                  return Function.apply(defaultFormatterFunction, [duration]);
                }
              },
            ),
          ),
          Expanded(
            child: GridView.count(
                crossAxisCount: 2,
                children: List.generate(4, (index) {
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => {
                        if (answers[index] == true)
                          {
                            setState(() {
                              answers.shuffle();
                              _controller.restart();
                            }),
                          }
                        else
                          {
                            setState(() {
                              wrong = true;
                            })
                          }
                      },
                      child: Text(answers[index].toString()),
                    ),
                  );
                })),
          ),
        ],
      );
    }
  }
}
