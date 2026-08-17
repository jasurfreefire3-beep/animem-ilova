import fs from 'fs';

let authProvider = fs.readFileSync('ilova/lib/providers/auth_provider.dart', 'utf8');

// Remove loginWithGoogle method from provider if it still exists
const providerMethodRegex = /Future<bool> loginWithGoogle\(\) async \{[\s\S]*?^  \}\n/m;
authProvider = authProvider.replace(providerMethodRegex, '');

fs.writeFileSync('ilova/lib/providers/auth_provider.dart', authProvider);
console.log('auth_provider.dart cleaned');
