import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar widget for the AI Meme Generator app.
/// Implements cyberpunk minimalism design with neon accents and thumb-zone optimization.
///
/// This widget is parameterized and reusable - navigation logic should be handled
/// by the parent widget through the [onTap] callback.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            // Provide haptic feedback for better user experience
            HapticFeedback.lightImpact();
            onTap(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
          unselectedLabelStyle:
              theme.bottomNavigationBarTheme.unselectedLabelStyle,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.home_outlined,
                isSelected: currentIndex == 0,
                theme: theme,
              ),
              activeIcon: _buildIcon(
                icon: Icons.home,
                isSelected: true,
                theme: theme,
              ),
              label: 'Home',
              tooltip: 'Home Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.auto_awesome_outlined,
                isSelected: currentIndex == 1,
                theme: theme,
              ),
              activeIcon: _buildIcon(
                icon: Icons.auto_awesome,
                isSelected: true,
                theme: theme,
              ),
              label: 'AI Create',
              tooltip: 'AI Meme Creator',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.grid_view_outlined,
                isSelected: currentIndex == 2,
                theme: theme,
              ),
              activeIcon: _buildIcon(
                icon: Icons.grid_view,
                isSelected: true,
                theme: theme,
              ),
              label: 'Gallery',
              tooltip: 'Meme Gallery',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.upload_outlined,
                isSelected: currentIndex == 3,
                theme: theme,
              ),
              activeIcon: _buildIcon(
                icon: Icons.upload,
                isSelected: true,
                theme: theme,
              ),
              label: 'Upload',
              tooltip: 'Upload Image',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an icon with optional neon glow effect for selected state
  Widget _buildIcon({
    required IconData icon,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: 24),
    );
  }
}
