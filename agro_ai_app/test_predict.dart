import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print('Loading model...');
    final interpreter = await Interpreter.fromAsset('assets/plant_model.tflite');
    print('Model loaded. Input shape: ${interpreter.getInputTensor(0).shape}');
    print('Output shape: ${interpreter.getOutputTensor(0).shape}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
