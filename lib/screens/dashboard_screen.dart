import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'cows_screen.dart';
import 'history_screen.dart';
import 'profit_screen.dart';
import 'cow_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    CowsScreen(),
    HistoryPage(),
    ProfitPage(),
  ];

  static const List<String> _titles = [
    'Tableau de bord',
    'Votre Troupeau',
    'Historique',
    'Profits',
  ];

  Future<void> _openAddCowDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ajouter une vache',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nom de la vache',
            labelStyle: GoogleFonts.nunito(color: kTextSecondary),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: kPrimary),
            ),
          ),
          style: GoogleFonts.nunito(color: kTextPrimary, fontSize: 16),
          onSubmitted: (v) {
            final n = v.trim();
            if (n.isNotEmpty) Navigator.pop(ctx, n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.nunito(color: kTextSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty) Navigator.pop(ctx, n);
            },
            child: Text('Continuer', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CowFormScreen(cowName: name)),
      );
      setState(() {});
    }
  }

  Widget _navItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? kPrimary : kTextSecondary,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: selected ? kPrimary : kTextSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _titles[_tabIndex],
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _pages[_tabIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCowDialog,
        backgroundColor: kPrimary,
        elevation: 6,
        shape: const CircleBorder(),
        tooltip: 'Ajouter une vache',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: kCardBg,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
              _navItem(1, Icons.pets_outlined, Icons.pets, 'Vaches'),
              const SizedBox(width: 72),
              _navItem(
                  2, Icons.history_outlined, Icons.history, 'Historique'),
              _navItem(
                  3, Icons.trending_up_outlined, Icons.trending_up, 'Profits'),
            ],
          ),
        ),
      ),
    );
  }
}
