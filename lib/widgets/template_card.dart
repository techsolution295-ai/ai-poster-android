import 'package:flutter/material.dart';

import '../engine/poster_canvas.dart';
import '../models/design_model.dart';

/// Grid card that renders a *live* miniature of the template using the same
/// layout engine as the editor (no hand-made thumbnail images), per the design
/// spec. The [design] is a lightweight preview built by the generator.
class TemplateCard extends StatelessWidget {
  final PosterDesign design;
  final VoidCallback onTap;

  const TemplateCard({super.key, required this.design, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show the full poster (no cropping) so no text gets cut off.
            Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: PosterCanvas(design: design),
            ),
            // Subtle tap affordance.
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
