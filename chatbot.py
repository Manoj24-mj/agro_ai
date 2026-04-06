def chatbot_response(msg):
    msg = msg.lower()

    # General Knowledge Base for Plant Diseases and Care
    knowledge = {
        "yellow leaves": "Yellowing leaves (Chlorosis) can be caused by nitrogen deficiency, overwatering, or lack of sunlight. Check soil moisture first.",
        "brown leaves": "Brown, crispy edges often indicate underwatering, low humidity, or salt buildup from fertilizer.",
        "spots": "Dark, water-soaked spots could be a bacterial infection. Remove infected leaves and avoid overhead watering.",
        "white fuzzy": "White, flour-like spots are likely Powdery Mildew. Treatment: Spray a mixture of baking soda, water, and a drop of dish soap.",
        "rust": "Orange or reddish-brown pustules on the underside of leaves indicate Rust. Prune infected parts and use a copper-based fungicide.",
        "tomato": "For tomatoes, watch out for Early Blight (brown spots with rings) or Late Blight (water-soaked patches). Ensure good air circulation.",
        "urea": "Urea is a great nitrogen source. Apply it carefully to the base of the plant to avoid 'burning' the leaves.",
        "healthy": "Your plant looks great! Continue with regular watering and ensure it gets enough sunlight.",
        "who are you": "I am your Agro AI Doctor, an expert in plant pathology and agricultural care. How can I help your garden today?",
        "help": "You can ask about symptoms like 'yellow leaves', 'rust', 'white spots', or specific plants like 'tomato'."
    }

    # Heuristic matching
    for key, response in knowledge.items():
        if key in msg:
            return response

    return "I'm not quite sure about that symptom. Could you provide more details, or perhaps take a photo of the leaf so I can diagnose it?"