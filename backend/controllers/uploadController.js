const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');

let storage;
if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  storage = new CloudinaryStorage({
    cloudinary,
    params: {
      folder: 'pet_town_posts',
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    },
  });
} else {
  const fs = require('fs');
  const path = require('path');
  const uploadDir = path.join(__dirname, '../public/uploads');
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
  storage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, uniqueSuffix + '-' + file.originalname);
    }
  });
}

const upload = multer({ storage });

exports.upload = upload;

exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }
    
    // If we used Cloudinary, req.file.path is the URL.
    // If we used local diskStorage, we need to construct a URL.
    let url = req.file.path;
    if (!process.env.CLOUDINARY_CLOUD_NAME) {
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      url = `${baseUrl}/uploads/${req.file.filename}`;
    }
    
    res.json({ url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Upload failed' });
  }
};
