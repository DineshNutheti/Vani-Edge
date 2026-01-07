import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/llm_service.dart';
import 'core/services/llama_service.dart'; // Ensure this imports your Mock or Real service
import 'features/chat/presentation/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ProviderScope(
      overrides: [
        // Injecting the service (Mock for now, Real later)
        llmServiceProvider.overrideWithValue(LlamaService()),
      ],
      child: const VaniEdgeApp(),
    ),
  );
}

class VaniEdgeApp extends StatelessWidget {
  const VaniEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vani-Edge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}