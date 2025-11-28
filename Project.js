const fs = require('fs');
const zlib = require('zlib');
const { PassThrough } = require('stream');
const pipermail = require('pipermail');

// Configure options (you can limit messages if needed)
const options = {
  // max: 1000, // uncomment to limit messages
  // from: '2025-01-01', // example filter
};

async function fetchAndSave() {
  try {
    // Get stream of JSON objects from the mailing list
    const parsed = pipermail('https://mail.mozilla.org/pipermail/es-discuss/', options);

    // Convert objects to JSON strings separated by newlines
    const stringified = parsed.pipe(pipermail.stringify());

    // Use PassThrough to duplicate stream safely
    const tee = new PassThrough();

    // Pipe stringified data into tee
    stringified.pipe(tee);

    // Pipe to plain text file
    const txtStream = fs.createWriteStream('res.txt');
    tee.pipe(txtStream);

    // Pipe to gzip file
    const gzipStream = fs.createWriteStream('res.txt.gz');
    stringified.pipe(zlib.createGzip()).pipe(gzipStream);

    // Error handling
    stringified.on('error', (err) => console.error('Stringify stream error:', err));
    tee.on('error', (err) => console.error('PassThrough stream error:', err));
    txtStream.on('error', (err) => console.error('Text file error:', err));
    gzipStream.on('error', (err) => console.error('Gzip file error:', err));

    // Completion logs
    txtStream.on('finish', () => console.log('res.txt written successfully.'));
    gzipStream.on('finish', () => console.log('res.txt.gz written successfully.'));

  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

fetchAndSave();
