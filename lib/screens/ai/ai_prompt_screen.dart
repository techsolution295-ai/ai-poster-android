import 'package:flutter/material.dart';

import '../../widgets/app_button.dart';
import 'ai_results_screen.dart';

/// Dedicated prompt entry screen opened from the home hero banner.
class AiPromptScreen extends StatefulWidget {
  const AiPromptScreen({super.key});

  @override
  State<AiPromptScreen> createState() => _AiPromptScreenState();
}

class _AiPromptScreenState extends State<AiPromptScreen> {
  final _controller = TextEditingController();
  bool _isGenerating = false;
  int _promptIndex = 0;
  static const List<String> _quickPrompts = [
    'Make a poster for New Year Party Event, Glowing and Modern.',
    'Design a business flyer for digital marketing services, bold and clean.',
    'Create an Umrah package poster for April 2026, 15 days, from \$999.',
    'Make a college admission poster, scholarships available, apply now.',
    'Create a travel poster for northern tour, adventure style, 3 days package.',
    'Design a mega sale poster, up to 50% off, limited time offer.',
    'Create an event announcement poster, professional and minimal.',
    'Make a social media post for product launch, trendy and vibrant.',
    'Create a restaurant grand opening poster with discount details.',
    'Design a gym membership offer poster, energetic and modern.',
    'Create a medical camp awareness poster for Sunday free checkup.',
    'Make a real estate promotion poster for luxury apartments.',
  ];

  @override
  void initState() {
    super.initState();
    // Keep the prompt box empty on open so only hint text is shown
    // until the user types manually or taps "Write for me".
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isGenerating) return;
    setState(() => _isGenerating = true);

    // Allow the UI to rebuild so the button loader becomes visible.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AiResultsScreen(prompt: prompt)),
    ).then((_) {
      if (mounted) setState(() => _isGenerating = false);
    });
  }

  void _writeForMe() {
    if (_isGenerating) return;
    final sample = _quickPrompts[_promptIndex % _quickPrompts.length];
    setState(() {
      _controller.text = sample;
      _controller.selection = TextSelection.collapsed(offset: sample.length);
      _promptIndex = (_promptIndex + 1) % _quickPrompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Poster Generator')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Describe your idea',
                  style: TextStyle(
                    fontSize: 32 / 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 58),
                          child: TextField(
                            controller: _controller,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your poster brief...',
                              hintStyle:
                                  TextStyle(color: Color(0xFF4B5563), fontSize: 15, height: 1.45),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: _writeForMe,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7EBFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome, size: 15, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 7),
                                Text(
                                  'Write for me',
                                  style: TextStyle(
                                    color: const Color(0xFF1D4ED8),
                                    fontSize: 15 / 1.08,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: AppButton(
                label: _isGenerating ? 'Generating...' : 'Generate Posters',
                icon: Icons.auto_awesome,
                loading: _isGenerating,
                onPressed: _isGenerating ? null : _go,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

