import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:agro_ai_app/localization.dart';
import 'package:agro_ai_app/widgets/searchable_picker.dart';

class CropPriceScreen extends StatefulWidget {
  const CropPriceScreen({super.key});

  @override
  State<CropPriceScreen> createState() => _CropPriceScreenState();
}

class _CropPriceScreenState extends State<CropPriceScreen> {
  String? _selectedCrop;
  String _selectedDuration = "3w"; // default timeframe

  @override
  void initState() {
    super.initState();
    // Sort crop data alphabetically
    _cropData.sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
  }

  final List<Map<String, dynamic>> _cropData = [
    // GRAINS
    {"name": "Rice", "price": 2850, "unit": "q", "history": {"1d": 2810, "3d": 2750, "3w": 2600}, "trend": "up", "change": "+₹40"},
    {"name": "Wheat", "price": 2240, "unit": "q", "history": {"1d": 2250, "3d": 2280, "3w": 2350}, "trend": "down", "change": "-₹10"},
    {"name": "Maize (Corn)", "price": 1980, "unit": "q", "history": {"1d": 1960, "3d": 1920, "3w": 1850}, "trend": "up", "change": "+₹20"},
    {"name": "Barley", "price": 1850, "unit": "q", "history": {"1d": 1840, "3d": 1800, "3w": 1750}, "trend": "up", "change": "+₹10"},
    {"name": "Oats", "price": 2150, "unit": "q", "history": {"1d": 2160, "3d": 2200, "3w": 2300}, "trend": "down", "change": "-₹10"},
    {"name": "Quinoa", "price": 15000, "unit": "q", "history": {"1d": 14800, "3d": 14200, "3w": 13000}, "trend": "up", "change": "+₹200"},
    {"name": "Sorghum", "price": 2450, "unit": "q", "history": {"1d": 2420, "3d": 2350, "3w": 2200}, "trend": "up", "change": "+₹30"},
    {"name": "Millet", "price": 2700, "unit": "q", "history": {"1d": 2680, "3d": 2600, "3w": 2450}, "trend": "up", "change": "+₹20"},

    // LEGUMES & PULSES
    {"name": "Soybean", "price": 4350, "unit": "q", "history": {"1d": 4380, "3d": 4450, "3w": 4600}, "trend": "down", "change": "-₹30"},
    {"name": "Chickpea", "price": 4950, "unit": "q", "history": {"1d": 4950, "3d": 4900, "3w": 4800}, "trend": "stable", "change": "₹0"},
    {"name": "Lentil", "price": 6200, "unit": "q", "history": {"1d": 6150, "3d": 6000, "3w": 5800}, "trend": "up", "change": "+₹50"},
    {"name": "Peanut", "price": 5800, "unit": "q", "history": {"1d": 5750, "3d": 5600, "3w": 5400}, "trend": "up", "change": "+₹50"},
    {"name": "Kidney Bean", "price": 8500, "unit": "q", "history": {"1d": 8400, "3d": 8100, "3w": 7500}, "trend": "up", "change": "+₹100"},

    // TUBERS & ROOTS
    {"name": "Potato", "price": 1250, "unit": "q", "history": {"1d": 1300, "3d": 1400, "3w": 1600}, "trend": "down", "change": "-₹50"},
    {"name": "Sweet Potato", "price": 2200, "unit": "q", "history": {"1d": 2150, "3d": 2000, "3w": 1800}, "trend": "up", "change": "+₹50"},
    {"name": "Cassava", "price": 3100, "unit": "q", "history": {"1d": 3050, "3d": 2900, "3w": 2700}, "trend": "up", "change": "+₹50"},

    // FRUITS
    {"name": "Apple", "price": 11500, "unit": "q", "history": {"1d": 11500, "3d": 11400, "3w": 11000}, "trend": "stable", "change": "₹0"},
    {"name": "Banana", "price": 2600, "unit": "q", "history": {"1d": 2550, "3d": 2400, "3w": 2200}, "trend": "up", "change": "+₹50"},
    {"name": "Mango", "price": 4800, "unit": "q", "history": {"1d": 5200, "3d": 5800, "3w": 7000}, "trend": "down", "change": "-₹400"},
    {"name": "Orange", "price": 5200, "unit": "q", "history": {"1d": 5100, "3d": 4900, "3w": 4500}, "trend": "up", "change": "+₹100"},
    {"name": "Avocado", "price": 35000, "unit": "q", "history": {"1d": 34000, "3d": 32000, "3w": 28000}, "trend": "up", "change": "+₹1000"},
    {"name": "Pineapple", "price": 5800, "unit": "q", "history": {"1d": 5700, "3d": 5500, "3w": 5000}, "trend": "up", "change": "+₹100"},
    {"name": "Strawberry", "price": 18000, "unit": "q", "history": {"1d": 18500, "3d": 19500, "3w": 22000}, "trend": "down", "change": "-₹500"},
    {"name": "Grapes", "price": 3800, "unit": "q", "history": {"1d": 3900, "3d": 4100, "3w": 4500}, "trend": "down", "change": "-₹100"},

    // VEGETABLES
    {"name": "Tomato", "price": 1600, "unit": "q", "history": {"1d": 1800, "3d": 2200, "3w": 3000}, "trend": "down", "change": "-₹200"},
    {"name": "Onion", "price": 2400, "unit": "q", "history": {"1d": 2200, "3d": 1800, "3w": 1200}, "trend": "up", "change": "+₹200"},
    {"name": "Onion (Red)", "price": 2600, "unit": "q", "history": {"1d": 2400, "3d": 2000, "3w": 1400}, "trend": "up", "change": "+₹200"},
    {"name": "Garlic", "price": 12000, "unit": "q", "history": {"1d": 11500, "3d": 10500, "3w": 9000}, "trend": "up", "change": "+₹500"},
    {"name": "Cabbage", "price": 1400, "unit": "q", "history": {"1d": 1350, "3d": 1250, "3w": 1100}, "trend": "up", "change": "+₹50"},
    {"name": "Broccoli", "price": 8200, "unit": "q", "history": {"1d": 8000, "3d": 7600, "3w": 7000}, "trend": "up", "change": "+₹200"},
    {"name": "Carrot", "price": 3500, "unit": "q", "history": {"1d": 3500, "3d": 3400, "3w": 3200}, "trend": "stable", "change": "₹0"},

    // FIBER & INDUSTRIAL
    {"name": "Cotton", "price": 7100, "unit": "q", "history": {"1d": 7000, "3d": 6800, "3w": 6500}, "trend": "up", "change": "+₹100"},
    {"name": "Jute", "price": 5500, "unit": "q", "history": {"1d": 5450, "3d": 5300, "3w": 5000}, "trend": "up", "change": "+₹50"},
    {"name": "Sugarcane", "price": 340, "unit": "q", "history": {"1d": 340, "3d": 335, "3w": 320}, "trend": "stable", "change": "₹0"},
    {"name": "Rubber", "price": 16500, "unit": "q", "history": {"1d": 16200, "3d": 15500, "3w": 14500}, "trend": "up", "change": "+₹300"},
    {"name": "Tobacco", "price": 14500, "unit": "q", "history": {"1d": 14200, "3d": 13800, "3w": 12500}, "trend": "up", "change": "+₹300"},

    // BEVERAGES & SPICES
    {"name": "Coffee (Arabica)", "price": 22000, "unit": "q", "history": {"1d": 21500, "3d": 20500, "3w": 18000}, "trend": "up", "change": "+₹500"},
    {"name": "Coffee (Robusta)", "price": 18000, "unit": "q", "history": {"1d": 17800, "3d": 17200, "3w": 16000}, "trend": "up", "change": "+₹200"},
    {"name": "Tea", "price": 17500, "unit": "q", "history": {"1d": 17800, "3d": 18500, "3w": 20000}, "trend": "down", "change": "-₹300"},
    {"name": "Cocoa", "price": 24000, "unit": "q", "history": {"1d": 23500, "3d": 22000, "3w": 19000}, "trend": "up", "change": "+₹500"},
    {"name": "Turmeric", "price": 8200, "unit": "q", "history": {"1d": 8000, "3d": 7600, "3w": 7000}, "trend": "up", "change": "+₹200"},
    {"name": "Ginger", "price": 16500, "unit": "q", "history": {"1d": 17000, "3d": 18500, "3w": 22000}, "trend": "down", "change": "-₹500"},
    {"name": "Cardamom", "price": 145000, "unit": "q", "history": {"1d": 142000, "3d": 135000, "3w": 120000}, "trend": "up", "change": "+₹3000"},
    {"name": "Vanilla", "price": 320000, "unit": "q", "history": {"1d": 315000, "3d": 300000, "3w": 270000}, "trend": "up", "change": "+₹5000"},
  ];

  Widget _buildHistoryRow(String label, int pastPrice, int currentPrice) {
    int diff = currentPrice - pastPrice;
    bool isUp = diff >= 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Row(
            children: [
              Text("₹$pastPrice", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: isUp ? Colors.green : Colors.red),
              Text(
                "${isUp ? '+' : ''}$diff", 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isUp ? Colors.green : Colors.red)
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedData = _selectedCrop != null 
        ? _cropData.firstWhere((c) => c["name"] == _selectedCrop)
        : null;

    int pastPrice = 0;
    String durationLabel = "3 Weeks";
    if (selectedData != null) {
      if (_selectedDuration == "1d") {
        pastPrice = selectedData["history"]["1d"];
        durationLabel = Lang.t("1 Day");
      } else if (_selectedDuration == "3d") {
        pastPrice = selectedData["history"]["3d"];
        durationLabel = Lang.t("3 Days");
      } else {
        pastPrice = selectedData["history"]["3w"];
        durationLabel = Lang.t("3 Weeks");
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(Lang.t("prices_btn"), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF2E7D32).withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Lang.t("market_insights"),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                Lang.t("select_crop"),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              
              // Crop Selector
              _buildSearchableSelector(
                label: Lang.t("choose_crop"),
                value: _selectedCrop != null ? Lang.t(_selectedCrop!) : Lang.t("choose_crop"),
                icon: Icons.grass,
                items: _cropData.map((e) => e["name"] as String).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCrop = val;
                  });
                },
              ),
              
              const SizedBox(height: 40),
              
              if (selectedData != null) ...[
                // Duration Pulse Selector
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        fillColor: const Color(0xFF2E7D32),
                        selectedColor: Colors.white,
                        color: Colors.black54,
                        isSelected: [_selectedDuration == "1d", _selectedDuration == "3d", _selectedDuration == "3w"],
                        onPressed: (index) {
                          setState(() {
                            if (index == 0) _selectedDuration = "1d";
                            if (index == 1) _selectedDuration = "3d";
                            if (index == 2) _selectedDuration = "3w";
                          });
                        },
                        children: [
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(Lang.t("1 Day"))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(Lang.t("3 Days"))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(Lang.t("3 Weeks"))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Price Card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2), width: 2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        Lang.t(selectedData["name"]),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "₹${selectedData["price"]}/${Lang.t(selectedData["unit"])}",
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedData["trend"] == "up" 
                                ? Icons.trending_up 
                                : selectedData["trend"] == "down" 
                                    ? Icons.trending_down 
                                    : Icons.trending_flat,
                            color: selectedData["trend"] == "up" 
                                ? Colors.green 
                                : selectedData["trend"] == "down" 
                                    ? Colors.red 
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedData["change"],
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: selectedData["trend"] == "up" 
                                  ? Colors.green 
                                  : selectedData["trend"] == "down" 
                                      ? Colors.red 
                                      : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // History Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Lang.t("hist_comparison"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildHistoryRow(Lang.t("1_day_ago"), selectedData["history"]["1d"], selectedData["price"]),
                      const Divider(),
                      _buildHistoryRow(Lang.t("3_days_ago"), selectedData["history"]["3d"], selectedData["price"]),
                      const Divider(),
                      _buildHistoryRow(Lang.t("3_weeks_ago"), selectedData["history"]["3w"], selectedData["price"]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // AI Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "The price of ${selectedData["name"]} has ${selectedData["price"] >= pastPrice ? "increased" : "decreased"} by ${((selectedData["price"] - pastPrice).abs() / pastPrice * 100).toStringAsFixed(1)}% since $durationLabel ago.",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Note: Prices may vary slightly by local mandi.",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              ] else ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 20),
                    const Text(
                      "No crop selected",
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableSelector({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () {
        SearchablePicker.show(
          context,
          title: label,
          items: items,
          selectedItem: value,
          onSelected: onChanged,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selected Crop", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
