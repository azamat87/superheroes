import 'package:json_annotation/json_annotation.dart';

part 'powerstats.g.dart';

@JsonSerializable(explicitToJson: true)
class Powerstats {
  final String intelligence;
  final String strength;
  final String speed;
  final String durability;
  final String power;
  final String combat;

  Powerstats(
      {required this.intelligence,
      required this.strength,
      required this.speed,
      required this.durability,
      required this.power,
      required this.combat});

  bool isNotNull() {
    return intelligence != "null" &&
        strength != "null" &&
        speed != "null" &&
        durability != "null" &&
        power != "null" &&
        combat != "null";
  }

  double get intelligencePercent => convertStringToValue(intelligence);

  double get strengthPercent => convertStringToValue(strength);

  double get speedPercent => convertStringToValue(speed);

  double get durabilityPercent => convertStringToValue(durability);

  double get powerPercent => convertStringToValue(power);

  double get combatPercent => convertStringToValue(combat);

  double convertStringToValue(final String value) {
    final intValue = int.tryParse(value);
    if (intValue == null) return 0;
    return intValue/100;
  }

  factory Powerstats.fromJson(Map<String, dynamic> json) =>
      _$PowerstatsFromJson(json);

  Map<String, dynamic> toJson() => _$PowerstatsToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Powerstats &&
          runtimeType == other.runtimeType &&
          intelligence == other.intelligence &&
          strength == other.strength &&
          speed == other.speed &&
          durability == other.durability &&
          power == other.power &&
          combat == other.combat;

  @override
  int get hashCode =>
      intelligence.hashCode ^
      strength.hashCode ^
      speed.hashCode ^
      durability.hashCode ^
      power.hashCode ^
      combat.hashCode;

  @override
  String toString() {
    return 'Powerstats{intelligence: $intelligence, strength: $strength, speed: $speed, durability: $durability, power: $power, combat: $combat}';
  }
}
