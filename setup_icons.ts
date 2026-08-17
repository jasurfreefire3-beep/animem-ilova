import fs from 'fs';

// Check pubspec.yaml for flutter_launcher_icons config
let pubspec = fs.readFileSync('ilova/pubspec.yaml', 'utf8');

if (!pubspec.includes('flutter_launcher_icons:')) {
  const launcherConfig = `
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 21
`;
  pubspec += '\n' + launcherConfig;
  fs.writeFileSync('ilova/pubspec.yaml', pubspec);
}
console.log('Launcher icon configured in pubspec.yaml');
