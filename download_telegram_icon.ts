import fs from 'fs';
import https from 'https';

const url = 'https://static.vecteezy.com/system/resources/previews/047/580/495/non_2x/telegram-logo-icon-free-png.png';
const file = fs.createWriteStream('ilova/assets/images/telegram_icon.png');

https.get(url, (response) => {
  response.pipe(file);
  file.on('finish', () => {
    file.close();
    console.log('Telegram icon downloaded successfully');
  });
}).on('error', (err) => {
  console.error('Error downloading telegram icon:', err.message);
});
