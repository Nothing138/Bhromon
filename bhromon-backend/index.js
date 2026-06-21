// index.js - Backend Server Main File
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ========================
// MIDDLEWARE
// ========================
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ========================
// ROUTES
// ========================
app.use('/api/auth', authRoutes);

// ========================
// HEALTH CHECK
// ========================
app.get('/health', (req, res) => {
  res.json({
    status: '✅ Backend is running',
    timestamp: new Date().toISOString(),
  });
});

// ========================
// 404 HANDLER
// ========================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// ========================
// ERROR HANDLER
// ========================
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// ========================
// START SERVER
// ========================
app.listen(PORT, () => {
  console.log('\n');
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log(`📧 Resend API Key: ${process.env.RESEND_API_KEY ? '✅ Loaded' : '❌ Missing'}`);
  console.log(`🔑 Supabase URL: ${process.env.SUPABASE_URL ? '✅ Loaded' : '❌ Missing'}`);
  console.log(`🗝️  Supabase Service Role: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ Loaded' : '❌ Missing'}`);
  console.log(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('\n✅ Ready for requests!\n');
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});