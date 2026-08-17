import fs from 'fs';

let authService = fs.readFileSync('ilova/lib/services/auth_service.dart', 'utf8');

// Remove import of google_sign_in
authService = authService.replace("import 'package:google_sign_in/google_sign_in.dart';", "");

// Remove _googleSignIn field and its initialization if any
authService = authService.replace(/final GoogleSignIn _googleSignIn = GoogleSignIn\([\s\S]*?\);\n/g, '');

// Remove loginWithGoogle method entirely since we now use browser-based redirect/deep link loginWithToken
const loginWithGoogleRegex = /Future<Map<String, dynamic>> loginWithGoogle\(\) async \{[\s\S]*?^  \}\n/m;
authService = authService.replace(loginWithGoogleRegex, '');

fs.writeFileSync('ilova/lib/services/auth_service.dart', authService);
console.log('auth_service.dart cleaned from google_sign_in references');
