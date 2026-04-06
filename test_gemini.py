import requests
import json

# Set your API key
API_KEY = "AIzaSyB_DIdaVU_jJnuafxqS89Pn73WZp-9gCUY"

def list_models():
    print("--- Listing Available Models (v1) ---")
    url = f"https://generativelanguage.googleapis.com/v1/models?key={API_KEY}"
    response = requests.get(url)
    if response.status_code == 200:
        models = response.json().get('models', [])
        for m in models:
            print(f"- {m['name']} ({m.get('displayName', 'No Display Name')})")
    else:
        print(f"Error listing models (v1): {response.status_code} - {response.text}")

    print("\n--- Listing Available Models (v1beta) ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"
    response = requests.get(url)
    if response.status_code == 200:
        models = response.json().get('models', [])
        for m in models:
            print(f"- {m['name']} ({m.get('displayName', 'No Display Name')})")
    else:
        print(f"Error listing models (v1beta): {response.status_code} - {response.text}")

def test_chat():
    print("\n--- Testing Gemini 1.5 Flash (v1) ---")
    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key={API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": "Hi, are you working?"}]}]
    }
    response = requests.post(url, json=payload)
    if response.status_code == 200:
        print("Success! Gemini 1.5 Flash is working on v1.")
        print("Response:", response.json()['candidates'][0]['content']['parts'][0]['text'])
    else:
        print(f"Failed on v1: {response.status_code} - {response.text}")
        
    print("\n--- Testing Gemini 1.5 Flash (v1beta) ---")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"
    response = requests.post(url, json=payload)
    if response.status_code == 200:
        print("Success! Gemini 1.5 Flash is working on v1beta.")
        print("Response:", response.json()['candidates'][0]['content']['parts'][0]['text'])
    else:
        print(f"Failed on v1beta: {response.status_code} - {response.text}")

if __name__ == "__main__":
    list_models()
    test_chat()
