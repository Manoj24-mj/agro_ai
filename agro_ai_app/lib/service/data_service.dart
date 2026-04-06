import 'dart:async';
import 'dart:math';

class AgroDataService {
  // 🌾 11 CROP CATEGORIES
  static const List<Map<String, dynamic>> cropCategories = [
    {"name": "Cereals", "icon": "🌾"},
    {"name": "Pulses", "icon": "🫘"},
    {"name": "Oilseeds", "icon": "🌻"},
    {"name": "Cash Crops", "icon": "💰"},
    {"name": "Fruits", "icon": "🍎"},
    {"name": "Vegetables", "icon": "🥦"},
    {"name": "Spices & Condiments", "icon": "🌶️"},
    {"name": "Plantation Crops", "icon": "🌴"},
    {"name": "Floriculture Crops", "icon": "🌸"},
    {"name": "Medicinal & Aromatic", "icon": "🌿"},
    {"name": "Fodder Crops", "icon": "🐄"}
  ];

  // 🚜 SCALABLE CROP DATABASE (NEW STRUCTURE)
  static const List<Map<String, dynamic>> cropDatabase = [
    {
      "id": "wheat_01",
      "name": "Wheat",
      "category": "Cereals",
      "scientific_name": "Triticum aestivum",
      "image": "assets/images/wheat.png",
      "growing_conditions": {
        "temperature": "10-25°C",
        "sunlight": "Full Sun",
        "rainfall": "500-750 mm/year",
        "humidity": "40-60%",
        "watering": "Moderate"
      },
      "soil": {
        "type": "Loamy / Clayey Loam",
        "ph": "6.0 - 7.5"
      },
      "spacing": {
        "row_to_row": "22.5 cm",
        "plant_to_plant": "5-7 cm",
        "note": "Drilling method is common for wheat sowing."
      },
      "fertilizer": {
        "N": "50", "P": "25", "K": "25",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Peas", "Beans", "Mustard"],
        "bad": ["None"],
        "explanation": "Legumes fix nitrogen which benefits wheat growth."
      },
      "cultivation": {
        "life_cycle": "Annual",
        "method": "Direct Seeding",
        "labour": "Moderate",
        "season": "Rabi"
      },
      "regions": ["Punjab", "Haryana", "UP", "MP", "Rajasthan"],
      "pests_diseases": ["Rust", "Smut", "Aphids"],
      "tips": "Early sowing in the first fortnight of November is recommended."
    },
    {
      "id": "tomato_01",
      "name": "Tomato",
      "category": "Vegetables",
      "scientific_name": "Solanum lycopersicum",
      "image": "assets/images/tomato.png",
      "growing_conditions": {
        "temperature": "18-27°C",
        "sunlight": "Full Sun",
        "rainfall": "600-1000 mm/year",
        "humidity": "60-70%",
        "watering": "Moderate (Avoid leaf wetness)"
      },
      "soil": {
        "type": "Well-drained Sandy Loam",
        "ph": "6.0 - 6.8"
      },
      "spacing": {
        "row_to_row": "60-75 cm",
        "plant_to_plant": "45-60 cm",
        "note": "Staking is mandatory for indeterminate varieties."
      },
      "fertilizer": {
        "N": "40", "P": "60", "K": "60",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Basil", "Marigold", "Garlic"],
        "bad": ["Cabbage", "Corn", "Potato"],
        "explanation": "Basil improves flavor and Marigold repels pests."
      },
      "cultivation": {
        "life_cycle": "Annual",
        "method": "Transplanting",
        "labour": "High",
        "season": "Year-round"
      },
      "regions": ["Andhra Pradesh", "Karnataka", "Maharashtra", "Tamil Nadu"],
      "pests_diseases": ["Late Blight", "Fruit Borer", "Leaf Minor"],
      "tips": "Prune suckers to improve fruit size and air circulation."
    },
    {
      "id": "mango_01",
      "name": "Mango",
      "category": "Fruits",
      "scientific_name": "Mangifera indica",
      "image": "assets/images/mango.png",
      "growing_conditions": {
        "temperature": "24-30°C",
        "sunlight": "Full Sun",
        "rainfall": "750-2500 mm/year",
        "humidity": "Moderate to High",
        "watering": "High (Young), Low (Mature)"
      },
      "soil": {
        "type": "Alluvial / Loamy",
        "ph": "5.5 - 7.5"
      },
      "spacing": {
        "row_to_row": "8-10 meters",
        "plant_to_plant": "8-10 meters",
        "note": "Ultra-High Density (UHDP) spacing is 3x2 meters."
      },
      "fertilizer": {
        "N": "100", "P": "50", "K": "100",
        "unit": "grams/tree/year"
      },
      "companions": {
        "good": ["Drumstick", "Legumes", "Turmeric"],
        "bad": ["None"],
        "explanation": "Intercropping with legumes fixes soil nitrogen."
      },
      "cultivation": {
        "life_cycle": "Perennial",
        "method": "Grafting",
        "labour": "Moderate",
        "season": "Summer (Harvest)"
      },
      "regions": ["UP", "Andhra Pradesh", "Bihar", "Karnataka"],
      "pests_diseases": ["Mango Hopper", "Mealy Bug", "Anthracnose"],
      "tips": "Smudging helps in uniform flowering in some varieties."
    },
    {
      "id": "maize_01",
      "name": "Maize (Corn)",
      "category": "Cereals",
      "scientific_name": "Zea mays",
      "image": "assets/images/maize.png",
      "growing_conditions": {
        "temperature": "18-27°C",
        "sunlight": "Full Sun",
        "rainfall": "600-1100 mm/year",
        "humidity": "Moderate",
        "watering": "Moderate"
      },
      "soil": {
        "type": "Well-drained Fertile Loam",
        "ph": "5.5 - 7.5"
      },
      "spacing": {
        "row_to_row": "60 cm",
        "plant_to_plant": "20-25 cm",
        "note": "Avoid waterlogging during the early growth stage."
      },
      "fertilizer": {
        "N": "50", "P": "30", "K": "20",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Beans", "Squash", "Pumpkin"],
        "bad": ["None"],
        "explanation": "The Three Sisters: Beans fix nitrogen, Squash covers ground."
      },
      "cultivation": {
        "life_cycle": "Annual",
        "method": "Direct Seeding",
        "labour": "Moderate",
        "season": "Kharif / Rabi"
      },
      "regions": ["Karnataka", "MP", "Bihar", "Andhra Pradesh"],
      "pests_diseases": ["Fall Armyworm", "Stem Borer", "Leaf Blight"],
      "tips": "Earthing up should be done at the 5-6 leaf stage."
    },
    {
      "id": "sugarcane_01",
      "name": "Sugarcane",
      "category": "Cash Crops",
      "scientific_name": "Saccharum officinarum",
      "image": "assets/images/sugarcane.png",
      "growing_conditions": {
        "temperature": "20-30°C",
        "sunlight": "Direct Sunlight",
        "rainfall": "1500-2500 mm/year",
        "humidity": "High",
        "watering": "High"
      },
      "soil": {
        "type": "Loamy / Clayey Loam",
        "ph": "6.5 - 7.5"
      },
      "spacing": {
        "row_to_row": "90-120 cm",
        "plant_to_plant": "30 cm",
        "note": "Wider spacing (150 cm) is used for mechanical harvesting."
      },
      "fertilizer": {
        "N": "100", "P": "40", "K": "40",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Mustard", "Potato", "Moong"],
        "bad": ["None"],
        "explanation": "Intercropping with legumes improves soil health."
      },
      "cultivation": {
        "life_cycle": "Perennial",
        "method": "Setts Planting",
        "labour": "Very High",
        "season": "Annual (12-15 months)"
      },
      "regions": ["UP", "Maharashtra", "Karnataka", "Tamil Nadu"],
      "pests_diseases": ["Red Rot", "Top Borer", "Pyrilla"],
      "tips": "Propping is necessary to prevent lodging during high winds."
    },
    {
      "id": "soybean_01",
      "name": "Soybean",
      "category": "Oilseeds",
      "scientific_name": "Glycine max",
      "image": "assets/images/soybean.png",
      "growing_conditions": {
        "temperature": "20-30°C",
        "sunlight": "Full Sun",
        "rainfall": "600-1000 mm/year",
        "humidity": "Moderate",
        "watering": "Moderate"
      },
      "soil": {
        "type": "Well-drained Loam",
        "ph": "6.0 - 7.5"
      },
      "spacing": {
        "row_to_row": "45 cm",
        "plant_to_plant": "5-10 cm",
        "note": "Avoid planting when the soil is too dry or too wet."
      },
      "fertilizer": {
        "N": "8", "P": "32", "K": "16",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Corn", "Potato", "Cucumber"],
        "bad": ["Garlic", "Onion"],
        "explanation": "Nitrogen fixation benefits companion heavy feeders like corn."
      },
      "cultivation": {
        "life_cycle": "Annual",
        "method": "Direct Seeding",
        "labour": "Moderate",
        "season": "Kharif"
      },
      "regions": ["MP", "Maharashtra", "Rajasthan", "Karnataka"],
      "pests_diseases": ["Girdle Beetle", "Yellow Mosaic Virus"],
      "tips": "Inoculate seeds with Rhizobium culture before sowing."
    },
    {
      "id": "mustard_01",
      "name": "Mustard",
      "category": "Oilseeds",
      "scientific_name": "Brassica juncea",
      "image": "assets/images/mustard.png",
      "growing_conditions": {
        "temperature": "10-25°C",
        "sunlight": "Full Sun",
        "rainfall": "250-400 mm/year",
        "humidity": "Low to Moderate",
        "watering": "Low"
      },
      "soil": {
        "type": "Sandy Loam to Clay Loam",
        "ph": "6.0 - 7.5"
      },
      "spacing": {
        "row_to_row": "30 cm",
        "plant_to_plant": "10-15 cm",
        "note": "Thinning should be done 15-20 days after sowing."
      },
      "fertilizer": {
        "N": "32", "P": "16", "K": "16",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Wheat", "Potato", "Sugarbeet"],
        "bad": ["None"],
        "explanation": "Mustard acts as a trap crop for certain pests when intercropped."
      },
      "cultivation": {
        "life_cycle": "Annual",
        "method": "Direct Seeding (Broadcasting/Line)",
        "labour": "Moderate",
        "season": "Rabi"
      },
      "regions": ["Rajasthan", "Haryana", "MP", "UP", "West Bengal"],
      "pests_diseases": ["Aphids", "White Rust", "Alternaria Blight"],
      "tips": "Sulfur application (10kg/acre) significantly increases oil content."
    },
    {
      "id": "ginger_01",
      "name": "Ginger",
      "category": "Spices & Condiments",
      "scientific_name": "Zingiber officinale",
      "image": "assets/images/ginger.png",
      "growing_conditions": {
        "temperature": "20-30°C",
        "sunlight": "Partial Shade",
        "rainfall": "1500-3000 mm/year",
        "humidity": "High",
        "watering": "High"
      },
      "soil": {
        "type": "Rich Sandy Loam",
        "ph": "6.0 - 6.5"
      },
      "spacing": {
        "row_to_row": "30 cm",
        "plant_to_plant": "15-20 cm",
        "note": "Raised beds are essential to prevent rhizome rot."
      },
      "fertilizer": {
        "N": "30", "P": "20", "K": "20",
        "unit": "kg/acre"
      },
      "companions": {
        "good": ["Turmeric", "Peppers", "Garlic"],
        "bad": ["None"],
        "explanation": "Grows well in the shade of taller spice plants."
      },
      "cultivation": {
        "life_cycle": "Perennial (Annual Cultivation)",
        "method": "Rhizome Planting",
        "labour": "High",
        "season": "Kharif"
      },
      "regions": ["Assam", "Kerala", "Sikkim", "Meghalaya"],
      "pests_diseases": ["Soft Rot", "Leaf Spot", "Shoot Borer"],
      "tips": "Apply heavy mulch immediately after planting to retain moisture."
    },
    {
      "id": "aloe_01",
      "name": "Aloe Vera",
      "category": "Medicinal & Aromatic",
      "scientific_name": "Aloe barbadensis miller",
      "image": "assets/images/aloe.png",
      "growing_conditions": {
        "temperature": "20-35°C",
        "sunlight": "Full Sun to Partial Shade",
        "rainfall": "300-500 mm/year",
        "humidity": "Low",
        "watering": "Very Low (Succulent)"
      },
      "soil": {
        "type": "Well-drained Sandy Soil",
        "ph": "7.0 - 8.5"
      },
      "spacing": {
        "row_to_row": "60 cm",
        "plant_to_plant": "45-60 cm",
        "note": "Overwatering will cause root rot instantly."
      },
      "fertilizer": {
        "N": "10", "P": "10", "K": "10",
        "unit": "kg/acre (Organic preferred)"
      },
      "companions": {
        "good": ["Onion", "Borage", "Pelargonium"],
        "bad": ["None"],
        "explanation": "Onions help deter pests that could attack succulents."
      },
      "cultivation": {
        "life_cycle": "Perennial",
        "method": "Suckers/Pups Planting",
        "labour": "Low",
        "season": "Year-round"
      },
      "regions": ["Rajasthan", "Gujarat", "Tamil Nadu", "Maharashtra"],
      "pests_diseases": ["Mealy Bugs", "Leaf Spot", "Root Rot"],
      "tips": "Harvest only the outermost leaves for continuous production."
    }
  ];

  static List<Map<String, dynamic>> getAllCrops() => cropDatabase;

  static List<Map<String, dynamic>> filterCrops({String? category, String? season, String? query}) {
    var list = cropDatabase;
    if (category != null && category != "All" && category != "Search Results") {
      list = list.where((c) => c["category"] == category).toList();
    }
    if (season != null && season != "All") {
      list = list.where((c) => c["cultivation"]["season"].contains(season)).toList();
    }
    if (query != null && query.isNotEmpty) {
      String q = query.toLowerCase();
      list = list.where((c) => 
        c["name"].toLowerCase().contains(q) || 
        c["scientific_name"].toLowerCase().contains(q) || 
        c["category"].toLowerCase().contains(q) ||
        c["cultivation"]["season"].toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  static Map<String, dynamic>? getCropById(String id) => cropDatabase.firstWhere((c) => c["id"] == id, orElse: () => {});

  static final List<Map<String, dynamic>> diseaseDatabase = [
    {
      "id": "rice_blast",
      "name": "Blast of Rice (Rice Blast)",
      "crop": "Rice (Paddy)",
      "image": "assets/images/rice.png",
      "symptoms": [
        "Diamond-shaped lesions on leaves with gray centers.",
        "Neck rot causing panicles to fall over.",
        "Brown spots on the nodes of the stem.",
        "Complete drying of leaves in severe cases."
      ],
      "prevention": [
        "Avoid excessive use of Nitrogen fertilizers.",
        "Maintain proper water levels to avoid stress.",
        "Ensure field sanitation and remove weed hosts."
      ],
      "organic_control": {
        "agent": "Pseudomonas fluorescens",
        "method": "Seed treatment (10g/kg) and foliar spray at 0.2% concentration.",
        "notes": "Effective if applied preventatively during vegetative stage."
      },
      "chemical_control": {
        "product": "Bavistin (Carbendazim 50% WP)",
        "dosage": "2g per liter of water",
        "active": "Carbendazim",
        "warning": "Apply ONLY ONE chemical treatment at a time. Mixing may cause phytotoxicity."
      },
      "community_q": 12 
    },
    {
      "id": "wheat_rust",
      "name": "Yellow Rust (Wheat)",
      "crop": "Wheat",
      "image": "assets/images/wheat.png",
      "symptoms": [
        "Yellow stripes of pustules on leaves.",
        "Premature leaf drying.",
        "Reduced grain size and shriveling."
      ],
      "prevention": [
        "Use resistant varieties like HD 2967.",
        "Avoid late sowing in November.",
        "Avoid over-irrigation during peak humidity."
      ],
      "organic_control": {
        "agent": "Trichoderma viride",
        "method": "Foliar spray at 5g per liter.",
        "notes": "Focus on ground-level coverage."
      },
      "chemical_control": {
        "product": "Tilt (Propiconazole 25% EC)",
        "dosage": "1ml per liter of water",
        "active": "Propiconazole",
        "warning": "Ensure complete coverage of the canopy for best results."
      },
      "community_q": 8
    }
  ];

  static List<Map<String, dynamic>> getRecommendedCrops(String? state) {
    if (state == null) return cropDatabase;
    return cropDatabase.where((c) => c["regions"].any((r) => r.contains(state))).toList();
  }

  static void submitFeedback(String type, String contentId, String feedback) {
     print("Feedback Logged: $type - $contentId - $feedback");
  }

  // Analytics etc. remain same but can use new data
  static const List<Map<String, dynamic>> alerts = [
    {"region": "Maharashtra / Gujarat", "crop": "Cotton", "severity": "High", "message": "Pink Bollworm attack reported. Use Pheromone traps immediately.", "date": "2026-04-06"},
    {"region": "Punjab / Haryana", "crop": "Wheat", "severity": "Moderate", "message": "Heatwave alert. Increase irrigation frequency.", "date": "2026-04-05"}
  ];

  static const List<Map<String, dynamic>> cultivationTips = [
    {"type": "Seasonal", "content": "During summer, prefer night irrigation to minimize evaporation loss."},
    {"type": "Soil", "content": "Crop rotation with Legumes restores soil nitrogen levels naturally."},
    {"type": "Water", "content": "Laser land leveling can improve water application efficiency by 20%."}
  ];

  static const List<Map<String, dynamic>> fieldTasks = [
    {
      "id": "rice_01",
      "stage": "Seedling",
      "day_range": [0, 15],
      "task": "Nursery Preparation & Sowing",
      "description": "Ensure level nursery beds and apply organic manure.",
      "weatherImpact": "Moderate Rain: Good for germination."
    },
    {
      "id": "rice_02",
      "stage": "Tillering",
      "day_range": [20, 45],
      "task": "Top Dressing (Urea)",
      "description": "Apply first dose of Urea. Ensure thin water layer.",
      "weatherImpact": "Heavy Rain Forecast: Skip application to avoid leaching."
    },
    {
      "id": "rice_03",
      "stage": "Vegetative",
      "day_range": [0, 120],
      "task": "Irrigation Management",
      "description": "Maintain 2-5cm standing water in the field.",
      "weatherTrigger": {
        "heat_wave": "Increase water depth to counter evaporation.",
        "heavy_rain": "Drain excess water to prevent submergence."
      }
    },
    {
      "id": "rice_04",
      "stage": "Monitoring",
      "day_range": [30, 90],
      "task": "Pest & Disease Scouting",
      "description": "Check for Leaf Blast or Stem Borer signs.",
      "weatherTrigger": {
        "high_humidity": "High risk of Fungal Diseases. Inspect leaves closely."
      }
    }
  ];

  static Map<String, dynamic> getAnalytics() {
    return {
      "totalScans": 1500,
      "topDisease": "Pink Bollworm",
      "dislikeRate": "3.5%",
      "alertReach": "1.2 Lakh Farmers",
      "activeUsers": 4200
    };
  }
}
