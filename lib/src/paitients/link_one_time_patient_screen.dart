import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'merge_patients_dialog.dart';
import 'patient_model.dart';

@RoutePage()
class LinkOneTimePatientScreen extends StatefulWidget {
  const LinkOneTimePatientScreen({super.key, this.initialDuplicate});

  /// When opened from the waiting / unregistered list, pre-fill the one-time patient.
  final Patient? initialDuplicate;

  @override
  State<LinkOneTimePatientScreen> createState() =>
      _LinkOneTimePatientScreenState();
}

class _LinkOneTimePatientScreenState extends State<LinkOneTimePatientScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFlow());
  }

  Future<void> _openFlow() async {
    if (_opened || !mounted) return;
    _opened = true;
    final merged = await runMergePatientsFlow(
      context,
      mode: MergePatientsMode.unregisteredOnly,
      initialDuplicate: widget.initialDuplicate,
    );
    if (!mounted) return;
    if (merged != null) {
      context.router.maybePop();
    } else {
      // User cancelled — stay so they can try again, or pop if they leave.
      setState(() => _opened = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link one-time patient'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Attach visits and bills from a one-time patient '
                  '(no hospital ID) onto a registered patient.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _openFlow,
                  icon: const Icon(Icons.link),
                  label: Text(
                    widget.initialDuplicate != null
                        ? 'Choose registered patient'
                        : 'Select patients to link',
                  ),
                ),
                if (widget.initialDuplicate != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'One-time patient: ${patientMergeLabel(widget.initialDuplicate!)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
