// models/counter_model.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';

class CounterModel extends ChangeNotifier {
  int _count;
  String _name;

  // Default constructor
  CounterModel({int count = 0, String name = "Default Counter"})
    : _count = count,
      _name = name;

  int get count => _count;
  String get name => _name;

  void increment() {
    _count++;
    notifyListeners(); // Notify all listeners about the state change
  }

  void setName(String newName) {
    _name = newName;
    notifyListeners(); // Notify all listeners about the state change
  }

  Map<String, dynamic> toMap() {
    return {'count': _count, 'name': _name};
  }

  factory CounterModel.fromMap(Map<String, dynamic> map) {
    return CounterModel(
      count: map['count'] ?? 0,
      name: map['name'] ?? "Default Counter",
    );
  }

  String toJson() => json.encode(toMap());

  factory CounterModel.fromJson(String source) =>
      CounterModel.fromMap(json.decode(source));
}
