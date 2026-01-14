// lib/widgets/linkable_text_widget.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkableTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const LinkableTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  static final RegExp _markdownUrlRegex = RegExp(
    r'\[([^\]]+?)\]\((https?:\/\/[^\)]+?)\)', // Text in [], URL in ()
    caseSensitive: false,
  );
  static final RegExp _plainUrlRegex = RegExp(
    r'(https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*))',
    caseSensitive: false,
  );

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
      debugPrint('Could not launch $url');
    }
  }

  List<InlineSpan> _buildTextSpans(String rawText, BuildContext context, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    int currentPosition = 0;

    // Combine matches from both regexes
    final List<Match> allMatches = [];
    allMatches.addAll(_markdownUrlRegex.allMatches(rawText));
    allMatches.addAll(_plainUrlRegex.allMatches(rawText));

    // Sort matches by start index
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Filter out overlapping matches (prefer markdown if plain URL is inside its text)
    final List<Match> uniqueMatches = [];
    for (int i = 0; i < allMatches.length; i++) {
      bool isOverlapped = false;
      for (int j = 0; j < uniqueMatches.length; j++) {
        // If current match is contained within a previous match's display text (for markdown)
        if (uniqueMatches[j].pattern == _markdownUrlRegex &&
            allMatches[i].start >= uniqueMatches[j].start &&
            allMatches[i].end <= uniqueMatches[j].start + uniqueMatches[j].group(1)!.length &&
            rawText.substring(uniqueMatches[j].start, uniqueMatches[j].end).contains(allMatches[i].group(0)!)) {
          isOverlapped = true;
          break;
        }
        // If current match starts before previous ends and ends after previous starts
        if (allMatches[i].start < uniqueMatches[j].end && allMatches[i].end > uniqueMatches[j].start) {
           // If a plain URL is fully contained within a markdown link's URL part, it's fine.
           // Otherwise, if they truly overlap, prioritize the longer or earlier one (markdown is usually more specific)
           if (uniqueMatches[j].pattern == _markdownUrlRegex && allMatches[i].pattern == _plainUrlRegex &&
               rawText.substring(uniqueMatches[j].start, uniqueMatches[j].end).contains(allMatches[i].group(0)!)) {
               // This plain URL is likely part of the markdown URL itself, skip it
           } else {
              // More sophisticated overlap handling might be needed for complex cases.
              // For now, let's assume simple overlaps and prioritize earlier/markdown.
              // If we add a plain URL that is entirely within a markdown link's text, we have an issue.
              // A simpler rule: if a match is entirely within another, take the outer one.
              if (allMatches[i].start >= uniqueMatches[j].start && allMatches[i].end <= uniqueMatches[j].end) {
                  isOverlapped = true;
                  break;
              }
           }
        }
      }
      if (!isOverlapped) {
        uniqueMatches.add(allMatches[i]);
      }
    }


    for (var match in uniqueMatches) {
      if (match.start > currentPosition) {
        spans.add(TextSpan(text: rawText.substring(currentPosition, match.start)));
      }

      String linkText;
      String url;

      if (match.pattern == _markdownUrlRegex) {
        linkText = match.group(1)!;
        url = match.group(2)!;
      } else { // Plain URL
        linkText = match.group(0)!;
        url = linkText;
      }

      spans.add(
        TextSpan(
          text: linkText,
          style: baseStyle.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: Theme.of(context).colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(context, url),
        )
      );
      currentPosition = match.end;
    }

    if (currentPosition < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(currentPosition)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: defaultStyle,
        children: _buildTextSpans(text, context, defaultStyle),
      ),
    );
  }
}