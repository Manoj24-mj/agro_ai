from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field
import secrets
import time
from typing import Dict
import uvicorn
import firebase_admin
from firebase_admin import credentials

# Initialize FastAPI app
app = FastAPI(title="Custom OTP System")

# ==============================================================================
# FIREBASE LIMITATION NOTE:
# The Firebase Admin SDK does NOT support sending arbitrary server-to-client SMS.
# Firebase Phone Authentication requires the client (Flutter, JS, iOS, etc.) to 
# initiate the flow (mostly to solve a reCAPTCHA or app verification API) to send the SMS.
# If you want real server-side SMS sending like MSG91/Twilio, you will need to use
# a provider like AWS SNS, Brevo, or Vonage.
#
# Below is the setup for Firebase Admin, but the "send" function is mocked since
# it cannot technically deliver SMS natively without FCM (Push Notifications).
# ==============================================================================

try:
    # Requires serviceAccountKey.json in the same directory
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Warning: Firebase initialization skipped or failed: {e}")

# In-memory storage for OTPs
# Format: { "+1234567890": {"otp": "123456", "created_at": 1612345678} }
otp_storage: Dict[str, dict] = {}

class OTPRequest(BaseModel):
    phone_number: str = Field(..., description="Phone number to send OTP to")

class OTPVerify(BaseModel):
    phone_number: str
    otp: str

def generate_otp() -> str:
    """Generate a 6-digit cryptographically secure OTP."""
    # secrets.randbelow(10) is used to generate each digit securely
    return ''.join(str(secrets.randbelow(10)) for _ in range(6))

def send_sms_via_firebase(phone_number: str, otp: str):
    """
    Placeholder for SMS delivery.
    """
    # [YOUR SMS GATEWAY LOGIC GOES HERE]
    # For testing, we just print the OTP to the console.
    print(f"-------------- SMS DELIVERY --------------")
    print(f"To: {phone_number}")
    print(f"Message: Your verification code is: {otp}")
    print(f"------------------------------------------")

@app.post("/request-otp", status_code=status.HTTP_200_OK)
async def request_otp(data: OTPRequest):
    phone = data.phone_number
    current_time = time.time()
    
    # 1. Security Check: Rate limiting (1 request per 60 seconds)
    if phone in otp_storage:
        last_request_time = otp_storage[phone]["created_at"]
        if current_time - last_request_time < 60:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Please wait 60 seconds before requesting another OTP."
            )
            
    # 2. Generate secure numeric OTP
    otp_code = generate_otp()
    
    # 3. Store in simple cache/dictionary
    otp_storage[phone] = {
        "otp": otp_code,
        "created_at": current_time
    }
    
    # 4. "Send" the SMS
    send_sms_via_firebase(phone, otp_code)
    
    return {"message": "OTP sent successfully."}

@app.post("/verify-otp", status_code=status.HTTP_200_OK)
async def verify_otp(data: OTPVerify):
    phone = data.phone_number
    user_otp = data.otp
    current_time = time.time()
    
    # Check if the generated OTP exists
    if phone not in otp_storage:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OTP not found for this phone number. Please request a new one."
        )
        
    stored_data = otp_storage[phone]
    stored_otp = stored_data["otp"]
    created_at = stored_data["created_at"]
    
    # 1. Verify Expiration: Check if OTP is older than 5 minutes (300 seconds)
    if current_time - created_at > 300:
        del otp_storage[phone]  # Expired, so delete it
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP has expired. Please request a new one."
        )
        
    # 2. Security Check: Compare OTP securely to prevent timing attacks
    if secrets.compare_digest(stored_otp, user_otp):
        # Successful verification: remove OTP from storage to avoid reuse
        del otp_storage[phone]
        return {"message": "OTP verified successfully."}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP."
        )

if __name__ == "__main__":
    # Run server locally
    uvicorn.run(app, host="0.0.0.0", port=8000)
