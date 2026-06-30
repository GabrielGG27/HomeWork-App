import 'package:flutter/material.dart';
import 'package:homework_app/l10n/app_localizations.dart';
import 'package:homework_app/main.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:homework_app/services/purchases_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchasesService = context.watch<PurchasesService>();
    final isPremium = purchasesService.isPremium;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, AppLocalizations.of(context)!.language),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blue),
            title: Text(AppLocalizations.of(context)!.language),
            subtitle: Text(
              Localizations.localeOf(context).languageCode == 'en'
                  ? 'English'
                  : 'Español',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, AppLocalizations.of(context)!.darkMode),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Colors.blue),
            title: Text(AppLocalizations.of(context)!.darkMode),
            value: isDark,
            onChanged: (bool value) {
              MyApp.setThemeMode(
                context,
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Soporte y Más'),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text(AppLocalizations.of(context)!.rateApp),
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              if (await inAppReview.isAvailable()) {
                inAppReview.requestReview();
              }
            },
          ),
          if (isPremium)
            const ListTile(
              leading: Icon(Icons.workspace_premium, color: Colors.amber),
              title: Text('Premium Activo ✅'),
              subtitle: Text('Anuncios eliminados'),
            )
          else if (purchasesService.isPurchasePending)
            const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Procesando compra...'),
            )
          else
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.restorePurchases),
              onTap: () {
                purchasesService.restorePurchases();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restaurando compras...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing: Localizations.localeOf(context).languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  MyApp.setLocale(context, const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Español'),
                trailing: Localizations.localeOf(context).languageCode == 'es'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  MyApp.setLocale(context, const Locale('es'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
