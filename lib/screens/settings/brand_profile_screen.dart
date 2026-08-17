import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/ui_helpers.dart';
import '../../models/brand_profile_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/color_swatch_picker.dart';

/// Lets the user save their reusable brand identity. These values auto-fill
/// into any template opened afterwards (company name, logo, contact).
class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  final _picker = ImagePicker();
  late TextEditingController _company;
  late TextEditingController _phone;
  late TextEditingController _whatsapp;
  late TextEditingController _address;
  late TextEditingController _website;
  String _logoPath = '';
  String _colorHex = '#FF6C2BD9';

  @override
  void initState() {
    super.initState();
    final b = context.read<AppState>().brand;
    _company = TextEditingController(text: b.companyName);
    _phone = TextEditingController(text: b.phone);
    _whatsapp = TextEditingController(text: b.whatsapp);
    _address = TextEditingController(text: b.address);
    _website = TextEditingController(text: b.website);
    _logoPath = b.logoLocalPath;
    _colorHex = b.brandColorHex;
  }

  @override
  void dispose() {
    _company.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _address.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file != null) setState(() => _logoPath = file.path);
  }

  Future<void> _save() async {
    final profile = BrandProfileModel(
      companyName: _company.text.trim(),
      logoLocalPath: _logoPath,
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      address: _address.text.trim(),
      website: _website.text.trim(),
      brandColorHex: _colorHex,
    );
    await context.read<AppState>().saveBrand(profile);
    if (mounted) {
      UiHelpers.showSnack(context, 'Brand profile saved.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brand profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                clipBehavior: Clip.antiAlias,
                child: _logoPath.isNotEmpty
                    ? Image.file(File(_logoPath), fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: AppColors.primary),
                          SizedBox(height: 6),
                          Text('Add logo', style: TextStyle(fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _field(_company, 'Company name', Icons.business),
          _field(_phone, 'Phone number', Icons.phone, type: TextInputType.phone),
          _field(_whatsapp, 'WhatsApp number', Icons.chat, type: TextInputType.phone),
          _field(_address, 'Address', Icons.location_on),
          _field(_website, 'Website', Icons.public, type: TextInputType.url),
          const SizedBox(height: 12),
          const Text('Default brand colour',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ColorSwatchPicker(
            selectedHex: _colorHex,
            onSelected: (hex) => setState(() => _colorHex = hex),
          ),
          const SizedBox(height: 28),
          AppButton(label: 'Save profile', icon: Icons.save, onPressed: _save),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}
