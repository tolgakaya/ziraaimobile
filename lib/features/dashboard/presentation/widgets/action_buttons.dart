import 'package:flutter/material.dart';
import '../../../plant_analysis/presentation/pages/capture_screen.dart';

class ActionButtons extends StatelessWidget {
  final bool hasSponsorRole;
  final VoidCallback? onSponsorButtonTap;

  const ActionButtons({
    super.key,
    this.hasSponsorRole = false,
    this.onSponsorButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // Fixed total height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Bitki Analizi Button (square-ish, full height)
          Expanded(
            flex: 1,
            child: _ActionButton(
              icon: Icons.camera_alt,
              label: 'Bitki Analizi',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF22C55E), // green-500
                  Color(0xFF16A34A), // green-600
                ],
              ),
              textColor: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaptureScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Right: Two buttons stacked vertically
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top: Geçmiş Button
                Expanded(
                  child: _ActionButton(
                    icon: Icons.history,
                    label: 'Geçmiş',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6B7280), // gray-500
                        Color(0xFF4B5563), // gray-600
                      ],
                    ),
                    textColor: Colors.white,
                    onTap: () {
                      // Geçmiş buton işlevi - sonra eklenecek
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom: Sponsor Paneli Button
                Expanded(
                  child: _ActionButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Sponsor Paneli',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6), // blue-500
                        Color(0xFF2563EB), // blue-600
                      ],
                    ),
                    textColor: Colors.white,
                    onTap: onSponsorButtonTap ?? () {
                      // Default action if no callback provided
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}