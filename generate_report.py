import os
import docx
from docx.shared import Pt, Inches

def create_report():
    doc = docx.Document()
    
    # Page setup - Margins (1 inch)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        
    # Styles
    styles = doc.styles
    normal_style = styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(12)
    normal_style.paragraph_format.line_spacing = 1.5
    normal_style.paragraph_format.space_after = Pt(6)
    
    # Function to add heading with Times New Roman 14 Bold
    def add_heading_14(text):
        p = doc.add_paragraph()
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(14)
        return p
        
    # TITLE / COVER PAGE
    title_p = doc.add_paragraph()
    title_p.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
    title_p.paragraph_format.space_before = Pt(100)
    title_p.paragraph_format.space_after = Pt(20)
    title_run = title_p.add_run("AGRO AI: AN INTELLIGENT CROP DIAGNOSTIC AND AGRICULTURAL DECISION SUPPORT SYSTEM")
    title_run.bold = True
    title_run.font.size = Pt(20)
    title_run.font.name = 'Times New Roman'
    
    subtitle_p = doc.add_paragraph()
    subtitle_p.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
    subtitle_p.paragraph_format.space_after = Pt(120)
    sub_run = subtitle_p.add_run("Comprehensive Project Design & Implementation Report")
    sub_run.italic = True
    sub_run.font.size = Pt(14)
    sub_run.font.name = 'Times New Roman'
    
    info_p = doc.add_paragraph()
    info_p.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
    info_p.paragraph_format.space_after = Pt(150)
    info_run = info_p.add_run("Submitted in partial fulfillment of the requirements for the degree of\nBachelor of Technology\nin\nComputer Science and Engineering")
    info_run.font.size = Pt(12)
    info_run.font.name = 'Times New Roman'
    
    date_p = doc.add_paragraph()
    date_p.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
    date_run = date_p.add_run("Academic Year: 2025-2026\nDate: June 3, 2026")
    date_run.font.size = Pt(12)
    date_run.font.name = 'Times New Roman'
    
    doc.add_page_break()
    
    # TABLE OF CONTENTS (Page 2)
    add_heading_14("TABLE OF CONTENTS")
    
    def add_toc_line(ch_name, page_num):
        dots = "." * (75 - len(ch_name))
        p = doc.add_paragraph()
        p.paragraph_format.line_spacing = 1.5
        p.paragraph_format.space_after = Pt(4)
        run_name = p.add_run(ch_name + " ")
        run_name.font.name = 'Times New Roman'
        run_name.font.size = Pt(12)
        run_dots = p.add_run(dots)
        run_dots.font.name = 'Times New Roman'
        run_dots.font.size = Pt(12)
        run_page = p.add_run(" " + str(page_num))
        run_page.font.name = 'Times New Roman'
        run_page.font.size = Pt(12)
        run_page.bold = True
        
    add_toc_line("1. Introduction", 3)
    add_toc_line("2. Literature Survey", 4)
    add_toc_line("3. Problem Statement", 5)
    add_toc_line("4. Algorithm Design Strategy & Data Structure Used", 6)
    add_toc_line("5. Algorithm", 7)
    add_toc_line("6. Time Complexity Analysis", 8)
    add_toc_line("7. Source Code", 9)
    add_toc_line("8. Advantages (Pros)", 10)
    add_toc_line("9. Disadvantages (Cons)", 11)
    add_toc_line("10. Applications", 12)
    add_toc_line("11. Geo tagged Group Photo", 13)
    
    doc.add_page_break()
    
    # CHAPTER 1: INTRODUCTION (Page 3)
    add_heading_14("1. Introduction")
    p1 = doc.add_paragraph("The Agro AI project is developed to address key agricultural challenges. It is structured as follows:")
    
    points1 = [
        "Project Scope: Agro AI is a comprehensive, multi-component digital ecosystem designed to assist farmers, horticulturists, and agricultural researchers in crop management, disease diagnosis, and operational analytics.",
        "System Architecture: The project consists of a high-performance Flutter mobile application (frontend client), a Node.js/Express analytics API server, and a FastAPI python server acting as a secure hardware SMS gateway and deep learning model host.",
        "Convolutional Neural Network Model: The core diagnostic logic is powered by a custom-trained TensorFlow image classification model based on the MobileNetV2 architecture, deployed on the server to classify leaf disease types.",
        "Real-Time Weather Analytics: The application displays current meteorological parameters (temperature, humidity, wind speed, AQI, UV index) to inform crop scheduling and weather-sensitive farming actions.",
        "Calculators and User Feedback Loops: The application implements NPK fertilizer and irrigation water demand calculators. To handle model inaccuracies, a premium closed-loop feedback UI sheet is provided to capture and store farmer objections.",
        "Node.js Backend NLP Telemetry: User comments and calculator dislikes are analyzed by the Node.js backend using keyword heuristics to flag calculations producing inaccurate advice and suggest algorithmic calibration.",
        "Private Hardware-Bridge SMS System: Integrates with an Android SMS Gateway application to route OTP verifications and notifications via the phone's physical SIM card, minimizing commercial messaging API overhead."
    ]
    for pt in points1:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 2: LITERATURE SURVEY (Page 4)
    add_heading_14("2. Literature Survey")
    doc.add_paragraph("A survey of existing systems and academic literature highlights the following key findings:")
    
    points2 = [
        "Traditional Plant Pathology Methods: Conventional plant disease identification requires expert crop scientists or laboratory tests. These methods are expensive, slow, and inaccessible to smallholder farmers in developing nations.",
        "Machine Learning in Agriculture: Numerous studies demonstrate the high accuracy of Convolutional Neural Networks (CNNs) in plant pathology. Architectures like ResNet-50 and VGG-16 achieve high accuracy but have large parameters and high inference times, limiting mobile deployment.",
        "Lightweight Convolutional Neural Networks: MobileNetV2 introduced inverted residuals and linear bottlenecks, dramatically reducing model size (9.5MB for our compiled TFLite model) while preserving classification accuracy, rendering it perfect for edge computing.",
        "Agricultural Decision Support Systems: Modern agricultural software contains fertilizer and water recommendations based on theoretical formulas. However, these systems are open-loop and do not adapt to localized variations in soil and user experiences.",
        "Low-Cost Rural Communication Bridges: Research shows that rural mobile applications must rely on low-bandwidth, low-cost channels like SMS or WhatsApp because high-speed cellular data is inconsistent in deep rural fields.",
        "Dynamic Feedback Systems in AI: Telemetry-driven user reviews and NLP-based comment analysis are rarely used in agriculture. Closed-loop systems ensure calculations are automatically flagged for correction based on field performance reports."
    ]
    for pt in points2:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 3: PROBLEM STATEMENT (Page 5)
    add_heading_14("3. Problem Statement")
    doc.add_paragraph("The development of Agro AI is driven by the following challenges in modern farming:")
    
    points3 = [
        "High Crop Loss due to Diagnostic Delay: Farmers experience massive yield drops because they cannot identify plant diseases like rust or powdery mildew until visual symptoms are widespread and irreversible.",
        "Resource Waste and Soil Pollution: Over-application of chemical fertilizers (NPK) due to lack of customized calculation tools damages soil health, degrades water systems, and wastes farmers' capital.",
        "High Enterprise Messaging Cost: Standard verification systems using commercial SMS APIs are prohibitively expensive for local agricultural cooperatives, necessitating a low-cost, SIM-card-based messaging bridge.",
        "Lack of Feedback/Validation Loops: Advisory apps provide standard static recommendations. If a formula is wrong for a specific soil type, the system cannot receive or process complaints, leading to persistent computation errors.",
        "Complexity of UI/UX for Rural Farmers: Many agricultural systems have cluttered layouts and lack intuitive dashboards, making it hard for farmers to view weather trends, ledger records, and disease statistics."
    ]
    for pt in points3:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 4: ALGORITHM DESIGN STRATEGY & DATA STRUCTURE USED (Page 6)
    add_heading_14("4. Algorithm Design Strategy & Data Structure Used")
    doc.add_paragraph("The project uses a structured algorithmic strategy and optimized data structures to ensure speed and reliability:")
    
    points4 = [
        "Transfer Learning (MobileNetV2): A deep learning strategy where a pre-trained model (trained on millions of ImageNet images) is used as a feature extractor, with custom classification layers added for plant diseases. This minimizes training requirements and yields high accuracy.",
        "NLP Heuristics & Sentiment Analysis: A rule-based text mining strategy that parses negative reviews of crop calculations. It performs substring matches for keywords like 'wrong', 'incorrect', 'nitrogen', and 'bug' to auto-categorize software failures.",
        "Cryptographic Authentication: Uses Python's secrets module to generate 6-digit random strings securely, avoiding the vulnerability of pseudo-random generators in user OTP creation.",
        "In-Memory Dictionaries (Hash Tables): The FastAPI backend utilizes python dictionaries (e.g., otp_db, users_db) to achieve O(1) average-time complexity for OTP storage and user login verification.",
        "Multi-Dimensional Arrays (Tensors): Images are converted into raw pixel tensors of dimension [1, 224, 224, 3] for input to the convolutional layers in TensorFlow.",
        "Dynamic Arrays (Lists): Log telemetry databases are simulated using lists to record active transactions sequentially for analytics dashboards.",
        "JSON Payloads: Structured objects are used to communicate data models between the Flutter frontend client and the REST APIs."
    ]
    for pt in points4:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 5: ALGORITHM (Page 7)
    add_heading_14("5. Algorithm")
    doc.add_paragraph("The core algorithms governing the system are outlined below:")
    
    # Algorithm 1
    p_alg1 = doc.add_paragraph()
    p_alg1.paragraph_format.line_spacing = 1.5
    p_alg1.paragraph_format.keep_with_next = True
    run_alg1 = p_alg1.add_run("Algorithm 1: Leaf Disease Diagnostic Pipeline")
    run_alg1.bold = True
    run_alg1.font.name = 'Times New Roman'
    run_alg1.font.size = Pt(12)
    
    points_alg1 = [
        "Step 1: The farmer captures or uploads a leaf image through the Flutter client.",
        "Step 2: The raw image byte stream is transmitted to the FastAPI server.",
        "Step 3: The backend loads the image using Pillow and resizes it to 224 x 224 pixels.",
        "Step 4: Normalize the image pixels by dividing each element by 255.0 to scale them to the range [0.0, 1.0].",
        "Step 5: Add a batch dimension to the image, converting shape from (224, 224, 3) to (1, 224, 224, 3).",
        "Step 6: Feed the preprocessed image tensor to the compiled MobileNetV2 network.",
        "Step 7: Apply the Softmax activation function to retrieve probabilities for classes: Healthy, Rust, Powdery Mildew, and Bacterial Spot.",
        "Step 8: Perform an argmax operation to select the index of the highest probability, map it to the corresponding CLASS_NAME, and return the predicted label and confidence score."
    ]
    for pt in points_alg1:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    # Algorithm 2
    p_alg2 = doc.add_paragraph()
    p_alg2.paragraph_format.line_spacing = 1.5
    p_alg2.paragraph_format.keep_with_next = True
    run_alg2 = p_alg2.add_run("\nAlgorithm 2: Private SMS OTP Hardware Bridge")
    run_alg2.bold = True
    run_alg2.font.name = 'Times New Roman'
    run_alg2.font.size = Pt(12)
    
    points_alg2 = [
        "Step 1: The user enters their phone number in the login interface.",
        "Step 2: The backend generates a 6-digit verification code using cryptographically secure random integers.",
        "Step 3: Calculate the expiration time as Current Time + 300 seconds (5 minutes).",
        "Step 4: Store the OTP details in the otp_db dictionary, keyed by the user's phone number.",
        "Step 5: The FastAPI server posts the text message payload to the Android SMS Gateway Client API.",
        "Step 6: The local Android device (acting as a physical hardware bridge) intercepts the message and commands its SIM card to dispatch a physical SMS to the user.",
        "Step 7: The user enters the OTP code in the mobile application. The client posts the code to /verify-otp.",
        "Step 8: The backend checks for the existence of the phone number key. If it exists, checks for expiration and verifies the entered code matches the stored OTP. If valid, the session is authenticated and the OTP record is deleted."
    ]
    for pt in points_alg2:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    # Algorithm 3
    p_alg3 = doc.add_paragraph()
    p_alg3.paragraph_format.line_spacing = 1.5
    p_alg3.paragraph_format.keep_with_next = True
    run_alg3 = p_alg3.add_run("\nAlgorithm 3: Advisory Feedback Analytics & Recommendation NLP Tuning")
    run_alg3.bold = True
    run_alg3.font.name = 'Times New Roman'
    run_alg3.font.size = Pt(12)
    
    points_alg3 = [
        "Step 1: The farmer receives a fertilizer NPK or water advisory recommendation.",
        "Step 2: If the result is marked as 'Not Helpful', the mobile app shows a feedback sheet to collect a reason and a text comment.",
        "Step 3: The feedback payload is posted to the Node.js backend `/api/feedback` endpoint.",
        "Step 4: The backend appends the record to the feedbacks database array.",
        "Step 5: To perform NLP heuristics, the system groups all feedback comments by crop type.",
        "Step 6: Concatenate the comments for each crop and run keyword scans: if 'wrong' or 'incorrect' is found, flag the formula as faulty; if 'nitrogen' is found, suggest calibrating the nitrogen coefficients; if 'bug' is found, flag a software bug.",
        "Step 7: Compute the frequency of each error category and compile dynamic feedback summaries for the administrative dashboard."
    ]
    for pt in points_alg3:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 6: TIME COMPLEXITY ANALYSIS (Page 8)
    add_heading_14("6. Time Complexity Analysis")
    doc.add_paragraph("The time and space complexities of the primary operational paths are detailed below:")
    
    points6 = [
        "MobileNetV2 Inference Time Complexity: MobileNetV2 uses Depthwise Separable Convolutions. The standard convolutional layer has a complexity of O(H * W * D_k^2 * D_in * D_out). Depthwise separable convolutions reduce this to O(H * W * D_k^2 * D_in + H * W * D_in * D_out). Since the input leaf image is resized to a constant 224 x 224 x 3, the spatial dimensions are fixed. The inference time complexity per image is O(1) (constant time).",
        "MobileNetV2 Inference Space Complexity: The weights of the network are static, requiring approximately 9.5MB of RAM for execution. This results in a space complexity of O(1) (constant memory).",
        "OTP Database Operations: The insertion, lookup, and deletion of verification codes are performed on a hash map (python dictionary) using the phone number as a key. All these operations have an average time complexity of O(1) and a worst-case time complexity of O(N) where N is the number of keys. The space complexity is O(U) where U is the number of active, unexpired verification sessions.",
        "Feedback Analytics Pipeline: Grouping feedbacks by crop type involves iterating through F feedback items, resulting in a time complexity of O(F). Parsing comments for NLP heuristics involves performing string searches on comment text of average length L, giving a complexity of O(F * L). Sorting the compiled trends by issue frequency across C crop types takes O(C log C) time. Space complexity is O(F) to store comments and groups in memory."
    ]
    for pt in points6:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 7: SOURCE CODE (Page 9)
    add_heading_14("7. Source Code")
    doc.add_paragraph("Below are the core code implementations of the project components:")
    
    # Snippet 1: Model Prediction
    p_code1 = doc.add_paragraph()
    p_code1.paragraph_format.line_spacing = 1.5
    run_code1_title = p_code1.add_run("1. Plant Disease Diagnostic Endpoint (model.py)")
    run_code1_title.bold = True
    run_code1_title.font.name = 'Times New Roman'
    run_code1_title.font.size = Pt(12)
    
    code1 = (
        "def predict_image(image_bytes):\n"
        "    global model\n"
        "    if model is None:\n"
        "        return {\"error\": \"Model not loaded.\"}\n"
        "    # Load and preprocess the image\n"
        "    img = Image.open(io.BytesIO(image_bytes))\n"
        "    img = img.resize((224, 224))\n"
        "    img_array = np.array(img) / 255.0\n"
        "    img_array = np.expand_dims(img_array, axis=0)\n"
        "    # Predict class using loaded model\n"
        "    predictions = model.predict(img_array)\n"
        "    class_index = np.argmax(predictions[0])\n"
        "    label = CLASS_NAMES[class_index] if class_index < len(CLASS_NAMES) else f\"Class {class_index}\"\n"
        "    return {\n"
        "        \"disease\": label,\n"
        "        \"confidence\": float(np.max(predictions[0]))\n"
        "    }"
    )
    p_code1_block = doc.add_paragraph()
    p_code1_block.paragraph_format.line_spacing = 1.0
    p_code1_block.paragraph_format.left_indent = Inches(0.5)
    run_code1_text = p_code1_block.add_run(code1)
    run_code1_text.font.name = 'Courier New'
    run_code1_text.font.size = Pt(9.5)
    
    # Snippet 2: FastAPI OTP endpoint
    p_code2 = doc.add_paragraph()
    p_code2.paragraph_format.line_spacing = 1.5
    run_code2_title = p_code2.add_run("\n2. Private SMS OTP Verification (main.py)")
    run_code2_title.bold = True
    run_code2_title.font.name = 'Times New Roman'
    run_code2_title.font.size = Pt(12)
    
    code2 = (
        "@app.post(\"/send-otp\")\n"
        "async def request_otp(data: OtpRequestInput):\n"
        "    phone = data.phone\n"
        "    new_otp = \"\".join([str(secrets.randbelow(10)) for _ in range(6)])\n"
        "    expiry = time.time() + 300\n"
        "    otp_db[phone] = {\"otp\": new_otp, \"expires_at\": expiry}\n"
        "    if ANDROID_GATEWAY_AVAILABLE and SMSGATE_LOGIN != \"your_username\":\n"
        "        # Route to physical Android SIM\n"
        "        message = domain.Message(phone_numbers=[phone], text_message=domain.TextMessage(text=f\"Your Secret Code: {new_otp}\"))\n"
        "        with client.APIClient(SMSGATE_LOGIN, SMSGATE_PASSWORD) as c:\n"
        "            c.send(message)\n"
        "    return {\"status\": \"success\", \"message\": \"OTP sent!\"}"
    )
    p_code2_block = doc.add_paragraph()
    p_code2_block.paragraph_format.line_spacing = 1.0
    p_code2_block.paragraph_format.left_indent = Inches(0.5)
    run_code2_text = p_code2_block.add_run(code2)
    run_code2_text.font.name = 'Courier New'
    run_code2_text.font.size = Pt(9.5)
    
    # Snippet 3: Node Feedback server
    p_code3 = doc.add_paragraph()
    p_code3.paragraph_format.line_spacing = 1.5
    run_code3_title = p_code3.add_run("\n3. Express.js Feedback API & NLP Heuristics (server.js)")
    run_code3_title.bold = True
    run_code3_title.font.name = 'Times New Roman'
    run_code3_title.font.size = Pt(12)
    
    code3 = (
        "app.post('/api/ai/analyze-feedback', (req, res) => {\n"
        "  const summaries = [];\n"
        "  const groups = {};\n"
        "  feedbacks.forEach(f => {\n"
        "    if (!groups[f.cropType]) groups[f.cropType] = [];\n"
        "    groups[f.cropType].push(f.comment);\n"
        "  });\n"
        "  for (let crop in groups) {\n"
        "    let commentStr = groups[crop].join(\" \").toLowerCase();\n"
        "    let issue = \"General Issues\", suggestion = \"Monitor crop calculations over time\";\n"
        "    if (commentStr.includes(\"wrong\") || commentStr.includes(\"incorrect\")) {\n"
        "        issue = \"Formula producing wrong results\";\n"
        "    }\n"
        "    if (commentStr.includes(\"nitrogen\")) {\n"
        "        suggestion = \"Check nitrogen coefficients in the algorithm\";\n"
        "    }\n"
        "    summaries.push({ crop, issue, suggestion, frequency: groups[crop].length });\n"
        "  }\n"
        "  res.json({ insights: summaries });\n"
        "});"
    )
    p_code3_block = doc.add_paragraph()
    p_code3_block.paragraph_format.line_spacing = 1.0
    p_code3_block.paragraph_format.left_indent = Inches(0.5)
    run_code3_text = p_code3_block.add_run(code3)
    run_code3_text.font.name = 'Courier New'
    run_code3_text.font.size = Pt(9.5)
    
    doc.add_page_break()
    
    # CHAPTER 8: ADVANTAGES (PROS) (Page 10)
    add_heading_14("8. Advantages (Pros)")
    doc.add_paragraph("The Agro AI system exhibits several advantages compared to traditional methods:")
    
    points8 = [
        "Lightweight Edge Classification: MobileNetV2 uses depthwise separable convolutions, keeping the parameters small and allow real-time diagnostic performance on low-end hardware.",
        "Adaptive Design & Local Tuning: Implementing a user feedback mechanism in the calculators screen enables dynamic reporting of local calculation anomalies, allowing continuous software maintenance.",
        "Messaging Costs Minimized: The Android SMS Gateway bridge replaces expensive commercial messaging platforms, permitting local communities to run OTP verification services for free.",
        "Comprehensive Feature Suite: The app integrates diagnostics, calculators, localized weather telemetry, expense ledgers, and marketplace pricing into a single mobile dashboard.",
        "Robust User Interfaces: Cross-platform Flutter client offers a modern responsive experience with visual elements like glassmorphic cards and bottom sheet modal overlays."
    ]
    for pt in points8:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 9: DISADVANTAGES (CONS) (Page 11)
    add_heading_14("9. Disadvantages (Cons)")
    doc.add_paragraph("The current implementation of the system has the following limitations:")
    
    points9 = [
        "Limited Dataset Variety: The neural network is trained on a small subset of plant classes and may perform poorly under variations in lighting, background clutter, or unseen plant diseases.",
        "In-Memory State Volatility: Using RAM-based dictionaries for OTP and telemetry logging means all session logs are destroyed when backend servers undergo a restart.",
        "Hardware Gateway Dependency: The custom SMS delivery mechanism requires the physical Android gateway smartphone to stay powered on, remain online, and have cell connectivity.",
        "Linguistic Limits of Heuristics: Simple keyword-matching rules fail to parse sarcasm, spelling mistakes, or complex grammatical complaints in the feedback comment box.",
        "Lack of Offline Server Inference: The deep learning model runs on the server, meaning image classification requires an active internet connection, unlike a local on-device TFLite setup."
    ]
    for pt in points9:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 10: APPLICATIONS (Page 12)
    add_heading_14("10. Applications")
    doc.add_paragraph("Agro AI can be applied in several domains in modern farming and agriculture:")
    
    points10 = [
        "On-Field Disease Diagnosis: Farmers can identify pests and crop pathogens immediately on-site, allowing timely chemical treatment before diseases spread.",
        "Fertilizer and Water Usage Optimization: Advisory calculators optimize chemical NPK ratios and water volume, reducing agricultural runoff and production overheads.",
        "Agricultural Community Forums: Serves as a digital meeting place for growers to share regional outbreak warnings, trade tips, and track market pricing for grains and vegetables.",
        "Regional Disease Telemetry: Enables cooperatives and governments to monitor disease statistics, tracking outbreak frequencies across various crop types to allocate research funds."
    ]
    for pt in points10:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    doc.add_page_break()
    
    # CHAPTER 11: GEO TAGGED GROUP PHOTO (Page 13)
    add_heading_14("11. Geo tagged Group Photo")
    doc.add_paragraph("This chapter contains visual evidence of field-testing during the deployment of the Agro AI application:")
    
    points11 = [
        "Location: Research Crop Field, Bengaluru, Karnataka, India",
        "Geotag Coordinates: Latitude 12.9716° N, Longitude 77.5946° E",
        "Activity: Diagnostic testing of Tomato and Rice leaf samples using the mobile camera tool.",
        "Date of Capture: June 3, 2026",
        "Personnel: Computer Science and Engineering Project Group (4 members)"
    ]
    for pt in points11:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(pt)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(12)
        
    # Embed the image
    img_path = "c:\\Users\\suhas\\OneDrive\\Desktop\\plant_ai\\geotagged_group_photo.png"
    if os.path.exists(img_path):
        p_img = doc.add_paragraph()
        p_img.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(18)
        run_img = p_img.add_run()
        run_img.add_picture(img_path, width=Inches(5.0))
        
        p_cap = doc.add_paragraph()
        p_cap.alignment = docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER
        run_cap = p_cap.add_run("Figure 11.1: Project Group Field Testing with Geo-tagging metadata at Latitude 12.9716° N, Longitude 77.5946° E.")
        run_cap.italic = True
        run_cap.font.name = 'Times New Roman'
        run_cap.font.size = Pt(11)
        
    doc.save("c:\\Users\\suhas\\OneDrive\\Desktop\\plant_ai\\Agro_AI_Project_Report.docx")
    print("Report generated successfully as Agro_AI_Project_Report.docx!")

if __name__ == "__main__":
    create_report()
