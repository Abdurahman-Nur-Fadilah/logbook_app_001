import 'package:flutter/material.dart';

class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int _step = 1;

  List<Map<String, dynamic>> log = []; 

  int get value => _counter; 
  void setstep(int newStep) => _step = newStep; 
  void increment() {
    int oldCounter = _counter;
    _counter = _counter + _step;

    String time = DateTime.now().toString();
    addToLog("[$time] Tambahan dari $oldCounter ke $_counter sebanyak $_step", Colors.green);
  }
  void decrement() {
    int oldCounter = _counter;
    if (_counter - _step < 0) {
      _step = _counter;
      String time = DateTime.now().toString();
      addToLog("[$time] Pengurangan tidak bisa dilakukan karena nilai negatif, mengatur step menjadi $_step", Colors.red);
    }
    _counter = _counter - _step;

    String time = DateTime.now().toString();
    addToLog("[$time] Pengurangan dari $oldCounter ke $_counter sebanyak $_step", Colors.red);
  }
  void reset() {
    int oldCounter = _counter;
    _counter = 0;

    String time = DateTime.now().toString();
    addToLog("[$time] Reset dari $oldCounter ke $_counter", Colors.black);
  }

  void addToLog(String message, Color color) {
    log.insert(0, {'message': message, 'color': color});
    
    if (log.length > 5) {
      log.removeLast();
    } 
  }
}
