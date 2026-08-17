import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/ui_helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 12),
        const Text(
          'Settings',
          style: TextStyle(fontSize: 38 / 1.7, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 886 / 322,
            child: Image.asset(AppConstants.settingsBannerAsset, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 14),
        _item(
          context,
          icon: CupertinoIcons.shield_fill,
          title: 'Privacy Policy',
          subtitle: 'How we collect and protect your data',
          onTap: () => _openUrl(context, AppConstants.privacyPolicyUrl),
        ),
        _item(
          context,
          icon: CupertinoIcons.doc_text_fill,
          title: 'Terms & Conditions',
          subtitle: 'Rules for using Poster Maker',
          onTap: () => _openUrl(context, AppConstants.termsUrl),
        ),
        _item(
          context,
          icon: CupertinoIcons.mail_solid,
          title: 'Support',
          subtitle: AppConstants.supportEmail,
          onTap: () => _openSupport(context),
        ),
        _item(
          context,
          icon: CupertinoIcons.share,
          title: 'Share App',
          subtitle: 'Invite friends to create posters',
          onTap: () => _shareApp(context),
        ),
        _item(
          context,
          icon: CupertinoIcons.star_fill,
          title: 'Rate Us',
          subtitle: 'Rate Poster Maker on Google Play',
          onTap: () => _rateApp(context),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18 / 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  color: AppColors.primary,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        UiHelpers.showSnack(context, 'Could not open link.', error: true);
      }
    } catch (_) {
      if (context.mounted) {
        UiHelpers.showSnack(context, 'Could not open link.', error: true);
      }
    }
  }

  Future<void> _openSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': '${AppConstants.appName} Support',
        'body':
            'Hi Support,\n\nApp: ${AppConstants.appName}\nPackage: ${AppConstants.packageName}\n\nPlease describe your issue:\n',
      },
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        UiHelpers.showSnack(
          context,
          'Could not open email. Write to ${AppConstants.supportEmail}',
          error: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        UiHelpers.showSnack(
          context,
          'Could not open email. Write to ${AppConstants.supportEmail}',
          error: true,
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    await SharePlus.instance.share(
      ShareParams(
        title: AppConstants.appName,
        text:
            'Create stunning posters, flyers & thumbnails in seconds with '
            '${AppConstants.appName}.\n\n'
            'Download free on Google Play:\n${AppConstants.playStoreUrl}',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final market = Uri.parse('market://details?id=${AppConstants.packageName}');
    final web = Uri.parse(AppConstants.playStoreUrl);
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        UiHelpers.showSnack(context, 'Could not open Play Store.', error: true);
      }
    }
  }
}
