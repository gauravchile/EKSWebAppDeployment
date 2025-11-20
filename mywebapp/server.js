const express = require('express');
const app = express();

app.get('/healthz', (req, res) => res.send('OK'));
app.get('/ready', (req, res) => res.send('READY'));
app.get('/', (req, res) => res.send('Hello from EKS WebApp!'));

app.listen(8080, () => console.log('Server running on port 8080'));
