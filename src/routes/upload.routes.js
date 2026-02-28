const express = require('express');
const router = express.Router();
const multer = require('multer');
const uploadController = require('../controllers/upload.controller');

// Use multer memory storage to keep file in memory before passing to Google Drive
const upload = multer({ storage: multer.memoryStorage() });

router.post('/evidence', upload.single('file'), uploadController.uploadEvidence);
router.post('/csv', upload.single('file'), uploadController.uploadCsv);

module.exports = router;
