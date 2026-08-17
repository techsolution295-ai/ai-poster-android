import 'package:flutter/material.dart';

/// Maps free Material icon names (stored as strings in Firestore/layout JSON)
/// to [IconData]. Using a lookup table keeps icon references data-driven and
/// avoids `Icons` tree-shaking issues from dynamic access.
class IconResolver {
  IconResolver._();

  static const Map<String, IconData> _icons = {
    'mosque': Icons.mosque,
    'business_center': Icons.business_center,
    'school': Icons.school,
    'landscape': Icons.landscape,
    'local_offer': Icons.local_offer,
    'campaign': Icons.campaign,
    'share': Icons.share,
    'phone': Icons.phone,
    'whatsapp': Icons.chat, // WhatsApp glyph avoided (trademark) -> generic chat
    'email': Icons.email,
    'location': Icons.location_on,
    'web': Icons.public,
    'star': Icons.star,
    'check': Icons.check_circle,
    'calendar': Icons.calendar_today,
    'clock': Icons.access_time,
    'tag': Icons.sell,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'discount': Icons.percent,
    'cart': Icons.shopping_cart,
    'info': Icons.info,
  };

  static IconData resolve(String? name, {IconData fallback = Icons.star}) {
    if (name == null) return fallback;
    return _icons[name] ?? fallback;
  }

  static List<String> get availableNames => _icons.keys.toList();
}
