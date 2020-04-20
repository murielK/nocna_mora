// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Voice _$VoiceFromJson(Map<String, dynamic> json) {
  return Voice(json['name'], json['description'], json['file']);
}

Map<String, dynamic> _$VoiceToJson(Voice instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'file': instance.file
    };
