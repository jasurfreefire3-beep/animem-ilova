import fs from 'fs';
let p = fs.readFileSync('ilova/pubspec.yaml', 'utf8');
p = p.replace('google_sign_in: ^6.2.1', '');
p = p.replace('google_sign_in_android: ^6.2.1', '');
p = p.replace('google_sign_in_web: ^0.12.4+4', '');
fs.writeFileSync('ilova/pubspec.yaml', p);
console.log('Removed old google plugin');
