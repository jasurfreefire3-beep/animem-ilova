import fs from 'fs';

let content = fs.readFileSync('server.ts', 'utf8');

// 1. Add appLoginCodes map
if (!content.includes('const appLoginCodes = new Map<string, any>();')) {
    content = content.replace(
        'const activeSessions = new Map<string, any>();',
        'const activeSessions = new Map<string, any>();\nconst appLoginCodes = new Map<string, any>();'
    );
}

// 2. Add endpoint to verify code
if (!content.includes('app.post("/api/auth/telegram/code"')) {
    const codeEndpoint = `
// Endpoint to verify 6-digit code for mobile app
app.post("/api/auth/telegram/code", async (req, res) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: "Kod kiritilmadi" });
  
  const loginData = appLoginCodes.get(code);
  if (!loginData) return res.status(400).json({ error: "Kod noto'g'ri yoki yaroqsiz" });
  
  if (Date.now() > loginData.expires) {
    appLoginCodes.delete(code);
    return res.status(400).json({ error: "Kod muddati tugagan" });
  }
  
  appLoginCodes.delete(code);
  return res.json({ token: loginData.token, user: loginData.user });
});
`;
    content = content.replace('app.get("/api/auth/telegram/session"', codeEndpoint + '\napp.get("/api/auth/telegram/session"');
}

// 3. Modify bot handlers
const newBotLogic = `
            const defaultKeyboard = {
              keyboard: [
                [ { text: "📱 Telefon raqamni yuborish", request_contact: true } ],
                [ { text: "🔐 Ilovaga kirish kodi" } ]
              ],
              resize_keyboard: true
            };

            // 1. Handle "/start auth_SESSION_ID" or app
            if (text.startsWith("/start")) {
              const parts = text.split(" ");
              const startParam = parts[1] || "";

              if (startParam && startParam.startsWith("app")) {
                await sendTelegramMessage(chat.id,
                  \`<b>Assalomu alaykum, \${from.first_name || 'Foydalanuvchi'}! 👋</b>\\n\\n\` +
                  \`Siz <b>ANIMEUZ</b> mobil ilovasiga kirishni tanladingiz.\\n\\n\` +
                  \`Iltimos, profilingizni tasdiqlash uchun pastdagi <b>"📱 Telefon raqamni yuborish"</b> tugmasini bosing yoki avval ro'yxatdan o'tgan bo'lsangiz <b>"🔐 Ilovaga kirish kodi"</b> ni bosing.\`,
                  defaultKeyboard
                );
              } else if (startParam && startParam.startsWith("auth_")) {
                const sessionId = startParam;

                activeSessions.set(sessionId, {
                  status: "pending_phone",
                  chatId: chat.id,
                  tgUser: from,
                  createdAt: Date.now()
                });
                chatToSession.set(chat.id, sessionId);

                await sendTelegramMessage(chat.id,
                  \`<b>Assalomu alaykum, \${from.first_name || 'Foydalanuvchi'}! 👋</b>\\n\\n\` +
                  \`Siz <b>ANIMEUZ</b> saytiga kirish jarayonini boshladingiz. Kirishni tasdiqlash uchun quyidagi <b>"📱 Telefon raqamni yuborish"</b> tugmasini bosing:\`,
                  defaultKeyboard
                );
              } else if (startParam) {
`;

content = content.replace(/(\/\/ 1\. Handle "\/start auth_SESSION_ID"[\s\S]*?)else if \(startParam\) {/, newBotLogic + '              } else if (startParam) {');

// Fix fallback /start
content = content.replace(
    /await sendTelegramMessage\(chat\.id,\s*\`<b>Assalomu alaykum! 👋<\/b>\\n\\n\` \+\s*\`ANIMEUZ rasmiy botiga xush kelibsiz\.\\n\\n\` \+\s*\`Siz saytga xavfsiz va tezkor kirish uchun saytdagi <b>"Telegram bilan kirish"<\/b> tugmasini bosing va ushbu botga o'ting\.\`\s*\);/,
    `await sendTelegramMessage(chat.id,
                  \`<b>Assalomu alaykum! 👋</b>\\n\\n\` +
                  \`ANIMEUZ rasmiy botiga xush kelibsiz.\\n\\n\` +
                  \`Siz saytga xavfsiz va tezkor kirish uchun saytdagi <b>"Telegram bilan kirish"</b> tugmasini bosing va ushbu botga o'ting.\`,
                  defaultKeyboard
                );`
);

// 4. Add "Ilovaga kirish kodi" handling
const codeGenLogic = `
            }
            // 1.5 Handle Ilovaga kirish kodi
            else if (text === "🔐 Ilovaga kirish kodi") {
              const tgUserId = from.id || chat.id;
              const [users]: any = await dbQuery("SELECT * FROM users WHERE telegram_id = ?", [String(tgUserId)]);
              const user = users[0];
              
              if (!user) {
                await sendTelegramMessage(chat.id, 
                  "Siz hali ro'yxatdan o'tmagansiz! Iltimos, avval pastdagi <b>📱 Telefon raqamni yuborish</b> tugmasini bosing.", 
                  defaultKeyboard
                );
              } else {
                const code = Math.floor(100000 + Math.random() * 900000).toString();
                const userPayload = {
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  role: user.role,
                  avatar_url: user.avatar_url,
                };
                const tokenPayload = {
                  id: user.id,
                  email: user.email,
                  role: user.role,
                };
                const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: "30d" });
                
                appLoginCodes.set(code, {
                  user: userPayload,
                  token,
                  expires: Date.now() + 5 * 60 * 1000 // 5 minutes
                });
                
                await sendTelegramMessage(chat.id,
                  \`Sizning ilovaga kirish kodingiz:\\n\\n\` +
                  \`<pre>\${code}</pre>\\n\\n\` +
                  \`Ushbu kodni mobil ilovaga kiriting. Kod 5 daqiqa davomida amal qiladi.\`,
                  defaultKeyboard
                );
              }
            }
            // 2. Handle Contact (Phone sharing)
`;
content = content.replace(/(\}\s*\/\/\ 2\. Handle Contact \(Phone sharing\))/, codeGenLogic.trim() + '\n            // 2. Handle Contact (Phone sharing)');

// And after contact success, optionally send the code if it was an app login
const contactSuccessBlock = `
                  // Mark session authorized
                  if (sessionId && activeSessions.has(sessionId)) {
                    activeSessions.set(sessionId, {
                      status: "authorized",
                      token,
                      user: userPayload,
                      createdAt: activeSessions.get(sessionId).createdAt || Date.now()
                    });

                    await sendTelegramMessage(chat.id,
                      \`<b>Siz ANIMEUZ saytiga muvaffaqiyatli kirdingiz! 🎉</b>\\n\\n\` +
                      \`👤 <b>Ism:</b> \${name}\\n\` +
                      (phone ? \`📞 <b>Telefon:</b> \${phone}\\n\\n\` : '\\n') +
                      \`Saytda avtorizatsiya yakunlandi! Endi saytga qaytib tomoshani davom ettirishingiz mumkin.\`,
                      defaultKeyboard
                    );
                  } else {
                    // It was an app login or direct contact share
                    const code = Math.floor(100000 + Math.random() * 900000).toString();
                    appLoginCodes.set(code, {
                      user: userPayload,
                      token,
                      expires: Date.now() + 5 * 60 * 1000
                    });
                    
                    await sendTelegramMessage(chat.id,
                      \`<b>Muvaffaqiyatli ro'yxatdan o'tdingiz! 🎉</b>\\n\\n\` +
                      \`Sizning mobil ilovaga kirish kodingiz:\\n\\n\` +
                      \`<pre>\${code}</pre>\\n\\n\` +
                      \`Ushbu kodni mobil ilovaga kiriting. Kod 5 daqiqa davomida amal qiladi.\`,
                      defaultKeyboard
                    );
                  }
`;

content = content.replace(/\/\/ Mark session authorized[\s\S]*?(?=catch \(contactErr\))/m, contactSuccessBlock);

fs.writeFileSync('server.ts', content);
console.log('Patch complete!');
