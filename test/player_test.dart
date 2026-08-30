// player.dart was only reached indirectly through widget_test.dart; these put
// its serialization and copy logic into mutation scope.
// Run with: flutter test test/player_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:game_tracker/models/player.dart';

void main() {
  test('toJson/fromJson round-trips all fields', () {
    final p = Player(
      id: 'p1',
      name: 'Alice',
      color: '#FF5252',
      createdAt: DateTime(2024, 5, 6),
    );
    final restored = Player.fromJson(p.toJson());
    expect(restored.id, 'p1');
    expect(restored.name, 'Alice');
    expect(restored.color, '#FF5252');
    expect(restored.createdAt, DateTime(2024, 5, 6));
  });

  test('fromJson applies the default color when absent', () {
    final p = Player.fromJson({
      'id': 'p2',
      'name': 'Bob',
      'createdAt': '2024-01-01T00:00:00.000',
    });
    expect(p.color, '#6C63FF');
  });

  test('copyWith updates only the requested fields', () {
    final p = Player(
      id: 'p3',
      name: 'Carol',
      color: '#00FF00',
      createdAt: DateTime(2024, 2, 2),
    );
    final q = p.copyWith(name: 'Carl', color: '#0000FF');
    expect(q.id, 'p3');
    expect(q.createdAt, DateTime(2024, 2, 2));
    expect(q.name, 'Carl');
    expect(q.color, '#0000FF');
  });

  test('omitted constructor args get generated values', () {
    final before = DateTime.now().add(const Duration(seconds: 1));
    final p = Player(name: 'Dave');
    expect(p.id, isNotEmpty);
    expect(p.color, '#6C63FF');
    expect(p.createdAt.isBefore(before), isTrue);
  });
}