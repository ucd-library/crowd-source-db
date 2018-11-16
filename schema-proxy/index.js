const express = require('express');
const bodyParse = require('body-parser');
const app = express();
const proxy = require('./lib/proxy');

app.use(bodyParse.text({
  type : '*/*',
  limit : '5mb'
}));

app.use((req, res) => proxy.middleware(req, res));

app.listen(3000, () => {
  console.log('schema proxy server ready on port 3000');
});