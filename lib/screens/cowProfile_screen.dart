import 'package:flutter/material.dart';
import 'besoins_energetiques_screen.dart';
import 'besoins_proteiques_screen.dart';
import 'besoins_mineraux_screen.dart';
import 'ingestion_screen.dart';
import 'fourrages_screen.dart';

class CowProfileScreen extends StatelessWidget {
  final String name;
  final String id;
  final int age;
  final String dateNaissance;
  final int semaineGestation;
  final double nec;
  final String race;
  final String laitQuotidien;
  final double poids;

  const CowProfileScreen({
    super.key,
    required this.name,
    required this.id,
    required this.age,
    required this.dateNaissance,
    required this.semaineGestation,
    required this.nec,
    required this.race,
    required this.laitQuotidien,
    required this.poids,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil de $name")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informations générales
          _buildSection("Informations générales", [
            {"label": "Nom", "value": name},
            {"label": "ID", "value": id},
            {"label": "Âge", "value": "$age ans"},
            {"label": "Date de naissance", "value": dateNaissance},
            {"label": "Race", "value": race},
          ]),
          const SizedBox(height: 16),

          // Reproduction
          _buildSection("Reproduction", [
            {"label": "Semaine de gestation", "value": "$semaineGestation"},
            {
              "label": "Note d’état corporel (NEC)",
              "value": nec.toStringAsFixed(1),
            },
          ]),
          const SizedBox(height: 16),

          // Production
          _buildSection("Production", [
            {"label": "Production laitière", "value": laitQuotidien},
            {"label": "Poids estimé", "value": "$poids kg"},
          ]),
          const SizedBox(height: 24),

          // Cartes nutritionnelles
          Text(
            "Calculs nutritionnels",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // Première ligne : 2 cartes
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context,
                  "Besoins énergétiques",
                  Icons.flash_on,
                  const BesoinsEnergetiquesScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  "Besoins protéiques",
                  Icons.restaurant,
                  const BesoinsProteiquesScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Deuxième ligne : 3 cartes
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  context,
                  "Besoins minéraux",
                  Icons.science,
                  const BesoinsMinerauxScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  "Capacité d’ingestion",
                  Icons.local_dining,
                  const IngestionScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCard(
                  context,
                  "Quantité de fourrages",
                  Icons.grass,
                  const FourragesScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section avec fond clair et lignes justifiées
  Widget _buildSection(String title, List<Map<String, String>> infos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Container(
          color: Colors.grey.shade100,
          child: Column(
            children: infos.map((info) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          info["label"]!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          info["value"]!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (info != infos.last)
                    Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Carte carrée cliquable avec icône + titre + animation subtile
  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // coins arrondis
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // ombre légère
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.green),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
