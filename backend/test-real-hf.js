require('dotenv').config();
const { checkMessageSafety } = require('./services/messageModerationService.js');

async function test() {
  try {
    const res1 = await checkMessageSafety("fuck you cunt");
    console.log("Test 1:", JSON.stringify(res1, null, 2));
  } catch(e) {
    console.error("Test 1 error:", e.message);
  }
}
test();
