import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/bottom_nav.dart';
import 'home_screen.dart';
import 'cows_screen.dart';
import 'history_screen.dart';
import 'profit_screen.dart';

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
      bottomNavigationBar: BottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}
