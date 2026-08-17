import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/font_resolver.dart';
import '../../../models/text_layer_model.dart';
import '../../../providers/editor_controller.dart';
import '../../../widgets/color_swatch_picker.dart';
import 'editor_sheet_scaffold.dart';

/// Tabbed bottom sheet for editing the selected text layer.
class TextEditorSheet extends StatefulWidget {
  final EditorController controller;
  const TextEditorSheet({super.key, required this.controller});

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _text;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.controller.selected?.text ?? '');
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _text.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final layer = widget.controller.selected;
        if (layer == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Select a text layer to edit.'),
          );
        }

        if (_text.text != layer.text) {
          _text.value = _text.value.copyWith(
            text: layer.text,
            selection: TextSelection.collapsed(offset: layer.text.length),
          );
        }

        final fontValue = FontResolver.curatedFonts.contains(layer.fontFamily)
            ? layer.fontFamily
            : FontResolver.curatedFonts.first;

        return EditorSheetScaffold(
          title: 'Edit Text',
          maxHeightFraction: 0.48,
          child: Column(
            children: [
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Text'),
                  Tab(text: 'Style'),
                  Tab(text: 'Color'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _textTab(layer),
                    _styleTab(layer, fontValue),
                    _colorTab(layer),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _textTab(PosterLayer layer) {
    return SingleChildScrollView(
      child: TextField(
        controller: _text,
        minLines: 2,
        maxLines: 4,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: 'Type your text here…',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(14),
        ),
        onChanged: widget.controller.setText,
      ),
    );
  }

  Widget _styleTab(PosterLayer layer, String fontValue) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Font family'),
          DropdownButtonFormField<String>(
            key: ValueKey('font_${layer.id}_$fontValue'),
            initialValue: fontValue,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: FontResolver.curatedFonts
                .map(
                  (font) => DropdownMenuItem<String>(
                    value: font,
                    child: Text(
                      font,
                      style: FontResolver.style(font, base: const TextStyle(fontSize: 14)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (font) {
              if (font != null) widget.controller.setFont(font);
            },
          ),
          const SizedBox(height: 14),
          _label('Text size'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: layer.fontSizeFactor.clamp(0.02, 0.3),
                  min: 0.02,
                  max: 0.3,
                  onChanged: widget.controller.setFontSizeFactor,
                ),
              ),
              Text(
                '${(layer.fontSizeFactor * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _label('Formatting'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _toggle(Icons.format_bold, layer.bold, widget.controller.toggleBold),
              _toggle(Icons.format_italic, layer.italic, widget.controller.toggleItalic),
              _toggle(
                Icons.format_align_left,
                layer.align == TextAlign.left,
                () => widget.controller.setAlign(TextAlign.left),
              ),
              _toggle(
                Icons.format_align_center,
                layer.align == TextAlign.center,
                () => widget.controller.setAlign(TextAlign.center),
              ),
              _toggle(
                Icons.format_align_right,
                layer.align == TextAlign.right,
                () => widget.controller.setAlign(TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorTab(PosterLayer layer) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Text colour'),
          ColorSwatchPicker(
            selectedHex: layer.colorHex,
            onSelected: widget.controller.setTextColor,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _toggle(IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.divider),
        ),
        child: Icon(icon, color: active ? Colors.white : AppColors.darkText, size: 19),
      ),
    );
  }
}
