require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const twilio = require('twilio');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Twilio credentials from environment variables
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

const client = twilio(accountSid, authToken);

// Simple local memory database for OTPs
// Structure: { "+1234567890": { otp: "123456", expiresAt: 1695420341234 } }
const otpStore = {};

// Helper to generate a 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

app.post('/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ success: false, message: 'Phone number is required' });
  }

  const otp = generateOTP();
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes in milliseconds

  // Store OTP
  otpStore[phone] = { otp, expiresAt };
  console.log(`Generated OTP ${otp} for ${phone}`); // For testing/debugging

  try {
    // Enable this when you have valid Twilio credentials
    /*
    await client.messages.create({
      body: `Your verification code is: ${otp}`,
      from: twilioPhoneNumber,
      to: phone
    });
    */
    
    // Simulating success
    res.json({ success: true, message: 'OTP sent successfully!' });
  } catch (error) {
    console.error('Twilio Error:', error);
    res.status(500).json({ success: false, message: 'Failed to send OTP' });
  }
});

app.post('/verify-otp', (req, res) => {
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ success: false, message: 'Phone and OTP are required' });
  }

  const storedData = otpStore[phone];

  if (!storedData) {
    return res.status(400).json({ success: false, message: 'No OTP requested for this number' });
  }

  if (Date.now() > storedData.expiresAt) {
    delete otpStore[phone];
    return res.status(400).json({ success: false, message: 'OTP has expired' });
  }

  if (storedData.otp === otp) {
    // OTP is correct
    delete otpStore[phone]; // Clean up after successful verification
    res.json({ success: true, message: 'OTP verified! Login successful.' });
  } else {
    res.status(400).json({ success: false, message: 'Invalid OTP' });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
