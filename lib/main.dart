import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'core/registry.dart';
import 'l10n/app_localizations.dart';
import 'screens/upload_screen.dart';
import 'screens/upload_screen.dart';

void main() {
  runApp(const ProviderScope(child: UppidiApp()));
}

class UppidiApp extends StatelessWidget {
  const UppidiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uppidi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AdaptiveHomePage(),
    );
  }
}

class AdaptiveHomePage extends StatelessWidget {
  const AdaptiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _MobileLayout();
        } else {
          return _DesktopLayout();
        }
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('uppidi')),
      body: const UploadScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.cloud_upload), label: Text('Upload')),
              NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: UploadScreen()),
        ],
      ),
    );
  }
}

class _ProviderList extends StatelessWidget {
  final List<dynamic> providers;
  const _ProviderList({required this.providers});

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const Center(child: Text('No providers configured'));
    }
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return ListTile(
          title: Text(provider.providerName ?? ''),
          subtitle: Text(provider.providerId ?? ''),
          trailing: provider.supportsWeb
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.warning, color: Colors.orange),
        );
      },
    );
  }
}
