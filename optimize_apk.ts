import fs from 'fs';

let gradle = fs.readFileSync('ilova/android/app/build.gradle', 'utf8');

// Enable shrinking and resource shrinking to reduce APK size significantly
if (!gradle.includes('isMinifyEnabled true')) {
  gradle = gradle.replace(
    / buildTypes \{[\s\S]*?release \{/m,
    ` buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            signingConfig signingConfigs.release
`
  );
  fs.writeFileSync('ilova/android/app/build.gradle', gradle);
  console.log('App size optimization enabled in build.gradle');
}
