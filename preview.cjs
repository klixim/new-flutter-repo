const http = require('node:http');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const file = join(__dirname, 'docs', 'index.html');
const port = Number(process.env.PORT || 8080);
http.createServer((req,res) => {
  if (new URL(req.url,'http://localhost').pathname !== '/') return res.writeHead(404).end();
  res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
  res.end(readFileSync(file));
}).listen(port,'127.0.0.1',() => console.log('http://127.0.0.1:' + port));
