import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchPhoneNumber(
  BuildContext context,
  String number, {
  String? label,
}) async {
  final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.isEmpty) {
    _toast(context, 'Invalid phone number.');
    return;
  }

  final uri = Uri(scheme: 'tel', path: cleaned);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: cleaned));
      if (context.mounted) {
        _toast(context, 'Copied ${label ?? number} — $cleaned');
      }
    }
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: cleaned));
    if (context.mounted) {
      _toast(context, 'Copied ${label ?? number} — $cleaned');
    }
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
