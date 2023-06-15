
import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_colors.dart';

class AlignmentInfo {

  final String name;
  final Color color;

  const AlignmentInfo._(this.name, this.color);

  static const bad = AlignmentInfo._("bad", SuperheroesColors.red);
  static const good = AlignmentInfo._("good", SuperheroesColors.green);
  static const neutral = AlignmentInfo._("neutral", SuperheroesColors.grey);

  static AlignmentInfo? fromAlignment(String alignment) {
    if (alignment == "bad") {
      return bad;
    } else if (alignment == "good") {
      return good;
    } else if (alignment == "neutral") {
      return neutral;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlignmentInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          color == other.color;

  @override
  int get hashCode => name.hashCode ^ color.hashCode;


}