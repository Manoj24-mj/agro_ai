import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'monitoring_detail_screens.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  String? _selectedMethod;

  void _handleConnect(BuildContext context, String method) {
     IconData icon = Icons.wifi;
     Color color = Colors.teal;
     
     if (method == "LoRaWAN") { icon = Icons.settings_input_antenna; color = Colors.blue[600]!; }
     if (method == "NB-IoT") { icon = Icons.cell_tower; color = Colors.orange[700]!; }
     
     Navigator.push(
       context, 
       MaterialPageRoute(
         builder: (context) => DeviceConnectionDetailScreen(
           method: method, 
           icon: icon, 
           color: color
         )
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(Lang.t("monitoring_btn") ?? "Monitoring"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Center(
                    child: Text(
                      "Connectivity Hub",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text("Select your device connection method", style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                  const SizedBox(height: 24),

                  _buildConnectionCard(
                    title: "LoRaWAN",
                    subtitle: "Long range, low power connectivity",
                    imgUrl: "https://images.unsplash.com/photo-1551808198-44d471946002?auto=format&fit=crop&q=80&w=500",
                    color: Colors.blue[600]!,
                    isSelected: _selectedMethod == "LoRaWAN",
                    onTap: () => setState(() => _selectedMethod = "LoRaWAN"),
                  ),
                  const SizedBox(height: 12),
                  _buildConnectionCard(
                    title: "NB-IoT",
                    subtitle: "Cellular-grade reliable monitoring",
                    imgUrl: "https://images.unsplash.com/photo-1563770660941-20978e870813?auto=format&fit=crop&q=80&w=500",
                    color: Colors.orange[700]!,
                    isSelected: _selectedMethod == "NB-IoT",
                    onTap: () => setState(() => _selectedMethod = "NB-IoT"),
                  ),
                  const SizedBox(height: 12),
                  _buildConnectionCard(
                    title: "WiFi",
                    subtitle: "Local high-speed farm network",
                    imgUrl: "https://images.unsplash.com/photo-1614064641935-4475e466641e?auto=format&fit=crop&q=80&w=500",
                    color: Colors.teal[600]!,
                    isSelected: _selectedMethod == "WiFi",
                    onTap: () => setState(() => _selectedMethod = "WiFi"),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedMethod == null 
                  ? null 
                  : () => _handleConnect(context, _selectedMethod!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  Lang.t("continue_btn") ?? "Continue",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConnectionCard({
    required String title,
    required String subtitle,
    required String imgUrl,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Technical fallback icons
    IconData fallbackIcon = Icons.wifi;
    if (title == "LoRaWAN") fallbackIcon = Icons.settings_input_antenna;
    if (title == "NB-IoT") fallbackIcon = Icons.cell_tower;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)]),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                child: Image.network(
                  imgUrl, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(fallbackIcon, color: color, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            if (isSelected) Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: color, size: 24),
            ) else const Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
