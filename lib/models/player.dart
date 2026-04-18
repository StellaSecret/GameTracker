// lib/models/player.dart
import 'package:uuid/uuid.dart';

class Player {
  final String id;
  final String name;
  final String color; // hex string e.g. '#FF5252'
  final DateTime createdAt;

  Player({
    String? id,
    required this.name,
    this.color = '#6C63FF',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as String? ?? '#6C63FF',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Player copyWith({String? name, String? color}) => Player(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
