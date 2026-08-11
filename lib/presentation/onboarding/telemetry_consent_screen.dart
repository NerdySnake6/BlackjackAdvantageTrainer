/// Optional first-run telemetry choices.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../viewmodels/app_state.dart';

class TelemetryConsentScreen extends StatefulWidget {
  const TelemetryConsentScreen({super.key});

  @override
  State<TelemetryConsentScreen> createState() => _TelemetryConsentScreenState();
}

class _TelemetryConsentScreenState extends State<TelemetryConsentScreen> {
  var _analyticsEnabled = false;
  var _crashReportsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.mint,
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.telemetryConsentTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.telemetryConsentBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _analyticsEnabled,
                          onChanged: (value) {
                            setState(() => _analyticsEnabled = value);
                          },
                          title: Text(strings.usageAnalyticsTitle),
                          subtitle: Text(strings.usageAnalyticsDescription),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _crashReportsEnabled,
                          onChanged: (value) {
                            setState(() => _crashReportsEnabled = value);
                          },
                          title: Text(strings.crashReportsTitle),
                          subtitle: Text(strings.crashReportsDescription),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.telemetryOptionalNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await context.read<AppState>().setTelemetryConsent(
                        analyticsEnabled: _analyticsEnabled,
                        crashReportsEnabled: _crashReportsEnabled,
                      );
                      if (context.mounted) {
                        context.go('/learn');
                      }
                    },
                    child: Text(strings.saveAndContinue),
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
