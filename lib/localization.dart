class Lang {
  static Map<String, Map<String, String>> data = {
    "en": {
      "title": "Agro AI Doctor 🌱",
      "chat_btn": "Chat with AI Bot",
      "weather_btn": "Check Weather",
      "temp": "Temperature",
      "humidity": "Humidity",
      "welcome": "Welcome! I am your Agro AI Doctor. How can I help you today?",
      "type_msg": "Type a message...",
      "offline": "Offline Mode",
      "online": "Online Mode",
      "good_morning": "Good Morning ☀️",
      "good_afternoon": "Good Afternoon 🌤️",
      "good_evening": "Good Evening 🌙",
      "good_night": "Good Night 😴",
      "thinking": "Thinking...",
      "analyzing": "Analyzing plant...",
      "detector_btn": "Detector",
      "detector_title": "Plant Disease Detector",
    },
    "kn": {
      "title": "ಅಗ್ರೋ ಎಐ ಡಾಕ್ಟರ್ 🌱",
      "chat_btn": "ಎಐ ಬೋಟ್‌ನೊಂದಿಗೆ ಮಾತನಾಡಿ",
      "weather_btn": "ಹವಾಮಾನ ಪರೀಕ್ಷಿಸಿ",
      "temp": "ತಾಪಮಾನ",
      "humidity": "ಆರ್ದ್ರತೆ",
      "welcome": "ಸ್ವಾಗತ! ನಾನು ನಿಮ್ಮ ಅಗ್ರೋ ಎಐ ಡಾಕ್ಟರ್. ಇಂದು ನಾನು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?",
      "type_msg": "ಸಂದೇಶವನ್ನು ಟೈಪ್ ಮಾಡಿ...",
      "offline": "ಆಫ್‌ಲೈನ್ ಮೋಡ್",
      "online": "ಆನ್‌ಲೈನ್ ಮೋಡ್",
      "good_morning": "ಶುಭೋದಯ ☀️",
      "good_afternoon": "ಶುಭ ಮಧ್ಯಾಹ್ನ 🌤️",
      "good_evening": "ಶುಭ ಸಂಜೆ 🌙",
      "good_night": "ಶುಭ ರಾತ್ರಿ 😴",
      "thinking": "ಆಲೋಚಿಸುತ್ತಿದೆ...",
      "analyzing": "ಸಸ್ಯವನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತಿದೆ...",
      "detector_btn": "ಡಿಟೆಕ್ಟರ್",
      "detector_title": "ಸಸ್ಯ ರೋಗ ಡಿಟೆಕ್ಟರ್",
    },
    "hi": {
      "title": "एग्रो एआई डॉक्टर 🌱",
      "chat_btn": "एआई बॉट से चैट करें",
      "weather_btn": "मौसम की जाँच करें",
      "temp": "तापमान",
      "humidity": "नमी",
      "welcome": "स्वागत है! मैं आपका एग्रो एआई डॉक्टर हूं। आज मैं आपकी कैसे मदद कर सकता हूं?",
      "type_msg": "संदेश टाइप करें...",
      "offline": "ऑफलाइन मोड",
      "online": "ऑनलाइन मोड",
      "good_morning": "शुभ प्रभात ☀️",
      "good_afternoon": "शुभ दोपहर 🌤️",
      "good_evening": "शुभ संध्या 🌙",
      "good_night": "शुभ रात्रि 😴",
      "thinking": "सोच रहा हूँ...",
      "analyzing": "पौधे का विश्लेषण कर रहा हूँ...",
      "detector_btn": "डिटेक्टर",
      "detector_title": "पादप रोग डिटेक्टर",
    }
  };

  static String lang = "en";

  static String t(String key) {
    return data[lang]?[key] ?? key;
  }
  
  static void setLang(String l) {
    lang = l;
  }
}