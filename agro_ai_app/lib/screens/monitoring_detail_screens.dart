import 'package:flutter/material.dart';
import 'package:agro_ai_app/localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DeviceConnectionDetailScreen extends StatelessWidget {
  final String method;
  final IconData icon;
  final Color color;

  const DeviceConnectionDetailScreen({
    super.key, 
    required this.method, 
    required this.icon, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Connect $method"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 30),
              Text(
                "Connect your $method Device",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Ensure your smart sensor is powered on and within range of your smartphone's antenna or $method gateway.",
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                         Icon(Icons.info_outline, size: 16, color: Colors.blue),
                         SizedBox(width: 8),
                         Text("Status: Searching...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(minHeight: 8, borderRadius: BorderRadius.all(Radius.circular(4))),
                    SizedBox(height: 20),
                    Text("Searching for nearby devices...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const MonitoringChoiceScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonitoringChoiceScreen extends StatelessWidget {
  const MonitoringChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Setup Monitoring Area"),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "How would you like to define your monitoring area?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "You can either select your land on our proprietary Digital Topographic map or manually enter your farm details.",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            
            _buildChoiceCard(
              context: context,
              title: "Proprietary Map",
              subtitle: "Interactive Digital Topography of Rajanukunte",
              icon: Icons.map_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LandSelectionMapScreen())),
            ),
            const SizedBox(height: 16),
            _buildChoiceCard(
              context: context,
              title: "Self Serve",
              subtitle: "Manually feed land size, soil type, and location details",
              icon: Icons.assignment_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfServeLandScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class SelfServeLandScreen extends StatefulWidget {
  const SelfServeLandScreen({super.key});

  @override
  State<SelfServeLandScreen> createState() => _SelfServeLandScreenState();
}

class _SelfServeLandScreenState extends State<SelfServeLandScreen> {
  final _valController = TextEditingController();
  final _villageController = TextEditingController();
  String _soilType = "Loamy";
  String _landUnit = "Acres";
  String _selectedDistrict = "Select District";
  String _searchQuery = "";

  final List<String> _districts = [
    "Bagalkot", "Bangalore Rural", "Bangalore Urban", "Belagavi", "Ballari",
    "Bidar", "Chamarajanagar", "Chikkaballapur", "Chikkamagaluru", "Chitradurga",
    "Dakshina Kannada", "Davanagere", "Dharwad", "Gadag", "Kalaburagi",
    "Hassan", "Haveri", "Kodagu", "Kolar", "Koppal", "Mandya", "Mysuru",
    "Raichur", "Ramanagara", "Shivamogga", "Tumakuru", "Udupi",
    "Uttara Kannada", "Vijayapura", "Yadgir", "Vijayanagara"
  ];

  void _showDistrictSearch() {
    _searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredDistricts = _districts
                .where((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) {
                        setModalState(() => _searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: "Search District in Karnataka...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: filteredDistricts.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_city, size: 20, color: Colors.blueGrey),
                          title: Text(filteredDistricts[index], style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                          onTap: () {
                            setState(() => _selectedDistrict = filteredDistricts[index]);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manual Land Setup"),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter Farm Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _valController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "e.g. 5.5",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _landUnit,
                      items: ["Acres", "Hectare", "Gunta"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (val) => setState(() => _landUnit = val!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _soilType,
                items: ["Loamy", "Clay", "Sandy", "Silty", "Peaty"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _soilType = val!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _showDistrictSearch,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(_selectedDistrict, style: TextStyle(color: _selectedDistrict == "Select District" ? Colors.grey : Colors.black)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _villageController,
                decoration: InputDecoration(
                  hintText: "e.g. Near Hassan Main Road",
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitoringDashboardScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Save & Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandSelectionMapScreen extends StatefulWidget {
  const LandSelectionMapScreen({super.key});

  @override
  State<LandSelectionMapScreen> createState() => _LandSelectionMapScreenState();
}

class _LandSelectionMapScreenState extends State<LandSelectionMapScreen> {
  Offset? _selectedPoint;
  String _currentLocName = "Rajanukunte, KA";

  final List<Map<String, dynamic>> _nearLocations = [
    {"name": "BMSIT Institute", "dist": "1.2 km", "lat": 13.1336},
    {"name": "Sai Vidya Engineering", "dist": "0.8 km", "lat": 13.1654},
    {"name": "NMIT Campus", "dist": "2.5 km", "lat": 13.1287},
    {"name": "Doddaballapur Ind.", "dist": "15 km", "lat": 13.2928},
    {"name": "Puttenahalli Lake", "dist": "3.1 km", "lat": 13.1118},
    {"name": "Avalahalli Forest", "dist": "4.2 km", "lat": 13.1020},
    {"name": "Sir M.V. Layout", "dist": "5.5 km", "lat": 13.0850},
    {"name": "Hesaraghatta Lake", "dist": "7.2 km", "lat": 13.1360},
    {"name": "Hebbal Flyover", "dist": "12 km", "lat": 13.0350},
    {"name": "Yelahanka New Town", "dist": "4.1 km", "lat": 13.1007},
    {"name": "Jakur Aerodrome", "dist": "6.8 km", "lat": 13.0750},
    {"name": "GKVK University", "dist": "8.5 km", "lat": 13.0500},
    {"name": "Budigere Cross", "dist": "18 km", "lat": 13.1000},
  ];

  void _onTapMap(TapDownDetails d) {
    setState(() {
      _selectedPoint = d.localPosition;
    });
  }

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
                child: Text("Locations near Rajanukunte", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _nearLocations.length,
                  itemBuilder: (context, index) {
                    final loc = _nearLocations[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.amber),
                      title: Text(loc['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(loc['dist'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      onTap: () {
                        setState(() {
                          _currentLocName = loc['name'];
                          _selectedPoint = Offset(150.0 + (index * 20), 200.0 + (index * 10));
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Digital Topography"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: _onTapMap,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: CustomPaint(
                painter: RajanukunteTopographyPainter(),
                child: Stack(
                   children: [
                     if (_selectedPoint != null)
                      Positioned(
                        left: _selectedPoint!.dx - 15,
                        top: _selectedPoint!.dy - 15,
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.greenAccent, width: 2),
                          ),
                          child: const Center(child: Icon(Icons.location_on, color: Colors.white, size: 16)),
                        ),
                      ),
                   ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 20, left: 20, right: 20,
            child: InkWell(
              onTap: _showSearchSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.amber, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentLocName,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 30, left: 24, right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: Colors.black,
                    mini: true,
                    child: const Icon(Icons.my_location, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedPoint == null ? null : () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const MonitoringDashboardScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Confirm Selection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class RajanukunteTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final highwayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arterialPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final waterPaint = Paint()
      ..color = const Color(0xFF00CED1).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 40) canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    for (double i = 0; i < size.height; i += 40) canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);

    final lakePath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.45, size.width * 0.8, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.65, size.width * 0.65, size.height * 0.5)
      ..close();
    canvas.drawPath(lakePath, waterPaint);

    final highway1 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height);
    canvas.drawPath(highway1, highwayPaint);

    final roads = Path()
      ..moveTo(0, size.height * 0.3)..lineTo(size.width * 0.4, size.height * 0.4)
      ..moveTo(size.width * 0.4, size.height * 0.5)..lineTo(size.width, size.height * 0.6)
      ..moveTo(size.width * 0.2, size.height)..lineTo(size.width * 0.5, 0);
    canvas.drawPath(roads, arterialPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MonitoringDashboardScreen extends StatelessWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Command Center"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSummaryHeader(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Monitoring Modules", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [
                      _buildModuleCard(context, "Crop Health", "https://images.pexels.com/photos/1084542/pexels-photo-1084542.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.eco, Colors.green, "Leaf color & growth"),
                      _buildModuleCard(context, "Soil Monitor", "https://images.pexels.com/photos/4207905/pexels-photo-4207905.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.grass, Colors.brown, "Moisture & NPK"),
                      _buildModuleCard(context, "Irrigation", "https://images.pexels.com/photos/2253013/pexels-photo-2253013.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.water_drop, Colors.blue, "Flow & Schedule"),
                      _buildModuleCard(context, "Weather", "https://images.pexels.com/photos/1118873/pexels-photo-1118873.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.wb_sunny, Colors.lightBlue, "Rain & Forecast"),
                      _buildModuleCard(context, "Pest Detect", "https://images.pexels.com/photos/2607544/pexels-photo-2607544.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.bug_report, Colors.orange, "Population trends"),
                      _buildModuleCard(context, "Equipment", "https://images.pexels.com/photos/162637/tractor-agriculture-farm-machine-162637.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.precision_manufacturing, Colors.blueGrey, "Tractor & Fuel"),
                      _buildModuleCard(context, "Fertilizer", "https://images.pexels.com/photos/4505166/pexels-photo-4505166.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.opacity, Colors.teal, "Nutrient history"),
                      _buildModuleCard(context, "Yield AI", "https://images.pexels.com/photos/1482101/pexels-photo-1482101.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.trending_up, Colors.purple, "Prediction charts"),
                      _buildModuleCard(context, "Field Map", "https://images.pexels.com/photos/1109541/pexels-photo-1109541.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.map, Colors.indigo, "Zoning & Mapping"),
                      _buildModuleCard(context, "Risk Center", "https://images.pexels.com/photos/3551203/pexels-photo-3551203.jpeg?auto=compress&cs=tinysrgb&w=300", Icons.warning, Colors.red, "Drought & Flood"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Field Status: Stable", style: TextStyle(color: Colors.white70, fontSize: 13)),
                   SizedBox(height: 4),
                   Text("Real-Time Data", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.check_circle, color: Colors.greenAccent[400], size: 30),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat("Temp", "28°C", Icons.thermostat),
              _buildHeaderStat("Moisture", "42%", Icons.water_drop),
              _buildHeaderStat("pH", "6.8", Icons.science),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String imgUrl, IconData icon, Color color, String subtitle) {
    return InkWell(
      onTap: () {
         _showModuleDetails(context, title, subtitle, color);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             ClipRRect(
               borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
               child: Image.network(
                 imgUrl, 
                 height: 65, 
                 width: double.infinity, 
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => Container(
                   height: 65, 
                   color: color.withOpacity(0.1),
                   child: Icon(icon, color: color),
                 ),
               ),
             ),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  void _showModuleDetails(BuildContext context, String title, String summary, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$title Analysis", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("AI engine is processing real-time feed from your sensors and field markers.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailCircle(Icons.show_chart, "Progress"),
                  _buildDetailCircle(Icons.auto_awesome, "AI Alert"),
                  _buildDetailCircle(Icons.history, "History"),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Dismiss", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCircle(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.grey[100], child: Icon(icon, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
