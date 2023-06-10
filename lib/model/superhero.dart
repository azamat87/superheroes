
import 'package:json_annotation/json_annotation.dart';
import 'package:superheroes/model/biography.dart';
import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/server_image.dart';

part 'superhero.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Superhero {
  final String id;
  final String name;
  final Biography biography;
  final ServerImage image;
  final Powerstats powerstats;

  factory Superhero.fromJson(Map<String, dynamic> json) => _$SuperheroFromJson(json);

  Superhero(this.id, this.name, this.biography, this.image, this.powerstats);

  Map<String, dynamic> toJson() => _$SuperheroToJson(this);
}
