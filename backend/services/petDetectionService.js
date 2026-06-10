const axios = require('axios');

const PET_LABELS = ['cat', 'dog', 'bird', 'horse', 'sheep', 'cow'];

exports.checkPetImage = async (imageUrl) => {
  if (!process.env.HUGGINGFACE_API_KEY) {
    throw new Error('HUGGINGFACE_API_KEY is missing');
  }

  const imageResponse = await axios.get(imageUrl, {
    responseType: 'arraybuffer',
    timeout: 20000
  });

  const response = await axios.post(
    'https://router.huggingface.co/hf-inference/models/facebook/detr-resnet-50',
    imageResponse.data,
    {
      headers: {
        Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
        'Content-Type': 'application/octet-stream'
      },
      timeout: 30000
    }
  );

  const results = Array.isArray(response.data) ? response.data : [];

  const bestPet = results
    .filter(item => PET_LABELS.includes(String(item.label).toLowerCase()))
    .sort((a, b) => Number(b.score) - Number(a.score))[0];

  return {
    isPet: !!bestPet,
    confidence: bestPet ? Number(bestPet.score) : 0,
    label: bestPet ? bestPet.label : 'no_pet_detected',
    imageUrl,
    raw: results.slice(0, 5)
  };
};