import fs from 'fs';

let server = fs.readFileSync('server.ts', 'utf8');

const newEndpoints = `
import { OAuth2Client } from 'google-auth-library';
const googleClient = new OAuth2Client(process.env.VITE_FIREBASE_API_KEY); // Using generic client or passing client ID

// New endpoint for browser redirect
app.get("/api/auth/google/mobile-login", (req, res) => {
  // Redirect browser to Google
  const redirectUri = \`https://animem.uz/api/auth/google/mobile-callback\`;
  const url = \`https://accounts.google.com/o/oauth2/v2/auth?client_id=155117606908-724599o40f7d54rch2edv2ok9q91eeb1.apps.googleusercontent.com&redirect_uri=\${encodeURIComponent(redirectUri)}&response_type=code&scope=email%20profile\`;
  res.redirect(url);
});

app.get("/api/auth/google/mobile-callback", async (req, res) => {
  const code = req.query.code;
  if (!code) return res.send("Google bilan bog'lanishda xatolik.");

  try {
    const redirectUri = \`https://animem.uz/api/auth/google/mobile-callback\`;
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code: code as string,
        client_id: "155117606908-724599o40f7d54rch2edv2ok9q91eeb1.apps.googleusercontent.com",
        client_secret: process.env.GOOGLE_CLIENT_SECRET || "",
        redirect_uri: redirectUri,
        grant_type: 'authorization_code',
      }),
    });
    
    const tokenData = await tokenResponse.json();
    if (!tokenData.id_token) return res.send("Google tokenni olishda xatolik: " + JSON.stringify(tokenData));

    // Decode ID token
    const client = new OAuth2Client("155117606908-724599o40f7d54rch2edv2ok9q91eeb1.apps.googleusercontent.com");
    const ticket = await client.verifyIdToken({
      idToken: tokenData.id_token,
      audience: "155117606908-724599o40f7d54rch2edv2ok9q91eeb1.apps.googleusercontent.com",
    });
    const payload = ticket.getPayload();
    if (!payload) return res.send("Google profilingizni o'qib bo'lmadi");

    const email = payload.email!;
    const name = payload.name || "Google User";
    const avatar_url = payload.picture;

    // Login or Register in DB
    let [users]: any = await dbQuery("SELECT * FROM users WHERE email = ?", [email]);
    let user = users[0];

    if (!user) {
      const role = email === "mosinjonovjasurbek28@gmail.com" ? "admin" : "user";
      const randomPass = Math.random().toString(36).slice(-8);
      const hashedPassword = await bcrypt.hash(randomPass, 10);
      
      const [result]: any = await dbQuery(
        "INSERT INTO users (name, email, password, role, avatar_url) VALUES (?, ?, ?, ?, ?)",
        [name, email, hashedPassword, role, avatar_url || null]
      );
      
      user = {
        id: result.insertId,
        name,
        email,
        role,
        avatar_url: avatar_url || null,
      };
    } else {
      if (avatar_url && !user.avatar_url) {
        await dbQuery("UPDATE users SET avatar_url = ? WHERE id = ?", [avatar_url, user.id]);
        user.avatar_url = avatar_url;
      }
    }

    const tokenPayload = {
      id: user.id,
      email: user.email,
      role: user.role,
    };
    const jwtToken = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: "30d" });

    // Redirect to Deep Link
    res.redirect(\`animem://auth?token=\${jwtToken}\`);
  } catch (err) {
    console.error(err);
    res.send("Server xatoligi yuz berdi");
  }
});
`;

if (!server.includes('/api/auth/google/mobile-login')) {
    server = server.replace('app.post("/api/auth/google"', newEndpoints.trim() + '\n\napp.post("/api/auth/google"');
    fs.writeFileSync('server.ts', server);
}
console.log('Server patched');
