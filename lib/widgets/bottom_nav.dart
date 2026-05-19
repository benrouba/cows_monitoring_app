import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kCardBg,
        border: Border(top: BorderSide(color: kBorderColor, width: 0.8)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: kCardBg,
        indicatorColor: kSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: kTextSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: kPrimary),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined, color: kTextSecondary),
            selectedIcon: Icon(Icons.pets, color: kPrimary),
            label: 'Vaches',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: kTextSecondary),
            selectedIcon: Icon(Icons.history, color: kPrimary),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined, color: kTextSecondary),
            selectedIcon: Icon(Icons.trending_up, color: kPrimary),
            label: 'Profits',
          ),
        ],
      ),
    );
  }
}

// Override label text style via NavigationBarTheme in the parent
extension NavigationBarLabels on Widget {
  Widget withNunitoLabels() {
    return Builder(builder: (context) {
      return NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? kPrimary : kTextSecondary,
            );
          }),
        ),
        child: this,
      );
    });
  }
}
