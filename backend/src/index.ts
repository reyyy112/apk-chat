import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';
import { initializeSockets } from './sockets';

dotenv.config();

const app = express();
const server = http.createServer(app);
export const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

export const prisma = new PrismaClient();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

import path from 'path';
import fs from 'fs';

// Serve uploaded files
const uploadsPath = path.resolve(__dirname, '../uploads');
if (!fs.existsSync(uploadsPath)) {
  fs.mkdirSync(uploadsPath, { recursive: true });
}
app.use('/uploads', express.static(uploadsPath));

// Basic health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date() });
});

// Download Android APK directly from phone
app.get('/download/app.apk', (req, res) => {
  const releaseApk = path.resolve(__dirname, '../../mobile/build/app/outputs/flutter-apk/app-release.apk');
  const debugApk = path.resolve(__dirname, '../../mobile/build/app/outputs/flutter-apk/app-debug.apk');
  if (fs.existsSync(releaseApk)) {
    return res.download(releaseApk, 'QuickChat.apk');
  } else if (fs.existsSync(debugApk)) {
    return res.download(debugApk, 'QuickChat.apk');
  }
  return res.status(404).send('APK belum dibuild.');
});

// Serve Flutter Web App
const webAppPath = path.resolve(__dirname, '../../mobile/build/web');
app.use(express.static(webAppPath, {
  etag: false,
  maxAge: 0,
  setHeaders: (res) => {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }
}));

import authRoutes from './routes/auth.routes';
import contactRoutes from './routes/contact.routes';
import storyRoutes from './routes/story.routes';
import callRoutes from './routes/call.routes';
import groupRoutes from './routes/group.routes';
import { seedDatabase } from './utils/seed';

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/contacts', contactRoutes);
app.use('/api/v1/stories', storyRoutes);
app.use('/api/v1/calls', callRoutes);
app.use('/api/v1/groups', groupRoutes);


// Initialize WebSockets
initializeSockets(io);

// SPA fallback for Flutter Web
app.use((req, res, next) => {
  if (req.method === 'GET' && !req.path.startsWith('/api') && !req.path.startsWith('/health') && !req.path.startsWith('/uploads')) {
    return res.sendFile(path.join(webAppPath, 'index.html'));
  }
  next();
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
  console.log(`🚀 QuickChat Server running on port ${PORT}`);
  await seedDatabase();
});
