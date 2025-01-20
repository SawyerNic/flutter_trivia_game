import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<dynamic> readData(String key) async {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final DataSnapshot snapshot = await dbRef.child(key).get();
  if (snapshot.exists) {
    return snapshot.value;
  }
  return null;
}

Future<void> writeData(String key, dynamic value) async {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  await dbRef.child(key).set(value);
}
