import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientNotesScreen extends StatefulWidget {
  const InpatientNotesScreen({super.key});

  @override
  State<InpatientNotesScreen> createState() => _InpatientNotesScreenState();
}

class _InpatientNotesScreenState extends State<InpatientNotesScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'New Nursing Note',
            subtitle: 'Free-text narrative note for this patient',
            actions: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_comment, size: 18),
                label: const Text('Add Note'),
              ),
            ],
            child: TextField(
              controller: _noteCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Enter nursing note...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Notes Timeline',
            subtitle: 'Historical nursing notes (edit limited to first 10 minutes)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: const Text('No notes recorded yet'),
                  subtitle: const Text(
                    'New notes will appear here in reverse chronological order.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

