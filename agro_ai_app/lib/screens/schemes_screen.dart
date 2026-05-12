import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'dart:ui';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schemes = [
      {
        "title": "PM-Kisan Samman Nidhi",
        "description": "Financial benefit of Rs. 6000/- per year in three equal installments.",
        "icon": Icons.account_balance,
        "color": Colors.orange,
      },
      {
        "title": "Pradhan Mantri Fasal Bima Yojana",
        "description": "Provides a comprehensive insurance cover against failure of the crop helping in stabilizing the income of the farmers.",
        "icon": Icons.shield,
        "color": Colors.green,
      },
      {
        "title": "Kisan Credit Card (KCC)",
        "description": "Provides adequate and timely credit support from the banking system to the farmers.",
        "icon": Icons.credit_card,
        "color": Colors.blue,
      },
      {
        "title": "National Agriculture Market (e-NAM)",
        "description": "Pan-India electronic trading portal which networks the existing APMC mandis to create a unified national market.",
        "icon": Icons.storefront,
        "color": Colors.teal,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Govt Schemes (Yojana)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schemes.length,
        itemBuilder: (context, index) {
          final scheme = schemes[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening ${scheme['title']} Portal...")));
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (scheme['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(scheme['icon'] as IconData, size: 32, color: scheme['color'] as Color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scheme['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(scheme['description'] as String, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                          const SizedBox(height: 12),
                          Text("Tap to apply ->", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
