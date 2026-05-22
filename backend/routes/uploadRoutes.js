const express = require('express');
const router = express.Router();
const { upload, uploadImage } = require('../controllers/uploadController');

router.post('/', (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      console.error('Multer/Cloudinary Error:', err);
      return res.status(500).json({ message: `Cloudinary Error: ${err.message || 'Unknown upload error'}. Please check Render environment variables.` });
    }
    next();
  });
}, uploadImage);

module.exports = router;
