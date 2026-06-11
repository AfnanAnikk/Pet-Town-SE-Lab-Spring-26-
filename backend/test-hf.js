require('dotenv').config();
const { checkMessageSafety } = require('./services/messageModerationService.js');
checkMessageSafety("you are an idiot").then(console.log).catch(e => console.error(e.message));
