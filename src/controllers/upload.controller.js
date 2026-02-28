const { uploadToDrive } = require('../services/googleDrive.service');
const { supabase } = require('../services/supabase.service');

const uploadEvidence = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file provided' });
        }

        console.log(`Uploading evidence file: ${req.file.originalname}`);

        // 1. Upload to Google Drive (Add Folder ID to environment variables if you want to organize it)
        const driveResult = await uploadToDrive(req.file, process.env.GOOGLE_DRIVE_EVIDENCE_FOLDER_ID);

        // 2. (Optional) If an actionPlanId is provided, automatically link it in Supabase
        const actionPlanId = req.body.actionPlanId;
        if (actionPlanId && supabase) {
            await supabase
                .from('action_plans')
                .update({ evidence_url: driveResult.url })
                .eq('id', actionPlanId);
        }

        res.status(200).json({
            success: true,
            message: 'File successfully uploaded to Google Drive',
            url: driveResult.url,
            fileId: driveResult.id
        });

    } catch (error) {
        console.error("Upload Evidence Error:", error);
        res.status(500).json({ error: 'Failed to upload evidence', details: error.message });
    }
};

const uploadCsv = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No CSV file provided' });
        }

        // Logic to parse CSV and dump to Supabase would go here
        // For now, we process and return success
        // This is where Sprint 5 Heavy lifting takes place
        res.status(200).json({ success: true, message: 'CSV File received for async processing.' });

    } catch (error) {
        res.status(500).json({ error: 'Failed to process CSV' });
    }
};

module.exports = {
    uploadEvidence,
    uploadCsv
};
