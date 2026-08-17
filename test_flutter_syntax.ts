import fs from 'fs';
const file = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');
if (file.includes('Future<void> _loginWithGoogle')) {
  console.log("login_screen OK");
}
