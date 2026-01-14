import 'package:flutter/material.dart';

class UnifiedParameterInput extends StatefulWidget {
  final TextEditingController controller;
  final List<String> predefinedExamples;
  final List<String> savedValues;
  final Function(String) onValueSelected;
  final VoidCallback? onSaveValue;
  final String? labelText;
  final String? hintText;

  const UnifiedParameterInput({
    super.key,
    required this.controller,
    this.predefinedExamples = const [],
    this.savedValues = const [],
    required this.onValueSelected,
    this.onSaveValue,
    this.labelText,
    this.hintText,
  });

  @override
  State<UnifiedParameterInput> createState() => _UnifiedParameterInputState();
}

class _UnifiedParameterInputState extends State<UnifiedParameterInput> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Clean up overlay first, before disposing other resources
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;

    if (_focusNode.hasFocus) {
      _updateSuggestions();
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onTextChanged() {
    if (!mounted) return;

    _updateSuggestions();
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _updateSuggestions() {
    if (!mounted) return;

    final query = widget.controller.text.toLowerCase();
    final allOptions = [...widget.predefinedExamples, ...widget.savedValues];

    final newFilteredSuggestions =
        allOptions
            .where((option) => option.toLowerCase().contains(query))
            .toList();
    final newShowSuggestions =
        newFilteredSuggestions.isNotEmpty && query.isNotEmpty;

    // Only call setState if something actually changed and widget is still mounted
    if (mounted &&
        (_filteredSuggestions != newFilteredSuggestions ||
            _showSuggestions != newShowSuggestions)) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _filteredSuggestions = newFilteredSuggestions;
            _showSuggestions = newShowSuggestions;
          });
        }
      });
    }
  }

  void _showOverlay() {
    if (!mounted || _overlayEntry != null || !_showSuggestions) return;

    // Use post-frame callback to ensure widget tree is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry != null || !_showSuggestions) return;

      try {
        _overlayEntry = _createOverlayEntry();
        if (mounted && _overlayEntry != null) {
          Overlay.of(context).insert(_overlayEntry!);
        }
      } catch (e) {
        // If overlay creation fails, clean up
        _overlayEntry = null;
      }
    });
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    if (mounted && _showSuggestions) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    if (!mounted) {
      throw Exception('Widget not mounted');
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      throw Exception('RenderBox not ready');
    }
    final size = renderBox.size;

    return OverlayEntry(
      builder: (overlayContext) {
        // Capture current state to avoid accessing disposed widget
        final suggestions = List<String>.from(_filteredSuggestions);
        final savedValues = List<String>.from(widget.savedValues);

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (listContext, index) {
                    final suggestion = suggestions[index];
                    final isFromSaved = savedValues.contains(suggestion);

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4, // Compact padding
                      ),
                      leading: Icon(
                        isFromSaved ? Icons.bookmark : Icons.lightbulb_outline,
                        size: 14, // Smaller icon to match text
                        color: isFromSaved ? Colors.blue : Colors.orange,
                      ),
                      title: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                        ), // Match input text size
                      ),
                      onTap: () {
                        if (mounted) {
                          widget.controller.text = suggestion;
                          widget.onValueSelected(suggestion);
                          _hideOverlay();
                          _focusNode.unfocus();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 13), // Smaller text size
        decoration: InputDecoration(
          labelText: widget.labelText ?? "Enter or select a value",
          labelStyle: const TextStyle(fontSize: 12), // Smaller label
          hintText:
              widget.hintText ??
              "Type to search suggestions or enter custom value",
          hintStyle: const TextStyle(fontSize: 12), // Smaller hint text
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16, // Increased padding for larger visual footprint
          ),
          suffixIcon:
              widget.onSaveValue != null
                  ? IconButton(
                    icon: const Icon(
                      Icons.bookmark_add_outlined,
                      size: 18,
                    ), // Slightly smaller icon
                    tooltip: "Save this value for future reuse",
                    onPressed: widget.onSaveValue,
                  )
                  : null,
          prefixIcon:
              _showSuggestions
                  ? const Icon(Icons.search, size: 18) // Slightly smaller icon
                  : const Icon(Icons.edit, size: 18), // Slightly smaller icon
        ),
        maxLines: 4, // Increased max lines for more space
        minLines: 2, // Increased min lines for larger widget
        onChanged: (value) {
          widget.onValueSelected(value);
        },
        onTap: () {
          if (mounted) {
            _updateSuggestions();
            _showOverlay();
          }
        },
      ),
    );
  }
}
