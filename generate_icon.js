const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 1024;

// Генерируем пиксели
const rows = [];
for (let y = 0; y < SIZE; y++) {
  const row = [];
  for (let x = 0; x < SIZE; x++) {
    const cx = SIZE / 2, cy = SIZE / 2;
    const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
    const blend = Math.max(0, 1 - dist / 380);

    // Тёмный фон с индиго градиентом
    let r = Math.round(10 + (x / SIZE) * 60 + blend * 89);
    let g = Math.round(10 + blend * 92);
    let b = Math.round(20 + (x / SIZE) * 100 + blend * 200);

    r = Math.min(255, r);
    g = Math.min(255, g);
    b = Math.min(255, b);
    row.push(r, g, b);
  }
  rows.push(row);
}

// PNG encoder
function u32(n) { const b = Buffer.alloc(4); b.writeUInt32BE(n); return b; }
function chunk(type, data) {
  const t = Buffer.from(type);
  const crc = zlib.crc32(Buffer.concat([t, data]));
  return Buffer.concat([u32(data.length), t, data, u32(crc)]);
}

// Raw image data
const raw = Buffer.alloc(SIZE * (SIZE * 3 + 1));
let pos = 0;
for (let y = 0; y < SIZE; y++) {
  raw[pos++] = 0; // filter type
  for (let x = 0; x < SIZE; x++) {
    raw[pos++] = rows[y][x * 3];
    raw[pos++] = rows[y][x * 3 + 1];
    raw[pos++] = rows[y][x * 3 + 2];
  }
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;  // bit depth
ihdr[9] = 2;  // color type RGB
ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

const idat = zlib.deflateSync(raw);

const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk('IHDR', ihdr),
  chunk('IDAT', idat),
  chunk('IEND', Buffer.alloc(0)),
]);

const outDir = path.join(__dirname, 'AIChatApp', 'Assets.xcassets', 'AppIcon.appiconset');
fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, 'AppIcon.png');
fs.writeFileSync(outPath, png);
console.log('Icon generated:', outPath, `(${(png.length / 1024).toFixed(1)} KB)`);
