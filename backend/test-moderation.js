const { checkMessageSafety } = require('./services/messageModerationService.js');

// mock process.env
process.env.HUGGINGFACE_API_KEY = 'hf_dummy_key_for_test';

// mock axios
const axios = require('axios');
jest = { mock: () => {} }; // dummy
axios.post = async () => {
  return {
    data: [
      { label: 'toxic', score: 0.99 }
    ]
  };
};

async function test() {
  try {
    const res1 = await checkMessageSafety("fuck you cunt");
    console.log("Test 1:", res1);
    const res2 = await checkMessageSafety("send me $100");
    console.log("Test 2:", res2);
  } catch(e) {
    console.error(e);
  }
}
test();
