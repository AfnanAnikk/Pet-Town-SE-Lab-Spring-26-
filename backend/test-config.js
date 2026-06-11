const https = require('https');
https.get('https://huggingface.co/unitary/toxic-bert/raw/main/config.json', (res) => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => console.log(body.substring(0, 500)));
}).on('error', e => console.error(e));
