import fs from 'fs';
const pubspec = fs.readFileSync('ilova/pubspec.yaml', 'utf8');
const pLines = pubspec.split('\n').filter(l => l.includes('google_sign_in'));
console.log(pLines);
