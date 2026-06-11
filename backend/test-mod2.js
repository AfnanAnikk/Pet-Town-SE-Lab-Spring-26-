const { checkMessageSafety } = require('./services/messageModerationService.js');

// mock process.env
process.env.HUGGINGFACE_API_KEY = 'hf_dummy_key_for_test';

// mock axios
const axios = require('axios');
axios.post = async () => {
  return {
    data: [] // mock empty response from HF
  };
};

async function test() {
  try {
    const res2 = await checkMessageSafety("send me $100");
    console.log("Test 2:", res2);
  } catch(e) {
    console.error(e);
  }
}
test();
