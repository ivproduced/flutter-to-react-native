// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TIMAChatInput _$TIMAChatInputFromJson(Map<String, dynamic> json) =>
    TIMAChatInput(
      sessionId: json['session_id'] as String,
      text: json['text'] as String?,
      action:
          json['action'] == null
              ? null
              : TIMAAction.fromJson(json['action'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TIMAChatInputToJson(TIMAChatInput instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'text': instance.text,
      'action': instance.action,
      'metadata': instance.metadata,
    };

TIMAChatOutput _$TIMAChatOutputFromJson(Map<String, dynamic> json) =>
    TIMAChatOutput(
      reply: json['reply'] as String,
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((e) => TIMAChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => TIMACitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      context: json['context'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$TIMAChatOutputToJson(TIMAChatOutput instance) =>
    <String, dynamic>{
      'reply': instance.reply,
      'choices': instance.choices,
      'citations': instance.citations,
      'context': instance.context,
    };

TIMAChatMessage _$TIMAChatMessageFromJson(Map<String, dynamic> json) =>
    TIMAChatMessage(
      id: json['id'] as String,
      type: $enumDecode(_$TIMAMessageTypeEnumMap, json['type']),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((e) => TIMAChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => TIMACitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TIMAChatMessageToJson(TIMAChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TIMAMessageTypeEnumMap[instance.type]!,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'choices': instance.choices,
      'citations': instance.citations,
      'metadata': instance.metadata,
    };

const _$TIMAMessageTypeEnumMap = {
  TIMAMessageType.user: 'user',
  TIMAMessageType.assistant: 'assistant',
  TIMAMessageType.system: 'system',
  TIMAMessageType.error: 'error',
};

TIMAChatSession _$TIMAChatSessionFromJson(Map<String, dynamic> json) =>
    TIMAChatSession(
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => TIMAChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      state:
          json['state'] == null
              ? null
              : TIMASessionState.fromJson(
                json['state'] as Map<String, dynamic>,
              ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$TIMAChatSessionToJson(TIMAChatSession instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'title': instance.title,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'messages': instance.messages,
      'state': instance.state,
      'metadata': instance.metadata,
      'is_active': instance.isActive,
    };
