import fs from 'fs';

let pubspec = fs.readFileSync('ilova/pubspec.yaml', 'utf8');

if (!pubspec.includes('assets/images/telegram_icon.png')) {
  // Ensure assets section exists
  if (pubspec.includes('assets:')) {
    pubspec = pubspec.replace('assets:', 'assets:\n    - assets/images/telegram_icon.png');
  } else {
    pubspec = pubspec.replace('flutter:', 'flutter:\n  assets:\n    - assets/images/telegram_icon.png');
  }
  fs.writeFileSync('ilova/pubspec.yaml', pubspec);
  console.log('Added telegram icon to pubspec assets');
}
