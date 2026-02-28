const { google } = require('googleapis');
const stream = require('stream');

/**
 * Uploads a file buffer to Google Drive.
 * Expected GOOGLE_CREDENTIALS_JSON in .env is the stringified JSON from Google Cloud Console.
 */
async function uploadToDrive(fileObject, parentFolderId = null) {
    try {
        let credentials;
        try {
            credentials = JSON.parse(process.env.GOOGLE_CREDENTIALS_JSON);
        } catch (e) {
            console.error("Failed to parse GOOGLE_CREDENTIALS_JSON. Make sure it's valid JSON.");
            throw new Error("Invalid Google Credentials Configuration");
        }

        const auth = new google.auth.GoogleAuth({
            credentials,
            scopes: ['https://www.googleapis.com/auth/drive.file'],
        });

        const drive = google.drive({ version: 'v3', auth });

        const bufferStream = new stream.PassThrough();
        bufferStream.end(fileObject.buffer);

        const fileMetadata = {
            name: `${Date.now()}_${fileObject.originalname}`,
        };

        if (parentFolderId) {
            fileMetadata.parents = [parentFolderId];
        }

        const media = {
            mimeType: fileObject.mimetype,
            body: bufferStream,
        };

        const response = await drive.files.create({
            resource: fileMetadata,
            media: media,
            fields: 'id, webViewLink, webContentLink',
        });

        return {
            id: response.data.id,
            url: response.data.webViewLink,
            downloadUrl: response.data.webContentLink
        };
    } catch (error) {
        console.error("Google Drive Upload Error:", error);
        throw error;
    }
}

module.exports = {
    uploadToDrive
};
