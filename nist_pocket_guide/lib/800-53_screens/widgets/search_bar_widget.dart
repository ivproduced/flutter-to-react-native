import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final void Function(String) onSubmitted;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onSubmitted,
    this.hintText = 'Search controls...',
  });

 @override
Widget build(BuildContext context) {
  final controller = TextEditingController();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8), // less vertical space
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
  controller: controller,
  onSubmitted: onSubmitted,
  textInputAction: TextInputAction.search,
  decoration: InputDecoration(
    prefixIcon: const Icon(Icons.search),
    hintText: 'Search...',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
),

    ),
  );
}

}
