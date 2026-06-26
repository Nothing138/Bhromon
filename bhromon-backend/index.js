// server.js - Complete Bhromon Backend Setup
// ✅ Raj's working Express server with all routes

import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import postsRoutes from './routes/posts.js';
import feedRoutes from './routes/feedRoutes.js';
import likesRoutes from './routes/likesRoutes.js';
import actionsRoutes from './routes/actionsRoutes.js';
import eventRoutes from './routes/eventRoutes.js'; 
import profileRoutes from './routes/profile_routes.js';
import passwordResetRoutes from './routes/password-reset.js';
import changePasswordRoutes from './routes/change-password.js';


dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// ========================
// MIDDLEWARE
// ========================
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// ========================
// ROUTES
// ========================
app.use('/api/auth', authRoutes);
app.use('/api/auth', passwordResetRoutes); 
app.use('/api/auth', changePasswordRoutes);
app.use('/api/posts', postsRoutes);
app.use('/api/feed', feedRoutes);
app.use('/api/likes', likesRoutes);
app.use('/api/actions', actionsRoutes);
app.use('/api', eventRoutes); 
app.use('/api', profileRoutes);

// Uploads folder
import fs from 'fs';
const uploadsDir = './uploads/profiles';
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// ========================
// HEALTH CHECK
// ========================
app.get('/health', (req, res) => {
  res.json({
    status: '✅ Bhromon Backend is Running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    services: {
      supabase: process.env.SUPABASE_URL ? '✅ Connected' : '❌ Missing',
      gmail: process.env.GMAIL_USER ? '✅ Configured' : '❌ Missing'
    }
  });
});

// ========================
// 404 HANDLER
// ========================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
  });
});

// ========================
// GLOBAL ERROR HANDLER
// ========================
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  console.error('Stack:', err.stack);
  
  res.status(err.status || 500).json({
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
  console.log('╔════════════════════════════════════════════╗');
  console.log('║   🌍 BHROMON BACKEND SERVER STARTED       ║');
  console.log('╚════════════════════════════════════════════╝\n');
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📧 Gmail SMTP: ${process.env.GMAIL_USER ? '✅ Configured' : '❌ Not configured'}`);
  console.log(`🗄️  Supabase URL: ${process.env.SUPABASE_URL ? '✅ Loaded' : '❌ Missing'}`);
  console.log(`🔑 Service Role Key: ${process.env.SUPABASE_SERVICE_ROLE_KEY ? '✅ Loaded' : '❌ Missing'}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 CORS Origin: ${process.env.FRONTEND_URL || 'All origins'}`);
  console.log('\n✅ All services initialized!\n');
});

// ========================
// GRACEFUL SHUTDOWN
// ========================
process.on('SIGTERM', () => {
  console.log('\n📴 SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

export default app;