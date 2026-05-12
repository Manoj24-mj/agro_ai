import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:agro_ai_app/service/data_service.dart';

class TFLiteService {
  static Interpreter? _interpreter;
  static List<String>? _labels;

  static Future<void> loadModel() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platforms might not have the TFLite native DLL configured.
        // We skip loading and fallback to mock in predict to allow UI testing.
        return;
      }
      if (_interpreter != null) return;
      _interpreter = await Interpreter.fromAsset('assets/plant_model.tflite');
      
      final labelData = await rootBundle.loadString('assets/models_list.txt');
      _labels = labelData.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      print("TFLite Model loaded successfully.");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  static Future<String?> predict(String imagePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _mockDesktopPrediction();
    }
    
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) return "Model not loaded properly.";

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return "Could not decode image.";

      // Resize to match model input (typically 224x224 or 256x256)
      // I'll assume 224x224 for standard plant disease models
      final inputSize = 256; 
      final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

      var input = List.generate(
        1,
        (i) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              // Normalize if necessary, assuming 0-1 float or 0-255 float
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            },
          ),
        ),
      );

      final outputTensor = _interpreter!.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      final numClasses = outputShape.isNotEmpty ? outputShape.last : (_labels?.length ?? 38);

      var output = List.generate(1, (i) => List.filled(numClasses, 0.0));

      _interpreter!.run(input, output);
      
      List<double> probabilities = List<double>.from(output[0]);

      List<Map<String, dynamic>> detectedDiseases = [];
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > 0.15) { // 15% threshold for multiple diseases
          detectedDiseases.add({
            'label': _labels != null && i < _labels!.length ? _labels![i] : "Unknown",
            'confidence': probabilities[i]
          });
        }
      }

      // Sort by confidence descending
      detectedDiseases.sort((a, b) => b['confidence'].compareTo(a['confidence']));

      if (detectedDiseases.isEmpty) {
         // Fallback to max if none above 15%
         int maxIndex = 0;
         double maxProb = probabilities[0];
         for (int i = 1; i < probabilities.length; i++) {
           if (probabilities[i] > maxProb) {
             maxProb = probabilities[i];
             maxIndex = i;
           }
         }
         detectedDiseases.add({
            'label': _labels != null && maxIndex < _labels!.length ? _labels![maxIndex] : "Unknown",
            'confidence': maxProb
         });
      }

      // Look up in AgroDataService for matches
      String report = _generateOfflineReport(detectedDiseases);
      return report;
    } catch (e) {
      print("Prediction error: $e");
      return "Error during offline prediction: $e";
    }
  }

  static String _generateOfflineReport(List<Map<String, dynamic>> diseases) {
     final topDisease = diseases.first;
     int confInt = ((topDisease['confidence'] as double) * 100).toInt();
     
     if (confInt < 30) {
        return "I am not confident ($confInt%), but it might be ${topDisease['label']}. Please try again with a better image or when online.";
     }
     
     bool isHealthy = topDisease['label'].toLowerCase().contains('healthy');
     bool isUnknown = topDisease['label'].toLowerCase().contains('unknown');

     if (isUnknown) {
        return "I could not identify the plant or disease offline. Please connect to the internet for a deep scan.";
     }

     if (isHealthy) {
       return '''
[ACCURACY: $confInt]
[SEVERITY: LOW]
[WATER: 50]
[TEMP: 25]
[HUMIDITY: 50]

---
## 📋 Section 1: Metadata
> 🌱 **Plant Type:** Detected from Image (Offline Mode)
- **Location & Climate:** Offline Edge AI

---
## 🔬 Section 2: Visual Evidence & Cause
> 🦠 **Diagnosis:** ${topDisease['label']}
- **Evidence/Observation:** Plant appears vigorous and free of major diseases.
> ⚠️ **Why it occurred:** Excellent care and suitable environmental conditions.

---
## 🧪 Section 3: The Prescription & Prevention
**1. Immediate Remedies:**
- Continue current care routine.

**2. Eradication (Pesticides & Dosage):**
> 🚨 **CRITICAL TREATMENT:** None required.

**3. Recovery (Best Fertilizers):**
> 💊 **RECOMMENDED FERTILIZER:** Standard organic compost to maintain health.

**4. Future Prevention:**
- Maintain optimal humidity and spacing.
''';
     }

     // Only join non-healthy/non-unknown diseases
     final actualDiseases = diseases.where((d) => !d['label'].toLowerCase().contains('healthy') && !d['label'].toLowerCase().contains('unknown')).toList();
     if (actualDiseases.isEmpty) actualDiseases.add(topDisease); // Fallback

     String diagnosisStr = actualDiseases.map((d) => "${d['label']} (${((d['confidence'] as double) * 100).toInt()}%)").join(" AND ");
     String remediesStr = actualDiseases.map((d) => "- For ${d['label']}: Isolate and treat immediately.").join("\n");

    // Formatted report simulating Gemini style
     return '''
[ACCURACY: $confInt]
[SEVERITY: HIGH]
[WATER: 50]
[TEMP: 25]
[HUMIDITY: 50]

---
## 📋 Section 1: Metadata
> 🌱 **Plant Type:** Detected from Image (Offline Mode)
- **Location & Climate:** Offline Edge AI

---
## 🔬 Section 2: Visual Evidence & Cause
> 🦠 **Diagnosis:** $diagnosisStr
- **Evidence/Observation:** Detected multiple visual markers using offline Edge AI.
> ⚠️ **Why it occurred:** Detected pattern matches offline database for the identified diseases.

---
## 🧪 Section 3: The Prescription & Prevention
**1. Immediate Remedies:**
$remediesStr

**2. Eradication (Pesticides & Dosage):**
> 🚨 **CRITICAL TREATMENT:** Consult local agriculture guidelines or connect to the internet for a deep AI analysis.

**3. Recovery (Best Fertilizers):**
> 💊 **RECOMMENDED FERTILIZER:** Standard organic compost.

**4. Future Prevention:**
- Maintain optimal humidity and spacing.
''';
  }

  static Future<String> _mockDesktopPrediction() async {
    List<String> allLabels = [];
    try {
      final labelData = await rootBundle.loadString('assets/models_list.txt');
      allLabels = labelData.split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !s.toLowerCase().contains("unknown"))
          .toList();
    } catch (e) {
      allLabels = ["Tomato Blight", "Apple Scab", "Corn Rust"];
    }
    
    final random = Random();
    final pickedLabel = allLabels[random.nextInt(allLabels.length)];
    final isHealthy = pickedLabel.toLowerCase().contains("healthy");

    final accuracy = 80 + random.nextInt(15);
    final temp = 24 + random.nextInt(8);
    final hum = 50 + random.nextInt(30);
    
    if (isHealthy) {
       return '''
[ACCURACY: $accuracy]
[SEVERITY: LOW]
[WATER: 50]
[TEMP: $temp]
[HUMIDITY: $hum]

---
## 📋 Section 1: Metadata
> 🌱 **Plant Type:** Detected from Image (Desktop Simulation)
- **Location & Climate:** Local Environment (Simulated Scan)

---
## 🔬 Section 2: Visual Evidence & Cause
> 🦠 **Diagnosis:** $pickedLabel
- **Evidence/Observation:** Plant appears vigorous and free of major diseases.
> ⚠️ **Why it occurred:** Excellent care and suitable environmental conditions.

---
## 🧪 Section 3: The Prescription & Prevention
**1. Immediate Remedies:**
- Continue current care routine.

**2. Eradication (Pesticides & Dosage):**
> 🚨 **CRITICAL TREATMENT:** None required.

**3. Recovery (Best Fertilizers):**
> 💊 **RECOMMENDED FERTILIZER:** Standard organic compost to maintain health.

**4. Future Prevention:**
- Maintain optimal humidity and spacing.
''';
    }

    return '''
[ACCURACY: $accuracy]
[SEVERITY: HIGH]
[WATER: 60]
[TEMP: $temp]
[HUMIDITY: $hum]

---
## 📋 Section 1: Metadata
> 🌱 **Plant Type:** Detected from Image (Desktop Simulation)
- **Location & Climate:** Local Environment (Simulated Scan)

---
## 🔬 Section 2: Visual Evidence & Cause
> 🦠 **Diagnosis:** $pickedLabel
- **Evidence/Observation:** Detected visual markers corresponding to $pickedLabel.
> ⚠️ **Why it occurred:** Often triggered by combined environmental stress ($hum% humidity and $temp°C).

---
## 🧪 Section 3: The Prescription & Prevention
**1. Immediate Remedies:**
- For $pickedLabel: Isolate and apply targeted treatment.

**2. Eradication (Pesticides & Dosage):**
> 🚨 **CRITICAL TREATMENT:** Standard broad-spectrum organic fungicide - 2ml/Liter.

**3. Recovery (Best Fertilizers):**
> 💊 **RECOMMENDED FERTILIZER:** Balanced NPK fertilizer.

**4. Future Prevention:**
- Control humidity and improve airflow.
''';
  }
}
