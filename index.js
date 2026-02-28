require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
    origin: '*', // For production, replace with frontend URL (https://harryilhamdi1.github.io or vercel domain)
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check Route
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Morrigan Backend System is running.' });
});

// Import Routes
const uploadRoutes = require('./src/routes/upload.routes');
const cronRoutes = require('./src/routes/cron.routes');

app.use('/api/upload', uploadRoutes);
app.use('/api/cron', cronRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

// Start Server
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
