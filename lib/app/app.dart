/// Root application widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../viewmodels/app_state.dart';
import 'router.dart';
import 'theme.dart';

class BlackjackTrainerApp extends StatefulWidget {
  const BlackjackTrainerApp({required this.appState, super.key});

  final AppState appState;

  @override
  State<BlackjackTrainerApp> createState() => _BlackjackTrainerAppState();
}

class _BlackjackTrainerAppState extends State<BlackjackTrainerApp> {
  late final _router = createRouter(appState: widget.appState);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appState,
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp.router(
            locale: appState.locale,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: _router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
