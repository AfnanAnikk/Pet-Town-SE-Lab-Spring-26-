const axios = require('axios');

const PET_LABELS = [
  'cat',
  'dog',
  'bird',
  'rabbit',
  'hamster',
  'guinea pig',
  'fish',
  'turtle',
  'pet animal'
];

exports.checkPetImage = async (imageUrl) => {
  const response = await axios.post(
    'https://api-inference.huggingface.co/models/openai/clip-vit-base-patch32',
    {
      inputs: imageUrl,
      parameters: {
        candidate_labels: [
          ...PET_LABELS,
          'human',
          'food',
          'car',
          'building',
          'landscape',
          'clothing',
          'furniture',
          'text screenshot',
          'random object'
        ]
      }
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  const results = response.data;
  const top = results[0];

  return {
    isPet: PET_LABELS.includes(top.label),
    confidence: Number(top.score),
    label: top.label,
    imageUrl
  };
};