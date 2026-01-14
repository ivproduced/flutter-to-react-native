// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tima_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TIMAAction _$TIMAActionFromJson(Map<String, dynamic> json) => TIMAAction(
  type: $enumDecode(_$ActionTypeEnumMap, json['type']),
  controlId: json['control_id'] as String?,
  docId: json['doc_id'] as String?,
  aspect: $enumDecodeNullable(_$AspectTypeEnumMap, json['aspect']),
  query: json['query'] as String?,
);

Map<String, dynamic> _$TIMAActionToJson(TIMAAction instance) =>
    <String, dynamic>{
      'type': _$ActionTypeEnumMap[instance.type]!,
      'control_id': instance.controlId,
      'doc_id': instance.docId,
      'aspect': _$AspectTypeEnumMap[instance.aspect],
      'query': instance.query,
    };

const _$ActionTypeEnumMap = {
  ActionType.controlSummary: 'CONTROL_SUMMARY',
  ActionType.deepen: 'DEEPEN',
  ActionType.assess: 'ASSESS',
  ActionType.tests: 'TESTS',
  ActionType.docSummary: 'DOC_SUMMARY',
  ActionType.search: 'SEARCH',
};

const _$AspectTypeEnumMap = {
  AspectType.plainEnglish: 'plain_english',
  AspectType.normative: 'normative',
};

TIMAChoice _$TIMAChoiceFromJson(Map<String, dynamic> json) => TIMAChoice(
  label: json['label'] as String,
  action: TIMAAction.fromJson(json['action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TIMAChoiceToJson(TIMAChoice instance) =>
    <String, dynamic>{'label': instance.label, 'action': instance.action};

TIMACitation _$TIMACitationFromJson(Map<String, dynamic> json) => TIMACitation(
  source: json['source'] as String,
  ref: json['ref'] as String,
  loc: json['loc'] as String?,
);

Map<String, dynamic> _$TIMACitationToJson(TIMACitation instance) =>
    <String, dynamic>{
      'source': instance.source,
      'ref': instance.ref,
      'loc': instance.loc,
    };

TIMAFocus _$TIMAFocusFromJson(Map<String, dynamic> json) =>
    TIMAFocus(kind: json['kind'] as String, id: json['id'] as String);

Map<String, dynamic> _$TIMAFocusToJson(TIMAFocus instance) => <String, dynamic>{
  'kind': instance.kind,
  'id': instance.id,
};

TIMATopicGeneration _$TIMATopicGenerationFromJson(Map<String, dynamic> json) =>
    TIMATopicGeneration(
      allowCrosslinks: json['allow_crosslinks'] as bool? ?? true,
    );

Map<String, dynamic> _$TIMATopicGenerationToJson(
  TIMATopicGeneration instance,
) => <String, dynamic>{'allow_crosslinks': instance.allowCrosslinks};

TIMASessionState _$TIMASessionStateFromJson(Map<String, dynamic> json) =>
    TIMASessionState(
      lastFocus:
          json['last_focus'] == null
              ? null
              : TIMAFocus.fromJson(json['last_focus'] as Map<String, dynamic>),
      breadcrumbs:
          (json['breadcrumbs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pendingChoices:
          (json['pending_choices'] as List<dynamic>?)
              ?.map((e) => TIMAChoice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      topicGeneration:
          json['topic_generation'] == null
              ? const TIMATopicGeneration()
              : TIMATopicGeneration.fromJson(
                json['topic_generation'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$TIMASessionStateToJson(TIMASessionState instance) =>
    <String, dynamic>{
      'last_focus': instance.lastFocus,
      'breadcrumbs': instance.breadcrumbs,
      'pending_choices': instance.pendingChoices,
      'topic_generation': instance.topicGeneration,
    };

TIMARouterDecision _$TIMARouterDecisionFromJson(Map<String, dynamic> json) =>
    TIMARouterDecision(
      intent: $enumDecode(_$RouterIntentEnumMap, json['intent']),
      controlId: json['control_id'] as String?,
      docId: json['doc_id'] as String?,
      aspect: $enumDecodeNullable(_$AspectTypeEnumMap, json['aspect']),
      query: json['query'] as String?,
      shouldSwitch: json['switch'] as bool? ?? false,
      altDocId: json['alt_doc_id'] as String?,
    );

Map<String, dynamic> _$TIMARouterDecisionToJson(TIMARouterDecision instance) =>
    <String, dynamic>{
      'intent': _$RouterIntentEnumMap[instance.intent]!,
      'control_id': instance.controlId,
      'doc_id': instance.docId,
      'aspect': _$AspectTypeEnumMap[instance.aspect],
      'query': instance.query,
      'switch': instance.shouldSwitch,
      'alt_doc_id': instance.altDocId,
    };

const _$RouterIntentEnumMap = {
  RouterIntent.controlSummary: 'CONTROL_SUMMARY',
  RouterIntent.deepen: 'DEEPEN',
  RouterIntent.assess: 'ASSESS',
  RouterIntent.tests: 'TESTS',
  RouterIntent.docSummary: 'DOC_SUMMARY',
  RouterIntent.search: 'SEARCH',
};

TIMAToolResult _$TIMAToolResultFromJson(Map<String, dynamic> json) =>
    TIMAToolResult(
      replyText: json['reply_text'] as String,
      citations:
          (json['citations'] as List<dynamic>?)
              ?.map((e) => TIMACitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      raw: json['raw'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TIMAToolResultToJson(TIMAToolResult instance) =>
    <String, dynamic>{
      'reply_text': instance.replyText,
      'citations': instance.citations,
      'raw': instance.raw,
    };
