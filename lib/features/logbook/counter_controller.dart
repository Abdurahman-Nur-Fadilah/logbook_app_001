import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 1;

  final String username;

  CounterController({required this.username});

  List<Map<String, dynamic>> log = []; 

  int get value => _counter; 

  void setstep(int newStep) => _step = newStep; 
  
  Future<void> increment() async {
    int oldCounter = _counter;
    _counter = _counter + _step;

    await saveLastValue(_counter);
  
    addToLog("Tambahan dari $oldCounter ke $_counter sebanyak $_step", Colors.green);
  }

  Future<void> decrement() async {
    int oldCounter = _counter;
    if (_counter - _step < 0) {
      _step = _counter;

      addToLog("Pengurangan tidak bisa dilakukan karena nilai negatif, mengatur step menjadi $_step", Colors.red);
    }
    _counter = _counter - _step;

    await saveLastValue(_counter);

    addToLog("Pengurangan dari $oldCounter ke $_counter sebanyak $_step", Colors.red);
  }

  Future<void> reset() async{
    int oldCounter = _counter;
    _counter = 0;

    await saveLastValue(_counter);

    addToLog("Reset dari $oldCounter ke $_counter", Colors.black);
  }

  void addToLog(String message, Color color) {
    String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    log.insert(0, {
      'message': '$timestamp - $username: $message',
       'color': color});
    
    if (log.length > 5) {
      log.removeLast();
    } 
  }

  Future<void> saveLastValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_counter', value); 
    // 'last_counter' adalah Kunci (Key) untuk memanggil data nanti
  }

  Future<void> loadLastValue() async {
  final prefs = await SharedPreferences.getInstance();
  // Ambil nilai berdasarkan Key, jika kosong (null) berikan nilai default 0
  _counter = prefs.getInt('last_counter') ?? 0;
  }

}
