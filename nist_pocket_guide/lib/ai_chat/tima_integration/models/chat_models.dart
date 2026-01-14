// Chat-specific models for the TIMA Dialog integration.
//
// These models handle the chat interface, message history,
// and conversation management specific to the Flutter UI.

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'tima_models.dart';

part 'chat_models.g.dart';

/// Input to the chat endpoint.
@JsonSerializable()
class TIMAChatInput extends Equatable {
  const TIMAChatInput({
    required this.sessionId,
    this.text,
    this.action,
    this.metadata = const {},
  });

  @JsonKey(name: 'session_id')
  final String sessionId;

  final String? text;
  final TIMAAction? action;
  final Map<String, dynamic> metadata;

  factory TIMAChatInput.fromJson(Map<String, dynamic> json) =>
      _$TIMAChatInputFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAChatInputToJson(this);

  @override
  List<Object?> get props => [sessionId, text, action, metadata];

  TIMAChatInput copyWith({
    String? sessionId,
    String? text,
    TIMAAction? action,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatInput(
      sessionId: sessionId ?? this.sessionId,
      text: text ?? this.text,
      action: action ?? this.action,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a text-based chat input.
  factory TIMAChatInput.text({
    required String sessionId,
    required String text,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatInput(
      sessionId: sessionId,
      text: text,
      metadata: metadata ?? const {},
    );
  }

  /// Create an action-based chat input.
  factory TIMAChatInput.action({
    required String sessionId,
    required TIMAAction action,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatInput(
      sessionId: sessionId,
      action: action,
      metadata: metadata ?? const {},
    );
  }
}

/// Output from the chat endpoint.
@JsonSerializable()
class TIMAChatOutput extends Equatable {
  const TIMAChatOutput({
    required this.reply,
    this.choices = const [],
    this.citations = const [],
    required this.context,
  });

  final String reply;
  final List<TIMAChoice> choices;
  final List<TIMACitation> citations;
  final Map<String, dynamic> context;

  factory TIMAChatOutput.fromJson(Map<String, dynamic> json) =>
      _$TIMAChatOutputFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAChatOutputToJson(this);

  @override
  List<Object?> get props => [reply, choices, citations, context];

  TIMAChatOutput copyWith({
    String? reply,
    List<TIMAChoice>? choices,
    List<TIMACitation>? citations,
    Map<String, dynamic>? context,
  }) {
    return TIMAChatOutput(
      reply: reply ?? this.reply,
      choices: choices ?? this.choices,
      citations: citations ?? this.citations,
      context: context ?? this.context,
    );
  }

  /// Check if this response has interactive choices.
  bool get hasChoices => choices.isNotEmpty;

  /// Check if this response has citations.
  bool get hasCitations => citations.isNotEmpty;

  /// Get the session ID from context.
  String? get sessionId => context['session_id'] as String?;

  /// Get the last focus from context.
  TIMAFocus? get lastFocus {
    final focusData = context['last_focus'] as Map<String, dynamic>?;
    return focusData != null ? TIMAFocus.fromJson(focusData) : null;
  }

  /// Get breadcrumbs from context.
  List<String> get breadcrumbs {
    final breadcrumbsData = context['breadcrumbs'] as List?;
    return breadcrumbsData?.cast<String>() ?? [];
  }
}

/// Message types for chat interface.
enum TIMAMessageType { user, assistant, system, error }

/// A single message in the chat conversation.
@JsonSerializable()
class TIMAChatMessage extends Equatable {
  const TIMAChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.choices = const [],
    this.citations = const [],
    this.metadata = const {},
    this.isTyping = false,
  });

  final String id;
  final TIMAMessageType type;
  final String content;
  final DateTime timestamp;
  final List<TIMAChoice> choices;
  final List<TIMACitation> citations;
  final Map<String, dynamic> metadata;

  @JsonKey(includeToJson: false, includeFromJson: false)
  final bool isTyping;

  factory TIMAChatMessage.fromJson(Map<String, dynamic> json) =>
      _$TIMAChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAChatMessageToJson(this);

  @override
  List<Object?> get props => [
    id,
    type,
    content,
    timestamp,
    choices,
    citations,
    metadata,
    isTyping,
  ];

  TIMAChatMessage copyWith({
    String? id,
    TIMAMessageType? type,
    String? content,
    DateTime? timestamp,
    List<TIMAChoice>? choices,
    List<TIMACitation>? citations,
    Map<String, dynamic>? metadata,
    bool? isTyping,
  }) {
    return TIMAChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      choices: choices ?? this.choices,
      citations: citations ?? this.citations,
      metadata: metadata ?? this.metadata,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Create a user message.
  factory TIMAChatMessage.user({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TIMAMessageType.user,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata ?? const {},
    );
  }

  /// Create an assistant message from API response.
  factory TIMAChatMessage.assistant({
    required TIMAChatOutput output,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return TIMAChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TIMAMessageType.assistant,
      content: output.reply,
      timestamp: DateTime.now(),
      choices: output.choices,
      citations: output.citations,
      metadata: {...output.context, ...?additionalMetadata},
    );
  }

  /// Create a system message.
  factory TIMAChatMessage.system({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TIMAMessageType.system,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata ?? const {},
    );
  }

  /// Create an error message.
  factory TIMAChatMessage.error({
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return TIMAChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TIMAMessageType.error,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata ?? const {},
    );
  }

  /// Create a typing indicator message.
  factory TIMAChatMessage.typing() {
    return TIMAChatMessage(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      type: TIMAMessageType.assistant,
      content: '',
      timestamp: DateTime.now(),
      isTyping: true,
    );
  }

  /// Check if this message has interactive choices.
  bool get hasChoices => choices.isNotEmpty;

  /// Check if this message has citations.
  bool get hasCitations => citations.isNotEmpty;

  /// Check if this is a user message.
  bool get isUser => type == TIMAMessageType.user;

  /// Check if this is an assistant message.
  bool get isAssistant => type == TIMAMessageType.assistant;

  /// Check if this is a system message.
  bool get isSystem => type == TIMAMessageType.system;

  /// Check if this is an error message.
  bool get isError => type == TIMAMessageType.error;
}

/// Chat conversation state and history.
@JsonSerializable()
class TIMAChatSession extends Equatable {
  const TIMAChatSession({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.state,
    this.metadata = const {},
    this.isActive = true,
  });

  @JsonKey(name: 'session_id')
  final String sessionId;

  final String title;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final List<TIMAChatMessage> messages;
  final TIMASessionState? state;
  final Map<String, dynamic> metadata;

  @JsonKey(name: 'is_active')
  final bool isActive;

  factory TIMAChatSession.fromJson(Map<String, dynamic> json) =>
      _$TIMAChatSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TIMAChatSessionToJson(this);

  @override
  List<Object?> get props => [
    sessionId,
    title,
    createdAt,
    updatedAt,
    messages,
    state,
    metadata,
    isActive,
  ];

  TIMAChatSession copyWith({
    String? sessionId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TIMAChatMessage>? messages,
    TIMASessionState? state,
    Map<String, dynamic>? metadata,
    bool? isActive,
  }) {
    return TIMAChatSession(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      state: state ?? this.state,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create a new chat session.
  factory TIMAChatSession.create({
    required String sessionId,
    required String title,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return TIMAChatSession(
      sessionId: sessionId,
      title: title,
      createdAt: now,
      updatedAt: now,
      metadata: metadata ?? const {},
    );
  }

  /// Add a message to the session.
  TIMAChatSession addMessage(TIMAChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Update the session state.
  TIMAChatSession updateState(TIMASessionState newState) {
    return copyWith(state: newState, updatedAt: DateTime.now());
  }

  /// Update the session title.
  TIMAChatSession updateTitle(String newTitle) {
    return copyWith(title: newTitle, updatedAt: DateTime.now());
  }

  /// Archive the session.
  TIMAChatSession archive() {
    return copyWith(isActive: false, updatedAt: DateTime.now());
  }

  /// Get the last message in the session.
  TIMAChatMessage? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  /// Get the last user message.
  TIMAChatMessage? get lastUserMessage => messages.lastWhere(
    (msg) => msg.isUser,
    orElse: () => throw StateError('No user message found'),
  );

  /// Get the last assistant message.
  TIMAChatMessage? get lastAssistantMessage => messages.lastWhere(
    (msg) => msg.isAssistant && !msg.isTyping,
    orElse: () => throw StateError('No assistant message found'),
  );

  /// Check if the session has any messages.
  bool get hasMessages => messages.isNotEmpty;

  /// Check if the session is currently waiting for a response.
  bool get isWaitingForResponse =>
      messages.isNotEmpty && messages.last.isUser ||
      messages.any((msg) => msg.isTyping);

  /// Get the current focus from the session state.
  TIMAFocus? get currentFocus => state?.lastFocus;

  /// Get message count.
  int get messageCount => messages.length;

  /// Get user message count.
  int get userMessageCount => messages.where((msg) => msg.isUser).length;

  /// Get assistant message count.
  int get assistantMessageCount =>
      messages.where((msg) => msg.isAssistant && !msg.isTyping).length;
}
