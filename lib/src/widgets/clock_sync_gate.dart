import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/errors/user_facing_error.dart';
import '../helper/app_timezone.dart';
import '../helper/date.formatter.dart';
import '../helper/theme.dart';
import '../models/server_time_model.dart';
import '../services/api_endpoint_selector.dart';
import '../services/api_service.dart';
import '../services/server_time_service.dart';

/// Runs before [child] is built: calls `GET /server-time` and blocks the app if
/// the PC clock differs from the server by more than [ServerTimeService.maxAllowedSkewMs].
class ClockSyncGate extends StatefulWidget {
  const ClockSyncGate({super.key, required this.child});

  final Widget child;

  @override
  State<ClockSyncGate> createState() => _ClockSyncGateState();
}

class _ClockSyncGateState extends State<ClockSyncGate> {
  _GatePhase _phase = _GatePhase.loading;
  String? _message;
  ServerTimePayload? _serverTime;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _phase = _GatePhase.loading;
      _message = null;
      _serverTime = null;
    });

    final timeService = ServerTimeService();
    try {
      final probe = await ApiEndpointSelector.selectFastest(
        kApiCandidateBaseUrls,
      );
      ApiService().setBaseUrl(probe.baseUrl);
      if (kDebugMode) {
        debugPrint(
          'ClockSyncGate: using ${probe.baseUrl} '
          '(${probe.latency.inMilliseconds}ms)',
        );
      }

      final server = probe.serverTime;
      final skew = timeService.skewMsIfInvalid(server);
      if (!mounted) return;
      if (skew != null) {
        setState(() {
          _phase = _GatePhase.clockMismatch;
          _serverTime = server;
          _message =
              'This computer\'s date and time do not match the hospital server '
              '(difference about ${_formatDuration(skew)}). '
              'Correct the system clock in Windows Settings, then try again.';
        });
        return;
      }
      setState(() => _phase = _GatePhase.ok);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _GatePhase.error;
        _message = userFacingErrorMessage(e);
      });
    }
  }

  static String _formatDuration(int ms) {
    if (ms < 60000) return '${(ms / 1000).round()} seconds';
    final m = ms / 60000;
    if (m < 60) return '${m.round()} minutes';
    final h = m / 60;
    return '${h.toStringAsFixed(1)} hours';
  }

  static String _formatDeviceTime() {
    return DateFormatter.dateTimeWithSeconds(AppTimezone.now());
  }

  static String _formatServerInstant(ServerTimePayload s) {
    final instant = DateTime.fromMillisecondsSinceEpoch(s.unixMs);
    return DateFormatter.dateTimeWithSeconds(instant);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _GatePhase.ok:
        return widget.child;
      case _GatePhase.loading:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Checking system time with the server…'),
                ],
              ),
            ),
          ),
        );
      case _GatePhase.clockMismatch:
        final server = _serverTime;
        final theme = AppTheme.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'System time is incorrect',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _message ?? '',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (server != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Server time (from API): ${_formatServerInstant(server)}',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This device: ${_formatDeviceTime()}',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _runCheck,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case _GatePhase.error:
        final theme = AppTheme.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        networkErrorTitle,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _message ?? networkErrorMessage,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What you can try:',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final tip in networkErrorTips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _runCheck,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

enum _GatePhase { loading, ok, clockMismatch, error }
