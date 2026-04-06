import firebase_admin
from firebase_admin import credentials, auth
import sys

def debug_firebase_connection():
    print("=== Firebase Backend Debugger ===")
    
    # 1. Check Credentials
    try:
        cred = credentials.Certificate('serviceAccountKey.json')
        app = firebase_admin.initialize_app(cred)
        print("✅ SUCCESS: Found and loaded serviceAccountKey.json")
        print(f"✅ Project ID: {app.project_id}")
    except FileNotFoundError:
        print("❌ ERROR: serviceAccountKey.json file not found.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ ERROR reading credentials: {e}")
        sys.exit(1)

    # 2. Test Fetching Users (Tests Auth API Access)
    try:
        # Fetching a single user just to see if the Admin SDK has permissions
        page = auth.list_users(max_results=1)
        print("✅ SUCCESS: Authorized to communicate with Firebase Auth API")
    except Exception as e:
        print(f"❌ ERROR: Cannot reach Firebase Auth. Details: {e}")

    print("\n=== 🛑 CRITICAL FIREBASE LIMITATIONS INFO ===")
    print("The Firebase Admin SDK (Python) CANNOT programmatically query your:")
    print("  - SMS Verification Limits / Quotas")
    print("  - App Check Configuration Status")
    print("  - reCAPTCHA backend settings")
    print("\nThese are security and billing configurations restricted to the Google Cloud Console.")
    print("To debug SMS non-delivery, please manually verify the following in the Firebase Console:")
    print("1. Authentication -> Settings -> SMS quota: Ensure you haven't hit the daily free limit (10,000/month or specific daily IPs).")
    print("2. Authentication -> Sign-in method -> Phone: Ensure it is ENABLED.")
    print("3. App Check: Check if App Check is enforcing tokens and discarding invalid traffic.")
    print("4. Google Cloud Console -> Identity Platform -> Settings -> Quotas: Review your SMS API quotas.")

if __name__ == "__main__":
    debug_firebase_connection()
