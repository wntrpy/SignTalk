import 'package:flutter/widgets.dart';
import 'presence_service.dart';

class AppLifecycleReactor with WidgetsBindingObserver {
  final PresenceService _presenceService;

  AppLifecycleReactor(this._presenceService);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App is back in foreground
      _presenceService.setUserOnline(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App goes background or is closed
      _presenceService.setUserOnline(false);
    }
  }
}
