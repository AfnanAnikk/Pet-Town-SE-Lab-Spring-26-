require('dotenv').config();
const { checkMessageSafety } = require('./services/messageModerationService.js');

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
