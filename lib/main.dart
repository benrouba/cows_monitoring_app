// import 'package:flutter/material.dart';
// import 'theme.dart';
// import 'screens/dashboard_screen.dart';

// void main() {
//   runApp(const HerdApp());
// }

// class HerdApp extends StatelessWidget {
//   const HerdApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Your Herd',
//       theme: buildAppTheme(),
//       home: const DashboardScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'repositories/cow_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CowRepository.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion du troupeau',
      theme: buildAppTheme(),
      home: const DashboardScreen(),
    );
  }
}
