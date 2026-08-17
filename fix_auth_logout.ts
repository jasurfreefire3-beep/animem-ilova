import fs from 'fs';

let authService = fs.readFileSync('ilova/lib/services/auth_service.dart', 'utf8');

// Remove any remaining reference to _googleSignIn in logout or anywhere else
authService = authService.replace(/await\s+_googleSignIn\.signOut\(\);\s*/g, '');

fs.writeFileSync('ilova/lib/services/auth_service.dart', authService);
console.log('Removed _googleSignIn from auth_service.dart');
