import fs from 'fs';
let login = fs.readFileSync('ilova/lib/screens/auth/login_screen.dart', 'utf8');
let reg = fs.readFileSync('ilova/lib/screens/auth/register_screen.dart', 'utf8');

console.log("Login screen has _loginWithGoogle:", login.includes('_loginWithGoogle'));
console.log("Register screen has _registerWithGoogle:", reg.includes('_registerWithGoogle'));
