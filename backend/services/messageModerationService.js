const axios = require('axios');

exports.checkMessageSafety = async (text) => {
  if (!process.env.HUGGINGFACE_API_KEY) {
    throw new Error('HUGGINGFACE_API_KEY is missing');
  }

  const response = await axios.post(
    'https://router.huggingface.co/hf-inference/models/unitary/toxic-bert',
    {
      inputs: text
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.HUGGINGFACE_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 30000
    }
  );

  const results = Array.isArray(response.data?.[0]) ? response.data[0] : [];

  const risky = results
    .filter(item =>
      ['toxic', 'threat', 'insult', 'obscene'].includes(
        String(item.label).toLowerCase()
      )
    )
    .sort((a, b) => Number(b.score) - Number(a.score))[0];

  const moneyKeywords = [
    'send money',
    'bkash',
    'nagad',
    'rocket',
    'bank transfer',
    'loan me',
    'pay me',
    'give me money'
  ];

  const hasMoneySpam = moneyKeywords.some(k =>
    text.toLowerCase().includes(k)
  );

  return {
    isRisky: !!risky || hasMoneySpam,
    confidence: risky ? Number(risky.score) : hasMoneySpam ? 0.9 : 0,
    label: risky ? risky.label : hasMoneySpam ? 'money_request' : 'safe',
    reason: risky ? 'Toxic or threatening message' : hasMoneySpam ? 'Possible money request spam' : 'Safe',
    raw: results
  };
};