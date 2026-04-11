import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:agro_ai_app/localization.dart';

class DiseaseAlertMapScreen extends StatefulWidget {
  const DiseaseAlertMapScreen({super.key});

  @override
  State<DiseaseAlertMapScreen> createState() => _DiseaseAlertMapScreenState();
}

class _DiseaseAlertMapScreenState extends State<DiseaseAlertMapScreen> {
  final List<Map<String, dynamic>> _diseaseHotspots = [
    {"name": "BMSIT (Leaf Rust)", "level": "High", "x": 0.35, "y": 0.45},
    {"name": "Sai Vidya (Early Blight)", "level": "Normal", "x": 0.65, "y": 0.25},
    {"name": "NMIT (Stem Rot)", "level": "High", "x": 0.45, "y": 0.65},
    {"name": "Puttenahalli (Powdery Mildew)", "level": "High", "x": 0.25, "y": 0.75},
    {"name": "Avalahalli (Aphids)", "level": "Normal", "x": 0.75, "y": 0.85},
    {"name": "Sir M.V. (Yellow Mosaic)", "level": "High", "x": 0.15, "y": 0.35},
    {"name": "Yelahanka (Downy Mildew)", "level": "High", "x": 0.55, "y": 0.45},
    {"name": "Hebbal (Alternaria)", "level": "Normal", "x": 0.85, "y": 0.15},
    {"name": "GKVK (Blight)", "level": "High", "x": 0.45, "y": 0.85},
    {"name": "Hesaraghatta (Rust)", "level": "Normal", "x": 0.15, "y": 0.65},
    {"name": "Jakur (Late Blight)", "level": "High", "x": 0.25, "y": 0.55},
  ];

  Map<String, dynamic>? _selectedHotspot;

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Search Disease Hotspots", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _diseaseHotspots.length,
                  itemBuilder: (context, index) {
                    final spot = _diseaseHotspots[index];
                    return ListTile(
                      leading: Icon(Icons.location_on, color: spot['level'] == "High" ? Colors.redAccent : Colors.amber),
                      title: Text(spot['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text("Risk Level: ${spot['level']}", style: TextStyle(color: spot['level'] == "High" ? Colors.redAccent.withOpacity(0.7) : Colors.amber.withOpacity(0.7), fontSize: 12)),
                      onTap: () {
                        setState(() {
                          _selectedHotspot = spot;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Regional Disease Heatmap"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
               // Find nearest hotspot on tap
               double minDistance = 50; 
               Map<String, dynamic>? nearest;
               for (var spot in _diseaseHotspots) {
                 double dx = spot['x'] * MediaQuery.of(context).size.width - details.localPosition.dx;
                 double dy = spot['y'] * MediaQuery.of(context).size.height - details.localPosition.dy;
                 double dist = dx*dx + dy*dy;
                 if (dist < minDistance * minDistance) {
                   nearest = spot;
                 }
               }
               setState(() {
                 _selectedHotspot = nearest;
               });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: DiseaseTopographyPainter(hotspots: _diseaseHotspots),
            ),
          ),
          
          // Legend
          Positioned(
            top: 10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(Colors.redAccent, "High Alert Outbreak"),
                  const SizedBox(height: 8),
                  _buildLegendRow(Colors.amber, "Normal/Risk Area"),
                ],
              ),
            ),
          ),

          if (_selectedHotspot != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_selectedHotspot!['level'] == "High" ? Colors.red.shade900 : Colors.amber.shade900, Colors.black]),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedHotspot!['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => setState(() => _selectedHotspot = null)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Severity: ${_selectedHotspot!['level']}", style: TextStyle(color: _selectedHotspot!['level'] == "High" ? Colors.redAccent : Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      "Alerting farmers in this radius to begin preventative spraying. Local moisture levels are sustaining pathogen growth.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class DiseaseTopographyPainter extends CustomPainter {
  final List<Map<String, dynamic>> hotspots;
  DiseaseTopographyPainter({required this.hotspots});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    // Draw Grid (Digital Topography style)
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintLine);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintLine);
    }

    // Draw abstract terrain lines
    final terrainPaint = Paint()
      ..color = const Color(0xFF2C1E14).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path terrainPath = Path();
    terrainPath.moveTo(0, size.height * 0.7);
    terrainPath.quadraticBezierTo(size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.8);
    terrainPath.quadraticBezierTo(size.width * 0.8, size.height * 0.9, size.width, size.height * 0.6);
    canvas.drawPath(terrainPath, terrainPaint);

    // Draw Disease Hotspots
    for (var spot in hotspots) {
      final center = Offset(spot['x'] * size.width, spot['y'] * size.height);
      final color = spot['level'] == "High" ? Colors.redAccent : Colors.amber;

      // Glow/Heatmap Ripple
      final ripplePaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 40, ripplePaint);

      final ripplePaintInner = Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 70, ripplePaintInner);

      // Core Marker
      final corePaint = Paint()..color = color;
      canvas.drawCircle(center, 6, corePaint);

      // Pulse ring for High alerts
      if (spot['level'] == "High") {
        final ringPaint = Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, 12, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
