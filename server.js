import cluster from 'node:cluster';
import os from 'node:os';
import express from 'express';
import crypto from 'crypto';
import * as circomlibjs from 'circomlibjs';

const app = express();
const PORT = 9075;
const GRID = 16;

if (cluster.isPrimary) {
  
  const numCPUs = os.cpus().length;
  console.log(`Master ${process.pid} starting ${numCPUs} workers`);
  for (let i = 0; i < numCPUs; i++) cluster.fork();

  cluster.on('exit', (worker) => {
    console.log(`Worker ${worker.process.pid} died, restarting`);
    cluster.fork();
  });
  
} else {

  app.use(express.static('public'));

  let poseidon;

  (async () => {
    poseidon = await circomlibjs.buildPoseidon();

    app.get('/api/data', (req, res) => {
      const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const result = generateData(ip);
      res.json(result);
    });

    app.listen(PORT, () => {
      console.log(`Server listening at http://localhost:${PORT}`);
    });
  })();

  function now() {
    let d = new Date();
    return d.getFullYear() + '-' +
      String(d.getMonth() + 1).padStart(2, '0') + '-' +
      String(d.getDate()).padStart(2, '0') + 'T' +
      String(d.getHours()).padStart(2, '0') + ':' +
      String(d.getMinutes()).padStart(2, '0') + ':' +
      String(d.getSeconds()).padStart(2, '0');
  }

  function generateData(ip) {
    const workerId = cluster.worker?.id;
    console.log(`${now()} W${workerId} generating new instance for ${ip}`);
    let it = 1;
    while (true) {
      const seed = BigInt('0x' + crypto.randomBytes(16).toString('hex'))
      let count = 0, empty = null;
      const data = [];

      for (let i = 0; i < GRID; i++) {
        for (let j = 0; j < GRID; j++) {
          const h = poseidon([seed, i, j]);
          const hex = BigInt(poseidon.F.toObject(h)).toString(16).padStart(64, '0');
          const firstByte = parseInt(hex.slice(62, 64), 16);
          if (firstByte === 0) {
            count++;
            empty = [i, j];
          }
          data.push({ i, j, x: (firstByte >> 4) & 0x0f, y: firstByte & 0x0f });
        }
      }
      it++;

      if (count === 1) {
        const i = empty[0], j = empty[1];
        const h = poseidon([seed, i, j]);
        const hex = BigInt(poseidon.F.toObject(h)).toString(16).padStart(64, '0');
        console.log(`${now()} W${workerId} found instance in ${it} it. for ${ip}`);
        
        return { seed: seed.toString(), data };
      }
    }
  }
}
