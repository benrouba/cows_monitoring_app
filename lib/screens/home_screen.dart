import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/summary_card.dart';
import '../widgets/env_card.dart';
import '../widgets/cow_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: SummaryCard(
                  icon: FontAwesomeIcons.cow,
                  label: 'Total vaches',
                  value: '32',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  icon: FontAwesomeIcons.tint,
                  label: 'Lait moyen (L)',
                  value: '19.8',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  icon: FontAwesomeIcons.wind,
                  label: 'Ammoniac (ppm)',
                  value: '6',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: EnvCard(
                  icon: FontAwesomeIcons.temperatureHigh,
                  label: 'Température',
                  value: '18°C',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: EnvCard(
                  icon: FontAwesomeIcons.water,
                  label: 'Humidité',
                  value: '82%',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: EnvCard(
                  icon: FontAwesomeIcons.tachometerAlt,
                  label: 'Pression',
                  value: '1004 hPa',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: EnvCard(
                  icon: FontAwesomeIcons.flask,
                  label: 'Ammoniac',
                  value: '6 ppm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
