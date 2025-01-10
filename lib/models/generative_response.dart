import 'package:json_annotation/json_annotation.dart';

part 'generative_response.g.dart';

@JsonSerializable()
class GenerativeResponse {
  final List<Content> candidates;

  GenerativeResponse({required this.candidates});

  factory GenerativeResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerativeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerativeResponseToJson(this);
}

@JsonSerializable()
class Content {
  final Parts parts;

  Content({required this.parts});

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);

  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

@JsonSerializable()
class Parts {
  final String text;

  Parts({required this.text});

  factory Parts.fromJson(Map<String, dynamic> json) =>
      _$PartsFromJson(json);

  Map<String, dynamic> toJson() => _$PartsToJson(this);
}