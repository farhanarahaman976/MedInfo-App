import 'package:flutter/material.dart';
import '../models/health_tip.dart';

class HealthTipDetailPage extends StatelessWidget {
  final HealthTip tip;
  final List<Color> gradientColors;

  const HealthTipDetailPage({
    super.key,
    required this.tip,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF14161D) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Health Tip'),
        backgroundColor: isDark ? const Color(0xFF14161D) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tip.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (tip.titleBangla.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tip.titleBangla,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── English section ──
            if (tip.body.isNotEmpty) ...[
              _sectionLabel(context, 'English', gradientColors, isDark),
              const SizedBox(height: 10),
              _bodyCard(context, tip.body, isDark),
              const SizedBox(height: 22),
            ],

            // ── Bangla section ──
            if (tip.bodyBangla.isNotEmpty) ...[
              _sectionLabel(context, 'বাংলা', gradientColors, isDark),
              const SizedBox(height: 10),
              _bodyCard(context, tip.bodyBangla, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    String label,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _bodyCard(BuildContext context, String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.7,
          color: isDark ? Colors.grey[300] : const Color(0xFF1A1D26),
        ),
      ),
    );
  }
}