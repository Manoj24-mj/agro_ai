const fetch = require('node-fetch');

// Set your API key
const API_KEY = "AIzaSyB_DIdaVU_jJnuafxqS89Pn73WZp-9gCUY";

async function listModels() {
  console.log("--- Listing Available Models (v1) ---");
  const urlV1 = `https://generativelanguage.googleapis.com/v1/models?key=${API_KEY}`;
  const responseV1 = await fetch(urlV1);
  if (responseV1.ok) {
    const data = await responseV1.json();
    data.models.forEach(m => console.log(`- ${m.name} (${m.displayName})`));
  } else {
    console.log(`Error listing models (v1): ${responseV1.status} - ${await responseV1.text()}`);
  }

  console.log("\n--- Listing Available Models (v1beta) ---");
  const urlV1beta = `https://generativelanguage.googleapis.com/v1beta/models?key=${API_KEY}`;
  const responseV1beta = await fetch(urlV1beta);
  if (responseV1beta.ok) {
    const data = await responseV1beta.json();
    data.models.forEach(m => console.log(`- ${m.name} (${m.displayName})`));
  } else {
    console.log(`Error listing models (v1beta): ${responseV1beta.status} - ${await responseV1beta.text()}`);
  }
}

async function testChat() {
  const url = `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=${API_KEY}`;
  const payload = {
    contents: [{ parts: [{ text: "Hi, are you working?" }] }]
  };
  
  console.log("\n--- Testing Gemini 1.5 Flash (v1) ---");
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  
  if (response.ok) {
    const data = await response.json();
    console.log("Success! Gemini 1.5 Flash is working on v1.");
    console.log("Response:", data.candidates[0].content.parts[0].text);
  } else {
    console.log(`Failed on v1: ${response.status} - ${await response.text()}`);
  }
}

async function main() {
  await listModels();
  await testChat();
}

main().catch(err => console.error(err));
