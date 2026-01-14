// Core data models for TIMA Dialog RAG integration.
//
// These models mirror the Python Pydantic models from the API
// to ensure type safety and consistency across the Flutter integration.

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tima_models.g.dart';

/// Action types that can be performed in the dialog system.
enum ActionType {
  @JsonValue('CONTROL_SUMMARY')
  controlSummary,
  @JsonValue('DEEPEN')
  deepen,
  @JsonValue('ASSESS')
  assess,
  @JsonValue('TESTS')
  tests,
  @JsonValue('DOC_SUMMARY')
  docSummary,
  @JsonValue('SEARCH')
  search,
}

/// Aspect types for content presentation.
enum AspectType {
  @JsonValue('plain_english')
  plainEnglish,
  @JsonValue('normative')
  normative,
}

/// Router intent types for classification.
enum RouterIntent {
  @JsonValue('CONTROL_SUMMARY')
  controlSummary,
  @JsonValue('DEEPEN')
  deepen,
  @JsonValue('ASSESS')
  assess,
  @JsonValue('TESTS')
  tests,
  @JsonValue('DOC_SUMMARY')
  docSummary,
  @JsonValue('SEARCH')
  search,
}

/// Action that can be taken from a choice button.
@JsonSerializable()
class TIMAAction extends Equatable {
  const TIMAAction({
    required this.type,
    this.controlId,
    this.docId,
    this.aspect,
    this.query,
  });

  final ActionType type;

  @JsonKey(name: 'control_id')
  final String? controlId;

  @JsonKey(name: 'doc_id')
  final String? docId;

  final AspectType? aspect;
  final String? query;

  factory TIMAAction.fromJson(Map<String, dynamic> json) =>
      _$TIMAActionFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAActionToJson(this);

  @override
  List<Object?> get props => [type, controlId, docId, aspect, query];

  TIMAAction copyWith({
    ActionType? type,
    String? controlId,
    String? docId,
    AspectType? aspect,
    String? query,
  }) {
    return TIMAAction(
      type: type ?? this.type,
      controlId: controlId ?? this.controlId,
      docId: docId ?? this.docId,
      aspect: aspect ?? this.aspect,
      query: query ?? this.query,
    );
  }
}

/// A choice button presented to the user.
@JsonSerializable()
class TIMAChoice extends Equatable {
  const TIMAChoice({required this.label, required this.action});

  final String label;
  final TIMAAction action;

  factory TIMAChoice.fromJson(Map<String, dynamic> json) =>
      _$TIMAChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAChoiceToJson(this);

  @override
  List<Object?> get props => [label, action];

  TIMAChoice copyWith({String? label, TIMAAction? action}) {
    return TIMAChoice(
      label: label ?? this.label,
      action: action ?? this.action,
    );
  }
}

/// Citation for referenced content.
@JsonSerializable()
class TIMACitation extends Equatable {
  const TIMACitation({required this.source, required this.ref, this.loc});

  final String source;
  final String ref;
  final String? loc;

  factory TIMACitation.fromJson(Map<String, dynamic> json) =>
      _$TIMACitationFromJson(json);

  Map<String, dynamic> toJson() => _$TIMACitationToJson(this);

  @override
  List<Object?> get props => [source, ref, loc];

  TIMACitation copyWith({String? source, String? ref, String? loc}) {
    return TIMACitation(
      source: source ?? this.source,
      ref: ref ?? this.ref,
      loc: loc ?? this.loc,
    );
  }
}

/// Focus information for session context.
@JsonSerializable()
class TIMAFocus extends Equatable {
  const TIMAFocus({required this.kind, required this.id});

  final String kind; // "control" or "doc"
  final String id;

  factory TIMAFocus.fromJson(Map<String, dynamic> json) =>
      _$TIMAFocusFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAFocusToJson(this);

  @override
  List<Object?> get props => [kind, id];

  TIMAFocus copyWith({String? kind, String? id}) {
    return TIMAFocus(kind: kind ?? this.kind, id: id ?? this.id);
  }

  /// Check if this focus is for a control.
  bool get isControl => kind == 'control';

  /// Check if this focus is for a document.
  bool get isDocument => kind == 'doc';
}

/// Topic generation settings.
@JsonSerializable()
class TIMATopicGeneration extends Equatable {
  const TIMATopicGeneration({this.allowCrosslinks = true});

  @JsonKey(name: 'allow_crosslinks')
  final bool allowCrosslinks;

  factory TIMATopicGeneration.fromJson(Map<String, dynamic> json) =>
      _$TIMATopicGenerationFromJson(json);

  Map<String, dynamic> toJson() => _$TIMATopicGenerationToJson(this);

  @override
  List<Object?> get props => [allowCrosslinks];

  TIMATopicGeneration copyWith({bool? allowCrosslinks}) {
    return TIMATopicGeneration(
      allowCrosslinks: allowCrosslinks ?? this.allowCrosslinks,
    );
  }
}

/// Session state for persistence and context.
@JsonSerializable()
class TIMASessionState extends Equatable {
  const TIMASessionState({
    this.lastFocus,
    this.breadcrumbs = const [],
    this.pendingChoices = const [],
    this.topicGeneration = const TIMATopicGeneration(),
  });

  @JsonKey(name: 'last_focus')
  final TIMAFocus? lastFocus;

  final List<String> breadcrumbs;

  @JsonKey(name: 'pending_choices')
  final List<TIMAChoice> pendingChoices;

  @JsonKey(name: 'topic_generation')
  final TIMATopicGeneration topicGeneration;

  factory TIMASessionState.fromJson(Map<String, dynamic> json) =>
      _$TIMASessionStateFromJson(json);

  Map<String, dynamic> toJson() => _$TIMASessionStateToJson(this);

  @override
  List<Object?> get props => [
    lastFocus,
    breadcrumbs,
    pendingChoices,
    topicGeneration,
  ];

  TIMASessionState copyWith({
    TIMAFocus? lastFocus,
    List<String>? breadcrumbs,
    List<TIMAChoice>? pendingChoices,
    TIMATopicGeneration? topicGeneration,
  }) {
    return TIMASessionState(
      lastFocus: lastFocus ?? this.lastFocus,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      pendingChoices: pendingChoices ?? this.pendingChoices,
      topicGeneration: topicGeneration ?? this.topicGeneration,
    );
  }

  /// Create a new empty session state.
  factory TIMASessionState.empty() => const TIMASessionState();

  /// Check if the session has an active focus.
  bool get hasFocus => lastFocus != null;

  /// Get the current focus control ID if focused on a control.
  String? get currentControlId =>
      lastFocus?.isControl == true ? lastFocus!.id : null;

  /// Get the current focus document ID if focused on a document.
  String? get currentDocumentId =>
      lastFocus?.isDocument == true ? lastFocus!.id : null;
}

/// Router decision from LLM classification.
@JsonSerializable()
class TIMARouterDecision extends Equatable {
  const TIMARouterDecision({
    required this.intent,
    this.controlId,
    this.docId,
    this.aspect,
    this.query,
    this.shouldSwitch = false,
    this.altDocId,
  });

  final RouterIntent intent;

  @JsonKey(name: 'control_id')
  final String? controlId;

  @JsonKey(name: 'doc_id')
  final String? docId;

  final AspectType? aspect;
  final String? query;

  @JsonKey(name: 'switch')
  final bool shouldSwitch;

  @JsonKey(name: 'alt_doc_id')
  final String? altDocId;

  factory TIMARouterDecision.fromJson(Map<String, dynamic> json) =>
      _$TIMARouterDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$TIMARouterDecisionToJson(this);

  @override
  List<Object?> get props => [
    intent,
    controlId,
    docId,
    aspect,
    query,
    shouldSwitch,
    altDocId,
  ];

  TIMARouterDecision copyWith({
    RouterIntent? intent,
    String? controlId,
    String? docId,
    AspectType? aspect,
    String? query,
    bool? shouldSwitch,
    String? altDocId,
  }) {
    return TIMARouterDecision(
      intent: intent ?? this.intent,
      controlId: controlId ?? this.controlId,
      docId: docId ?? this.docId,
      aspect: aspect ?? this.aspect,
      query: query ?? this.query,
      shouldSwitch: shouldSwitch ?? this.shouldSwitch,
      altDocId: altDocId ?? this.altDocId,
    );
  }
}

/// Tool execution result.
@JsonSerializable()
class TIMAToolResult extends Equatable {
  const TIMAToolResult({
    required this.replyText,
    this.citations = const [],
    this.raw,
  });

  @JsonKey(name: 'reply_text')
  final String replyText;

  final List<TIMACitation> citations;
  final Map<String, dynamic>? raw;

  factory TIMAToolResult.fromJson(Map<String, dynamic> json) =>
      _$TIMAToolResultFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAToolResultToJson(this);

  @override
  List<Object?> get props => [replyText, citations, raw];

  TIMAToolResult copyWith({
    String? replyText,
    List<TIMACitation>? citations,
    Map<String, dynamic>? raw,
  }) {
    return TIMAToolResult(
      replyText: replyText ?? this.replyText,
      citations: citations ?? this.citations,
      raw: raw ?? this.raw,
    );
  }
}
