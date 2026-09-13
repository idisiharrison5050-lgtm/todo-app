import 'package:flutter/material.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: _EmptyRoutines(onCreate: () {}),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 82, height: 82, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.schedule_rounded, size: 42, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 20), Text('Build your own routine', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center), const SizedBox(height: 8), Text('Create reminders for anything you want to happen throughout your day. Nothing is hard-coded.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 20), FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create your first routine'))])));
}
