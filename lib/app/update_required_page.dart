import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, required this.installedVersion});

  final String installedVersion;

  Future<void> _openStore() async {
    final market = Uri.parse('market://details?id=${AppConfig.playStorePackageId}');
    final https = Uri.parse(
      'https://play.google.com/store/apps/details?id=${AppConfig.playStorePackageId}',
    );
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(https, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.system_update, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Update required',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This version is no longer supported. Please install the latest '
                'release from the store to continue.\n\nInstalled version: $installedVersion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _openStore,
                child: const Text('Update on Google Play'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
