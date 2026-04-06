import secrets
import time
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

# Tries to import android_sms_gateway. Will still work via console print if it fails.
try:
    from android_sms_gateway import client, domain
    ANDROID_GATEWAY_AVAILABLE = True
except ImportError:
    ANDROID_GATEWAY_AVAILABLE = False

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------------- CONFIGURATION -----------------
# Get your username/password by installing 'Android SMS Gateway'
# from Google Play Store: https://play.google.com/store/apps/details?id=com.capita.sms_gateway
SMSGATE_LOGIN = "your_username"
SMSGATE_PASSWORD = "your_password"

# ----------------- DATABASES (In-Memory) ----------
otp_db = {}
users_db = {"+911234567890": {"name": "Admin User", "password": "password123"}}
sms_history = []  # Logs SMS for the HTML Dashboard

# ----------------- MODELS ------------------------
class PhoneInput(BaseModel):
    phone: str

class OtpRequestInput(BaseModel):
    phone: str
    method: Optional[str] = "sms"

class VerifyInput(BaseModel):
    phone: str
    otp: str

class RegisterInput(BaseModel):
    phone: str
    otp: str
    name: str
    password: str

class LoginInput(BaseModel):
    phone: str
    password: str

class ResetPasswordInput(BaseModel):
    phone: str
    otp: str
    new_name: str
    new_password: str

# ----------------- ROUTES ------------------------
@app.get("/dashboard", response_class=HTMLResponse)
async def get_dashboard():
    """Simple HTML Dashboard to view sent SMS records"""
    html_rows = ""
    for msg in reversed(sms_history):
        # Apply CSS classes based on status
        status_class = "status-simulated"
        if "sent" in msg['status'].lower():
            status_class = "status-sent"
        elif "error" in msg['status'].lower():
            status_class = "status-error"
            
        html_rows += f"""
        <tr>
            <td>{msg['time']}</td>
            <td>{msg['phone']}</td>
            <td>{msg['otp']}</td>
            <td class="{status_class}">{msg['status']}</td>
        </tr>
        """
        
    html_content = f"""
    <html>
        <head>
            <title>SMS Gateway Dashboard</title>
            <style>
                body {{ font-family: 'Segoe UI', Arial, sans-serif; padding: 20px; background-color: #f9f9f9; }}
                .container {{ max-width: 900px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }}
                h1 {{ color: #2E7D32; border-bottom: 2px solid #e0e0e0; padding-bottom: 10px; }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
                th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
                th {{ background-color: #2E7D32; color: white; }}
                .status-sent {{ color: green; font-weight: bold; }}
                .status-simulated {{ color: #f57c00; font-weight: bold; }}
                .status-error {{ color: red; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📱 Private SMS Gateway Dashboard</h1>
                <p>Monitor active OTPs being routed through your Android Phone via Hardware Bridge.</p>
                <table>
                    <tr>
                        <th>Time</th>
                        <th>Phone Number</th>
                        <th>OTP Code</th>
                        <th>Delivery Status</th>
                    </tr>
                    {html_rows if html_rows else "<tr><td colspan='4' style='text-align:center;'>No messages sent yet. Trigger OTP in the app!</td></tr>"}
                </table>
            </div>
        </body>
    </html>
    """
    return html_content

@app.post("/check-user")
async def check_user(data: PhoneInput):
    phone = data.phone
    if phone in users_db:
        return {"exists": True, "name": users_db[phone]["name"]}
    return {"exists": False}


@app.post("/send-otp")
async def request_otp(data: OtpRequestInput):
    phone = data.phone
    
    # Generate 6-digit OTP
    new_otp = "".join([str(secrets.randbelow(10)) for _ in range(6)])
    expiry = time.time() + 300 # 5 mins
    otp_db[phone] = {"otp": new_otp, "expires_at": expiry}
    
    current_time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
    status = "Simulated (Terminal Only)"
    
    print("\n" + "="*40)
    print(f"🚀 CUSTOM OTP SYSTEM (MSG91 STYLE)")
    print(f"📱 SENDER TO: {phone}")
    print(f"🔑 VERIFICATION CODE: {new_otp}")
    
    # Attempt to send via Android Hardware Bridge
    if ANDROID_GATEWAY_AVAILABLE and SMSGATE_LOGIN != "your_username":
        try:
            message = domain.Message(
                phone_numbers=[phone],
                text_message=domain.TextMessage(text=f"Your Agro AI Secret Code is: {new_otp}"),
            )
            with client.APIClient(SMSGATE_LOGIN, SMSGATE_PASSWORD) as c:
                state = c.send(message)
                print(f"📡 ANDROID HARDWARE STATUS: SENT via SIM Card (ID: {state.id})")
                status = "Sent (Via Android SIM)"
        except Exception as e:
            status = f"Error ({e})"
            print(f"❌ ANDROID HARDWARE ERROR: {e}")
    else:
         print(f"⏳ STATUS: Code stored. Ready for verification.")
         if SMSGATE_LOGIN == "your_username":
              print("⚠️  NOTICE: Edit main.py with your Android SMS Gateway App login to send real text messages!")
         
    print("="*40 + "\n")
    
    # Log to dashboard
    sms_history.append({
        "time": current_time_str,
        "phone": phone,
        "otp": new_otp,
        "status": status
    })
    
    return {"status": "success", "message": "OTP sent!"}


def verify_otp_logic(phone: str, user_otp: str):
    if phone not in otp_db:
        raise HTTPException(status_code=400, detail="No OTP record found.")
    record = otp_db[phone]
    if time.time() > record["expires_at"]:
        del otp_db[phone]
        raise HTTPException(status_code=400, detail="OTP expired.")
    if record["otp"] != user_otp:
        raise HTTPException(status_code=400, detail="Wrong OTP.")
    # Success, remove from DB
    del otp_db[phone]


@app.post("/verify-otp")
async def check_otp(data: VerifyInput):
    verify_otp_logic(data.phone, data.otp)
    return {"status": "success", "message": "Verification Successful!"}


@app.post("/register")
async def register_user(data: RegisterInput):
    verify_otp_logic(data.phone, data.otp)
    # Save the user to the local dict
    users_db[data.phone] = {
        "name": data.name,
        "password": data.password
    }
    return {"status": "success", "message": "User registered."}


@app.post("/login")
async def login_user(data: LoginInput):
    phone = data.phone
    if phone not in users_db or users_db[phone]["password"] != data.password:
        raise HTTPException(status_code=400, detail="Invalid phone or password.")
    return {"status": "success", "message": "Logged in successfully.", "name": users_db[phone]["name"]}


@app.post("/reset-password")
async def reset_password(data: ResetPasswordInput):
    verify_otp_logic(data.phone, data.otp)
    users_db[data.phone] = {
        "name": data.new_name,
        "password": data.new_password
    }
    return {"status": "success", "message": "Password reset successfully."}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)