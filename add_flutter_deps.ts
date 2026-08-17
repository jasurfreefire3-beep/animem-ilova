import fs from 'fs';
let pubspec = fs.readFileSync('ilova/pubspec.yaml', 'utf8');

if (!pubspec.includes('app_links:')) {
    pubspec = pubspec.replace('dependencies:\n  flutter:\n    sdk: flutter', 'dependencies:\n  flutter:\n    sdk: flutter\n  app_links: ^6.3.3');
    fs.writeFileSync('ilova/pubspec.yaml', pubspec);
}
console.log('Pubspec patched');
