import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CalculatorScreen extends StatefulWidget {
  final String type; // "Fertilizer", "Pesticide", or "Farming"

  const CalculatorScreen({super.key, required this.type});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _areaController = TextEditingController();
  final _waterController = TextEditingController(text: "200"); // Standard 200L per unit area
  final _doseController = TextEditingController(text: "500"); // Standard dose 
  String _selectedCrop = "Rice";
  String _selectedProduct = "";
  String _selectedAreaUnit = "Hectares";
  String _selectedDosageUnit = "ml"; // ml or kg
  String _result = "";
  Map<String, dynamic>? _lastInputs;

  final List<String> _fertilizers = [
    "Urea", "Ammonium Nitrate", "Ammonium Sulphate", "CAN (Calcium Ammonium Nitrate)",
    "SSP (Single Super Phosphate)", "TSP (Triple Super Phosphate)", "MAP (Mono-Ammonium Phosphate)", "DAP (Di-Ammonium Phosphate)",
    "MOP (Muriate of Potash)", "Potassium Sulphate (SOP)", "Potassium Nitrate",
    "NPK 19:19:19", "NPK 12:32:16", "NPK 10:20:20", "NPK 15:15:15",
    "Magnesium Sulphate", "Zinc Sulphate", "Boron", "Ferrous Sulphate", "Manganese Sulphate", "Gypsum",
    "Vermicompost", "Neem Cake", "Bonemeal", "Bloodmeal", "Fish Emulsion", "Kelp/Seaweed Extract"
  ];
  
  final List<String> _pesticides = [
    "Malathion", "Chlorpyrifos", "Dimethoate", "Acephate",
    "Cypermethrin", "Deltamethrin", "Permethrin", "Bifenthrin",
    "Imidacloprid", "Thiamethoxam", "Acetamiprid",
    "Mancozeb (Fungicide)", "Carbendazim (Fungicide)", "Hexaconazole", "Azoxystrobin", "Tebuconazole", "Copper Oxychloride",
    "Glyphosate (Herbicide)", "Paraquat", "2,4-D", "Atrazine",
    "Neem Oil", "Spinosad", "BT (B. Thuringiensis)", "Pyrethrin", "Abamectin"
  ];

  final List<String> _globalCrops = [
    "Rice", "Wheat", "Maize (Corn)", "Barley", "Oats", "Rye", "Sorghum", "Millet",
    "Soybean", "Chickpea", "Black Gram (Urad)", "Green Gram (Moong)", "Lentil", "Pea", "Peanut", "Kidney Bean",
    "Cotton", "Jute", "Flax", "Hemp",
    "Sugarcane", "Sugar Beet",
    "Sunflower", "Mustard/Rapeseed", "Canola", "Sesame", "Olive",
    "Potato", "Tomato", "Onion", "Cabbage", "Carrot", "Broccoli", "Spinach", "Lettuce", "Pepper", "Eggplant", "Cucumber",
    "Banana", "Mango", "Apple", "Grapes", "Pomegranate", "Orange", "Strawberry", "Pineapple", "Watermelon", "Avocado", "Cherry", "Peach",
    "Coffee", "Tea", "Tobacco", "Cocoa", "Rubber"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.type == "Fertilizer") _selectedProduct = _fertilizers.first;
    if (widget.type == "Pesticide") _selectedProduct = _pesticides.first;
    _selectedCrop = _globalCrops.first;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an area.')));
      return;
    }
    
    setState(() {
      _lastInputs = {
        "area": _areaController.text,
        "areaUnit": _selectedAreaUnit,
        "cropType": _selectedCrop,
        "calculatorType": widget.type,
        "product": _selectedProduct,
        "targetDose": _doseController.text,
        "dosageUnit": _selectedDosageUnit,
        "waterRatio": _waterController.text
      };
      
      double area = double.tryParse(_areaController.text) ?? 1.0;
      double targetDose = double.tryParse(_doseController.text) ?? (widget.type == "Fertilizer" ? 125.0 : 500.0);
      double waterRatio = double.tryParse(_waterController.text) ?? 200.0;

      // Conversion Factors (Internal standard is Hectares)
      // 1 Hectare = 2.47 Acres
      // 1 Acre = 40 Guntas
      // 1 Hectare approx 100 Guntas (actually 98.8)
      
      if (widget.type == "Fertilizer") {
        double totalDose = targetDose * area;
        _result = "Recommended Product: $_selectedProduct\nTotal Quantity: ${totalDose.toStringAsFixed(1)} kg\nFor $_selectedCrop in $area $_selectedAreaUnit";
      } else if (widget.type == "Pesticide") {
        double totalDose = targetDose * area;
        double totalWater = waterRatio * area;
        _result = "Recommended Product: $_selectedProduct\nTotal Dose: ${totalDose.toStringAsFixed(1)} $_selectedDosageUnit\nMix with water: ${totalWater.toStringAsFixed(1)} Liters\nFor $_selectedCrop in $area $_selectedAreaUnit";
      } else {
        // For Yield estimation, we normalize to Hectares to keep existing formulas
        double factor = 1.0;
        if (_selectedAreaUnit == "Acres") factor = 0.4047;
        else if (_selectedAreaUnit == "Guntas") factor = 0.0101;
        
        double areaInHa = area * factor;
        double yieldEst = 3500 * areaInHa;
        double revenue = yieldEst * 20; // 20 per kg
        _result = "Estimated Yield: ${yieldEst.toStringAsFixed(0)} kg\nEstimated Revenue: ₹${revenue.toStringAsFixed(0)}\nFor $_selectedCrop in $area $_selectedAreaUnit";
      }
    });
  }

  void _showFeedbackSheet() {
    String selectedReason = "Incorrect calculation";
    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Why wasn't this helpful?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  items: ["Incorrect calculation", "Hard to understand", "Not relevant", "App bug", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setSheetState(() => selectedReason = val!),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: "Add specific comments... (e.g. calculation is wrong)", 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitFeedback(selectedReason, commentController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("Submit Feedback", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _submitFeedback(String reason, String comment) async {
    try {
      await http.post(
        Uri.parse('http://127.0.0.1:3000/api/feedback'), // Use localhost for web, 10.0.2.2 for android
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "screenName": "${widget.type} Calculator",
          "cropType": _selectedCrop,
          "calculationInputs": _lastInputs,
          "reason": reason,
          "comment": comment
        }),
      ).timeout(const Duration(seconds: 5));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback Submitted! Our AI model will analyze this.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback saved locally. (Backend unavailable)', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text("${widget.type} Calculator", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Calculate for ${widget.type}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCrop,
                      items: _globalCrops.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedCrop = v!),
                      decoration: InputDecoration(
                        labelText: "Crop Type", 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.grass, color: Color(0xFF2E7D32))
                      ),
                    ),
                    if (widget.type != "Farming") ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedProduct,
                        items: (widget.type == "Fertilizer" ? _fertilizers : _pesticides)
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedProduct = v!),
                        decoration: InputDecoration(
                          labelText: "Select ${widget.type}", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(widget.type == "Fertilizer" ? Icons.science : Icons.pest_control, color: const Color(0xFF2E7D32))
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              labelText: "Farm Area", 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.landscape, color: Color(0xFF2E7D32))
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedAreaUnit,
                            items: ["Hectares", "Acres", "Guntas"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => _selectedAreaUnit = v!),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10)
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (widget.type != "Farming") ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _doseController,
                              decoration: InputDecoration(
                                labelText: "Target Dosage", 
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.medication, color: Color(0xFF2E7D32)),
                                suffixText: widget.type == "Fertilizer" ? "kg" : null
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          if (widget.type == "Pesticide") ...[
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _selectedDosageUnit,
                                items: ["ml", "kg"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setState(() => _selectedDosageUnit = v!),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10)
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _waterController,
                        decoration: InputDecoration(
                          labelText: "Water Volume (Liters per area)", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.water_drop, color: Color(0xFF2E7D32)),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      child: const Text("Calculate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              if (_result.isNotEmpty) ...[
                const Text("Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade200, width: 2),
                    boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science, color: Colors.teal, size: 28),
                          const SizedBox(width: 10),
                          const Text("Result", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(_result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text("Was this calculation accurate?", style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                side: BorderSide(color: Colors.grey.shade300)
                              ),
                              icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.green), 
                              label: const Text("Helpful"),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your feedback!')));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade800,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0
                              ),
                              icon: const Icon(Icons.thumb_down, color: Colors.red), 
                              label: const Text("Not Helpful"),
                              onPressed: _showFeedbackSheet,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Colors.teal)
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.teal), 
                          label: const Text("Retry", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() { _result = ""; });
                          },
                        ),
                      )
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
