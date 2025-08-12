// lib/widgets/chat/search_user_card_widget.dart

import 'package:flutter/material.dart';

class SearchUserCardWidget extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback? onTap;

  const SearchUserCardWidget({
    required this.name,
    required this.email,
    this.photoUrl,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.search, color: Colors.grey),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      visualDensity: VisualDensity.compact,
    );
  }
}
