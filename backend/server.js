const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http');
const { Server } = require('socket.io');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Socket.io injection into req for controllers to emit events if needed
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/vets', require('./routes/vetRoutes'));
app.use('/api/posts', require('./routes/postRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/messages', require('./routes/messagesRouter'));
app.use('/api/marketplace', require('./routes/marketplaceRoutes'));
app.use('/api/orders', require('./routes/orderRoutes'));
app.use('/api/upload', require('./routes/uploadRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/vouchers', require('./routes/voucherRoutes'));
app.use('/api/adoptions', require('./routes/adoptionRoutes'));
app.use('/api/shelters', require('./routes/shelterRoutes'));
app.use('/api/salons', require('./routes/salonRoutes'));
app.use('/api/social', require('./routes/socialRoutes'));
app.use('/api/events', require('./routes/eventRoutes'));
// Socket.io connection logic
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('join_chat', (userId) => {
    socket.join(`user_${userId}`);
    console.log(`User ${userId} joined their personal room.`);
  });

  socket.on('start_call', (data) => {
    const { receiver_id } = data;

    console.log('start_call:', data);

    io.to(`user_${receiver_id}`).emit('incoming_call', data);
  });

  socket.on('call_declined', (data) => {
    const { caller_id } = data;

    console.log('call_declined:', data);

    io.to(`user_${caller_id}`).emit('call_declined', data);
  });

  socket.on('call_missed', (data) => {
    const { caller_id } = data;

    console.log('call_missed:', data);

    io.to(`user_${caller_id}`).emit('call_missed', data);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
