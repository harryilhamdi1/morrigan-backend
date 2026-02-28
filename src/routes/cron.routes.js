const express = require('express');
const router = express.Router();
const cronController = require('../controllers/cron.controller');

// Optional: you can set cron jobs here or trigger them remotely from Vercel CRON feature calling this URL
router.post('/ai-level-1', cronController.runAiLevel1);
router.post('/ai-level-2', cronController.runAiLevel2);
router.post('/ai-level-3', cronController.runAiLevel3);

module.exports = router;
