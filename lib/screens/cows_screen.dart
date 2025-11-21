import 'package:flutter/material.dart';
import '../widgets/cow_card.dart';

class CowsScreen extends StatelessWidget {
  const CowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        CowCard(
          name: 'Belle',
          breed: 'Holstein',
          milkPerDay: '18,5 L/jour',
          id: 'C001',
          age: 4,
          dateNaissance: '12/03/2021',
          semaineGestation: 12,
          nec: 3.0,
          poids: 600,
        ),
        SizedBox(height: 10),
        CowCard(
          name: 'Elsa',
          breed: 'Jersey',
          milkPerDay: '20,5 L/jour',
          id: 'C002',
          age: 5,
          dateNaissance: '05/07/2020',
          semaineGestation: 0,
          nec: 3.5,
          poids: 550,
        ),
        SizedBox(height: 10),
        CowCard(
          name: 'Héra',
          breed: 'Frisonne',
          milkPerDay: '19,2 L/jour',
          id: 'C003',
          age: 6,
          dateNaissance: '22/11/2019',
          semaineGestation: 20,
          nec: 2.8,
          poids: 620,
        ),
      ],
    );
  }
}
