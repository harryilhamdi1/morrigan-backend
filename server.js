// server.js
// Node.js Middleware for Eiger Retail Action Plan
// Handles Google Drive Uploads & Supabase Interactions

import express from 'express';
import cors from 'cors';
import multer from 'multer';
import { google } from 'googleapis';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import stream from 'stream';

// Load Environment Variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Set up Multer for Memory Storage (we stream directly to GDrive, no local save needed)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit per file
});

// Initialize Supabase Client (Admin Role for secure backend ops)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.warn("⚠️ WARNING: Supabase credentials missing in .env");
}

const supabase = supabaseUrl && supabaseServiceKey
    ? createClient(supabaseUrl, supabaseServiceKey)
    : null;

// Initialize Google Drive API Client
const SCOPES = ['https://www.googleapis.com/auth/drive.file'];
let drive = null;

try {
    const auth = new google.auth.GoogleAuth({
        keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
        scopes: SCOPES,
    });
    drive = google.drive({ version: 'v3', auth });
    console.log("✅ Google Drive API Initialized");
} catch (error) {
    console.error("❌ Failed to initialize Google Drive:", error.message);
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

// 1. Health Check
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', message: 'Action Plan Middleware is running' });
});

// 2. Upload Execution Proof to Google Shared Drive
app.post('/api/upload-proof', upload.single('evidence'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, error: 'No file uploaded' });
        }

        const { actionPlanId, storeName } = req.body;

        if (!actionPlanId) {
            return res.status(400).json({ success: false, error: 'actionPlanId is required' });
        }

        console.log(`Uploading evidence for Plan ID: ${actionPlanId}, Store: ${storeName}`);

        // Prepare file metadata for Google Drive
        const fileMetadata = {
            name: `${storeName}_Proof_${Date.now()}_${req.file.originalname}`,
            parents: [process.env.GOOGLE_DRIVE_FOLDER_ID] // Store in the specific Shared Drive Folder
        };

        // Convert memory buffer to readable stream for Google API
        const bufferStream = new stream.PassThrough();
        bufferStream.end(req.file.buffer);

        const media = {
            mimeType: req.file.mimetype,
            body: bufferStream,
        };

        // Upload to Drive
        const driveResponse = await drive.files.create({
            requestBody: fileMetadata,
            media: media,
            fields: 'id, webViewLink, webContentLink',
        });

        const fileId = driveResponse.data.id;
        const fileUrl = driveResponse.data.webViewLink; // The link to view in browser

        // Make file publicly readable (anyone with link can view) so Dashboard can display it
        await drive.permissions.create({
            fileId: fileId,
            requestBody: {
                role: 'reader',
                type: 'anyone',
            },
        });

        // 3. Update Supabase Action Plan Record with the new URL
        if (supabase) {
            const { error: dbError } = await supabase
                .from('action_plans')
                .update({
                    execution_proof_link: fileUrl,
                    status: 'in_progress', // Move status forward automatically
                    updated_at: new Date()
                })
                .eq('id', actionPlanId);

            if (dbError) throw dbError;
        }

        res.json({
            success: true,
            message: 'File uploaded and database updated successfully',
            fileUrl: fileUrl,
            fileId: fileId
        });

    } catch (error) {
        console.error("Upload Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Middleman Server running on http://localhost:${PORT}`);
});
