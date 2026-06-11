const https = require('https');
const data = JSON.stringify({ inputs: "fuck you cunt" });

const options = {
  hostname: 'router.huggingface.co',
  path: '/hf-inference/models/unitary/toxic-bert',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => console.log('Response:', body));
});

req.on('error', e => console.error(e));
req.write(data);
req.end();
