document.addEventListener('DOMContentLoaded', () => {
    const step1 = document.getElementById('step-1');
    const step2 = document.getElementById('step-2');
    const step3 = document.getElementById('step-3');
    
    const phoneInput = document.getElementById('phone');
    const otpInput = document.getElementById('otp');
    
    const sendBtn = document.getElementById('send-btn');
    const verifyBtn = document.getElementById('verify-btn');
    const backBtn = document.getElementById('back-btn');
    const googleBtn = document.getElementById('google-btn');
    
    const displayPhone = document.getElementById('display-phone');
    const messageDiv = document.getElementById('message');

    let currentPhone = '';

    function showMessage(text, type) {
        messageDiv.textContent = text;
        messageDiv.className = `message ${type}`;
        setTimeout(() => { messageDiv.textContent = ''; }, 5000);
    }

    sendBtn.addEventListener('click', async () => {
        const phone = phoneInput.value.trim();
        if (!phone) {
            showMessage('Please enter a valid phone number', 'error');
            return;
        }

        currentPhone = phone;
        sendBtn.disabled = true;
        sendBtn.textContent = 'Sending...';

        try {
            const res = await fetch('/send-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone })
            });

            const data = await res.json();
            
            if (data.success) {
                showMessage(data.message, 'success');
                displayPhone.textContent = currentPhone;
                step1.classList.remove('active');
                step2.classList.add('active');
            } else {
                showMessage(data.message || 'Failed to send OTP', 'error');
            }
        } catch (err) {
            showMessage('Network error occurred', 'error');
        } finally {
            sendBtn.disabled = false;
            sendBtn.textContent = 'Send OTP';
        }
    });

    verifyBtn.addEventListener('click', async () => {
        const otp = otpInput.value.trim();
        if (!otp || otp.length < 6) {
            showMessage('Please enter the 6-digit code', 'error');
            return;
        }

        verifyBtn.disabled = true;
        verifyBtn.textContent = 'Verifying...';

        try {
            const res = await fetch('/verify-otp', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ phone: currentPhone, otp })
            });

            const data = await res.json();
            
            if (data.success) {
                step2.classList.remove('active');
                step3.classList.add('active');
                messageDiv.textContent = ''; // Clear messages
            } else {
                showMessage(data.message || 'Invalid OTP', 'error');
            }
        } catch (err) {
            showMessage('Network error occurred', 'error');
        } finally {
            verifyBtn.disabled = false;
            verifyBtn.textContent = 'Verify & Login';
        }
    });

    backBtn.addEventListener('click', () => {
        step2.classList.remove('active');
        step1.classList.add('active');
        otpInput.value = '';
        messageDiv.textContent = '';
    });

    googleBtn.addEventListener('click', () => {
        // Simulate a successful Google Login for demonstration and allow access
        step1.classList.remove('active');
        step3.classList.add('active');
        document.querySelector('#step-3 p').textContent = "Logged in successfully via Google.";
    });
});
