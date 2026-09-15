import 'package:flutter/material.dart';
import 'package:sungguard/l10n/app_localizations.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping_rounded,
              size: 56.0,
              color: Colors.white,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'SUNGUARD',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              l10n.splashSubtitle,
              style: const TextStyle(
                fontSize: 13.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24.0),
            const SizedBox(
              width: 24.0,
              height: 24.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
