// Ensure you have installed firebase using: npm install firebase
import { initializeApp } from "firebase/app";
import { getAuth, RecaptchaVerifier, signInWithPhoneNumber } from "firebase/auth";

// 1. Initialize Firebase with your project config
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Optional: Set auth language to device default
auth.useDeviceLanguage(); 

/**
 * 2. Setup Invisible RecaptchaVerifier.
 * This attaches to an HTML element (e.g., a button with id 'sign-in-button').
 * Because it's 'invisible', the user won't see a checkbox, but might see a challenge if suspicious.
 */
function setupRecaptcha() {
  window.recaptchaVerifier = new RecaptchaVerifier(auth, 'sign-in-button', {
    'size': 'invisible',
    'callback': (response) => {
      // reCAPTCHA solved automatically, you can now proceed with submitting the phone number.
      // Usually, you don't need to call onSignInSubmit here if your button click already triggers it,
      // but it's an option.
      console.log("reCAPTCHA verified successfully.");
    },
    'expired-callback': () => {
      // The user took too long to complete the challenge.
      console.warn("reCAPTCHA expired. Please try again.");
      // Optional: Reset UI or show an error
    }
  });
}

/**
 * 3. Handle sending the SMS
 */
function onSignInSubmit() {
  const phoneNumber = document.getElementById('phone-number').value; 
  // Example format: "+1234567890"

  // Ensure verifier is initialized
  if (!window.recaptchaVerifier) {
      setupRecaptcha();
  }
  
  const appVerifier = window.recaptchaVerifier;

  signInWithPhoneNumber(auth, phoneNumber, appVerifier)
    .then((confirmationResult) => {
      // SMS Sent!
      console.log("SMS sent successfully!");
      
      // Store the result on window so you can call `confirm()` later
      // when the user types in the code they received.
      window.confirmationResult = confirmationResult;
      
      // Update your UI to show the "Enter Code" screen
      document.getElementById('verification-form').style.display = 'block';
    })
    .catch((error) => {
      console.error("Error sending SMS:", error);
      
      // Common Errors:
      // auth/too-many-requests: Quota exceeded
      // auth/invalid-phone-number: Format must be E.164 (e.g., +1...)
      
      // IMPORTANT: Reset recaptcha so the user can try again on failure
      window.recaptchaVerifier.render().then(function(widgetId) {
        grecaptcha.reset(widgetId);
      });
    });
}

/**
 * 4. Verify the code entered by the user
 */
function verifyCode() {
  const code = document.getElementById('verification-code').value;
  
  window.confirmationResult.confirm(code)
    .then((result) => {
      // User signed in successfully.
      const user = result.user;
      console.log("User successfully signed in!", user);
    })
    .catch((error) => {
      // User couldn't sign in (bad verification code, etc)
      console.error("Error verifying code:", error);
    });
}

// Ensure you call setupRecaptcha() when your page loads (or before the user clicks send)
// document.addEventListener('DOMContentLoaded', setupRecaptcha);
