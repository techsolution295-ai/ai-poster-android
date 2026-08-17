/// A user's reusable brand identity. Used to auto-fill templates with the
/// user's company name, logo and contact details. Persisted both locally
/// (SharedPreferences) and, when signed in, to Firestore.
class BrandProfileModel {
  final String companyName;
  final String logoUrl;
  final String logoLocalPath;
  final String phone;
  final String whatsapp;
  final String address;
  final String website;
  final String brandColorHex;

  const BrandProfileModel({
    this.companyName = '',
    this.logoUrl = '',
    this.logoLocalPath = '',
    this.phone = '',
    this.whatsapp = '',
    this.address = '',
    this.website = '',
    this.brandColorHex = '#FF6C2BD9',
  });

  bool get isEmpty =>
      companyName.isEmpty &&
      phone.isEmpty &&
      whatsapp.isEmpty &&
      website.isEmpty &&
      logoUrl.isEmpty &&
      logoLocalPath.isEmpty;

  /// Best available logo reference (local file wins over remote url).
  String? get logo => logoLocalPath.isNotEmpty
      ? logoLocalPath
      : (logoUrl.isNotEmpty ? logoUrl : null);

  BrandProfileModel copyWith({
    String? companyName,
    String? logoUrl,
    String? logoLocalPath,
    String? phone,
    String? whatsapp,
    String? address,
    String? website,
    String? brandColorHex,
  }) {
    return BrandProfileModel(
      companyName: companyName ?? this.companyName,
      logoUrl: logoUrl ?? this.logoUrl,
      logoLocalPath: logoLocalPath ?? this.logoLocalPath,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      website: website ?? this.website,
      brandColorHex: brandColorHex ?? this.brandColorHex,
    );
  }

  factory BrandProfileModel.fromMap(Map<String, dynamic> m) {
    return BrandProfileModel(
      companyName: m['company_name']?.toString() ?? '',
      logoUrl: m['logo_url']?.toString() ?? '',
      logoLocalPath: m['logo_local_path']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      whatsapp: m['whatsapp']?.toString() ?? '',
      address: m['address']?.toString() ?? '',
      website: m['website']?.toString() ?? '',
      brandColorHex: m['brand_color']?.toString() ?? '#FF6C2BD9',
    );
  }

  Map<String, dynamic> toMap() => {
        'company_name': companyName,
        'logo_url': logoUrl,
        'logo_local_path': logoLocalPath,
        'phone': phone,
        'whatsapp': whatsapp,
        'address': address,
        'website': website,
        'brand_color': brandColorHex,
      };
}
