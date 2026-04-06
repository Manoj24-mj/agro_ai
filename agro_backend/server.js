const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

// In-memory array to simulate DB for quick testing
// Replace this with mongoose in production
const feedbacks = [];

// Mongoose schema logic provided as requested, ready for use:
const feedbackSchema = new mongoose.Schema({
  screenName: { type: String, required: true },
  cropType: { type: String, required: true },
  calculationInputs: { type: mongoose.Schema.Types.Mixed },
  reason: { type: String, enum: ['Incorrect calculation', 'Hard to understand', 'Not relevant', 'App bug', 'Other'] },
  comment: { type: String },
  createdAt: { type: Date, default: Date.now }
});

// POST /feedback
app.post('/api/feedback', (req, res) => {
  try {
    const { screenName, cropType, calculationInputs, reason, comment } = req.body;
    const newFeedback = { screenName, cropType, calculationInputs, reason, comment, createdAt: new Date() };
    feedbacks.push(newFeedback);
    // await new mongoose.model('Feedback', feedbackSchema)(newFeedback).save();
    console.log("Feedback Received:", newFeedback);
    res.status(201).json({ message: "Feedback saved", data: newFeedback });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/feedback', (req, res) => {
  res.json({ data: feedbacks });
});

// GET /analytics/dislikes
app.get('/api/analytics/dislikes', (req, res) => {
  const analytics = {};
  feedbacks.forEach(f => {
    if (!analytics[f.cropType]) analytics[f.cropType] = {};
    if (!analytics[f.cropType][f.reason]) analytics[f.cropType][f.reason] = 0;
    analytics[f.cropType][f.reason]++;
  });
  res.json(analytics);
});

// GET /analytics/crop-trends
app.get('/api/analytics/crop-trends', (req, res) => {
    const cropCounts = {};
    feedbacks.forEach(f => {
      cropCounts[f.cropType] = (cropCounts[f.cropType] || 0) + 1;
    });
    // This could return an array format for charts
    const sortedTrends = Object.keys(cropCounts).map(key => ({
        cropType: key,
        issueCount: cropCounts[key]
    })).sort((a,b) => b.issueCount - a.issueCount);
    
    res.json(sortedTrends);
});

// POST /ai/analyze-feedback
app.post('/api/ai/analyze-feedback', (req, res) => {
  const summaries = [];
  const groups = {};
  feedbacks.forEach(f => {
    if (!groups[f.cropType]) groups[f.cropType] = [];
    groups[f.cropType].push(f.comment);
  });

  for (let crop in groups) {
    let commentStr = groups[crop].join(" ").toLowerCase();
    
    // Quick NLP Fallback Rules
    let issue = "General Issues";
    let suggestion = "Monitor crop calculations over time";
    
    if (commentStr.includes("wrong") || commentStr.includes("incorrect")) {
        issue = "Formula producing wrong results";
    }
    if (commentStr.includes("nitrogen")) {
        suggestion = "Check nitrogen coefficients in the algorithm";
    }
    if (commentStr.includes("bug") || commentStr.includes("crash")) {
        issue = "App logic bug reported. Fix required in UI component.";
    }

    summaries.push({ crop, issue, suggestion, frequency: groups[crop].length });
  }
  res.json({ insights: summaries });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}. Use http://10.0.2.2:${PORT} from Android Emulator.`);
});
