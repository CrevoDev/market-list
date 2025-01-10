// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generative_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerativeResponse _$GenerativeResponseFromJson(Map<String, dynamic> json) =>
    GenerativeResponse(
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => Content.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GenerativeResponseToJson(GenerativeResponse instance) =>
    <String, dynamic>{
      'candidates': instance.candidates,
    };

Content _$ContentFromJson(Map<String, dynamic> json) => Content(
      parts: Parts.fromJson(json['parts'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
      'parts': instance.parts,
    };

Parts _$PartsFromJson(Map<String, dynamic> json) => Parts(
      text: json['text'] as String,
    );

Map<String, dynamic> _$PartsToJson(Parts instance) => <String, dynamic>{
      'text': instance.text,
    };
