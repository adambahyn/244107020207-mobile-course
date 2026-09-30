import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/post_list_page.dart';

void main() => runApp(
  // ProviderScope wajib: tempat semua provider hidup dan tempat override
  // repository dipasang saat test.
  const ProviderScope(child: MyApp()),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Week 4 - Posts API',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const PostListPage(),
  );
}
