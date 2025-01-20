import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Player {
  String name;
  String imageLink;
  String? position;
  double yards;
  dynamic stats;

  Player(this.name, this.imageLink, this.yards);
}

class Team {
  String name;
  int id;
  Player qbOne;
  Player rbOne;
  Player wrOne;

  Team(this.name, this.id, this.qbOne, this.rbOne, this.wrOne);
}

Future<Object> fetchWholeNFLTeam(int teamID) async {
  late Object data;

  final url = Uri.parse(
      'https://tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com/getNFLTeamRoster?teamID=$teamID&getStats=true&fantasyPoints=false');

  try {
    final response = await http.get(
      url,
      headers: {
        'x-rapidapi-key': '56d5b89f7cmsh1e2b0558e2661dep12b85fjsn71c203c534c4',
        'x-rapidapi-host':
            'tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Request failed with status: ${response.statusCode}');
      throw Exception('Failed to fetch team data');
    }
  } catch (e) {
    throw Exception('Error occurred: $e');
  }
}

class playerCollection {
  late final DateTime currentTime;
  final List players;

  playerCollection(this.currentTime, this.players);
}

Future updatePlayerDb() async {
  playerCollection newCollection = playerCollection(DateTime.now(), []);

  for (int i = 1; i <= 32; i++) {}
}

Future<Team> fetchNFLTeam(int teamID) async {
  final data;

  // Define the API endpoint
  final url = Uri.parse(
      'https://tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com/getNFLTeamRoster?teamID=$teamID&getStats=true&fantasyPoints=false');

  try {
    // Make the GET request with headers
    final response = await http.get(
      url,
      headers: {
        'x-rapidapi-key': '56d5b89f7cmsh1e2b0558e2661dep12b85fjsn71c203c534c4',
        'x-rapidapi-host':
            'tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com',
      },
    );

    Player playerZero = Player(
        'zero', 'https://i.ytimg.com/vi/6R1bYmNLwxs/maxresdefault.jpg', 0);

    //CREATE THE TEAM OBJECT THAT WE WILL BE ADDING PLAYERS TO (the first string qb, wr and rb)
    Team bestBallers =
        Team('Mikeys Dog House', teamID, playerZero, playerZero, playerZero);

    // Check if request is successful (status code 200)
    if (response.statusCode == 200) {
      // decode into an object
      data = jsonDecode(response.body);

      bestBallers.name = data['body']['team'];

      //LOOP THROUGH THE ROSTER
      for (final teammate in data['body']['roster']) {
        //check the position of each player -- we are going to filter them into a team object

        // Check if the required fields are not null
        final position = teammate['pos'];
        final dynamic recYds = teammate['stats']?['Receiving']?['recYds'];
        final dynamic passYds = teammate['stats']?['Passing']?['passYds'];
        final dynamic rushYds = teammate['stats']?['Rushing']?['rushYds'];

        Player candidate =
            Player(teammate['espnName'], teammate['espnHeadshot'], 0);

        // check if the teammate is an active wr
        if (position == 'WR' && recYds != null) {
          candidate.yards = double.tryParse(recYds)!;

          if (candidate.yards > bestBallers.wrOne.yards) {
            bestBallers.wrOne = candidate;
          }

          continue;
        } else if (position == 'QB' && passYds != null) {
          candidate.yards = double.tryParse(passYds)!;

          if (candidate.yards > bestBallers.qbOne.yards) {
            bestBallers.qbOne = candidate;
          }

          continue;
        } else if (position == 'RB' && rushYds != null) {
          candidate.yards = double.tryParse(rushYds)!;

          if (candidate.yards > bestBallers.rbOne.yards) {
            bestBallers.rbOne = candidate;
          }
        }
      }

      print(bestBallers.wrOne.name);
      print(bestBallers.qbOne.name);
      print(bestBallers.rbOne.name);

// equivalent to console.log(this.responseText)
    } else {
      print('Request failed with status: ${response.statusCode}');
    }

    return bestBallers;
  } catch (e) {
    print('Error occurred: $e');
    throw Error;
  }
}

Future<dynamic> updatePlayerList() async {
  for (int i = 0; i < 33; i++) {
    final url = Uri.parse(
        'https://tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com/getNFLTeamRoster?teamID=$i&getStats=true&fantasyPoints=false');

    try {
      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-key':
              '56d5b89f7cmsh1e2b0558e2661dep12b85fjsn71c203c534c4',
          'x-rapidapi-host':
              'tank01-nfl-live-in-game-real-time-statistics-nfl.p.rapidapi.com',
        },
      );
    } catch (e) {
      print('Error occured: $e');
    }
  }
}

class Option {
  Player player;
  bool correct;

  Option(this.player, this.correct);
}

class Question {
  String text;
  List options;

  Question(this.text, this.options);
}

List<int> getRandomNumbers(int count, int min, int max) {
  if (count > (max - min + 1)) {
    throw ArgumentError('Count cannot be greater than the range of numbers.');
  }

  final random = Random();
  final numbers = <int>{};

  while (numbers.length < count) {
    numbers.add(random.nextInt(max - min + 1) + min);
  }

  return numbers.toList();
}

Future<List<Question>> generateQuestions() async {
  final randomNumbers = getRandomNumbers(4, 1, 32);
  Question qbQuestion = Question('Which QB has the most passing yards?', []);
  Question rbQuestion = Question('Which RB has the most rushing yards?', []);
  Question wrQuestion = Question('Which WR has the most receiving yards?', []);

  for (int i in randomNumbers) {
    Team team = await fetchNFLTeam(i);

    qbQuestion.options.add(Option(team.qbOne, false));
    rbQuestion.options.add(Option(team.rbOne, false));
    wrQuestion.options.add(Option(team.wrOne, false));
  }

  void setCorrectOption(Question question) {
    Option? correctOption;
    for (var option in question.options) {
      if (correctOption == null ||
          option.player.yards > correctOption.player.yards) {
        correctOption = option;
      }
    }
    if (correctOption != null) {
      correctOption.correct = true;
    }
  }

  setCorrectOption(qbQuestion);
  setCorrectOption(rbQuestion);
  setCorrectOption(wrQuestion);

  print(randomNumbers);

  return [qbQuestion, rbQuestion, wrQuestion];
}

void main() async {
  dynamic testTeam = await fetchWholeNFLTeam(
      3); // Ensure fetchWholeNFLTeam is awaited if it's asynchronous
  print(jsonEncode(testTeam)); // Print the parsed JSON data
}
