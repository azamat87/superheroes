import 'package:json_annotation/json_annotation.dart';

part 'server_image.g.dart';

@JsonSerializable(fieldRename: FieldRename.kebab)
class ServerImage {

  final String url;

  factory ServerImage.fromJson(Map<String, dynamic> json) => _$ServerImageFromJson(json);

  ServerImage(this.url);
  
  Map<String, dynamic> toJson() => _$ServerImageToJson(this);
}