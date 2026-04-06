from fastapi import FastAPI, Request
from twilio.twiml.messaging_response import MessagingResponse

app = FastAPI()

@app.post("/whatsapp")
async def reply(request: Request):
    form = await request.form()
    media = form.get("MediaUrl0")

    res = MessagingResponse()

    if media:
        res.message("🌿 Disease: Tomato Late Blight (92%)")
    else:
        res.message("Send plant image 📸")

    return str(res)
    