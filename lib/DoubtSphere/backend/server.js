const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

// 🧠 In-memory storage (no DB)
let doubts = [];

/* -------------------------
   TEST ROUTE
--------------------------*/
app.get("/", (req, res) => {
  res.send("Server running 🚀");
});

/* -------------------------
   CREATE DOUBT
--------------------------*/
app.post("/doubt", (req, res) => {
  const { title, description } = req.body;

  const newDoubt = {
    _id: Date.now().toString(),
    title,
    description,
    status: "OPEN",
    acceptedBy: null
  };

  doubts.push(newDoubt);

  res.json(newDoubt);
});

/* -------------------------
   GET ALL DOUBTS
--------------------------*/
app.get("/doubts", (req, res) => {
  res.json(doubts);
});

/* -------------------------
   ACCEPT DOUBT
--------------------------*/
app.post("/accept-doubt", (req, res) => {
  const { doubtId, userId } = req.body;

  const doubt = doubts.find(d => d._id === doubtId);

  if (!doubt) {
    return res.status(404).json({ error: "Doubt not found" });
  }

  if (doubt.status !== "OPEN") {
    return res.status(400).json({ error: "Already accepted" });
  }

  doubt.status = "MATCHED";
  doubt.acceptedBy = userId;

  res.json({
    message: "Doubt accepted successfully",
    doubt
  });
});

/* -------------------------
   DELETE DOUBT (optional)
--------------------------*/
app.delete("/doubt/:id", (req, res) => {
  doubts = doubts.filter(d => d._id !== req.params.id);
  res.json({ message: "Deleted" });
});

/* -------------------------
   START SERVER
--------------------------*/
app.listen(5000, () => {
  console.log("Server running on port 5000");
});