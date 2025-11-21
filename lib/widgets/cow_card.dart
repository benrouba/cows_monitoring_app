import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/cowProfile_screen.dart';

class CowCard extends StatelessWidget {
  final String name;
  final String breed;
  final String milkPerDay;
  final String id;
  final int age;
  final String dateNaissance;
  final int semaineGestation;
  final double nec;
  final double poids;

  const CowCard({
    super.key,
    required this.name,
    required this.breed,
    required this.milkPerDay,
    required this.id,
    required this.age,
    required this.dateNaissance,
    required this.semaineGestation,
    required this.nec,
    required this.poids,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CowProfileScreen(
                name: name,
                id: id,
                age: age,
                dateNaissance: dateNaissance,
                semaineGestation: semaineGestation,
                nec: nec,
                race: breed,
                laitQuotidien: milkPerDay,
                poids: poids,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(FontAwesomeIcons.cow, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(breed, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                milkPerDay,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
