# Animem Uz - Rasmiy Flutter Mobil Ilovasi 📱

Ushbu papkada **Animem.uz** platformasining rasmiy Android va iOS uchun to'liq Flutter mobil ilovasi joylashgan. Ilova to'g'ridan-to'g'ri sayt backend API va Socket.IO serveri bilan 100% sinxron ishlaydi.

---

## ✨ Ilova Imkoniyatlari (Features):

1. **🎬 Professional Video Player:**
   - HLS (.m3u8), MP4 va barcha video formatlarni qo'llab-quvvatlaydi.
   - 10 soniya oldinga/orqaga o'tkazish, ijro tezligi (0.5x, 1x, 1.5x, 2x).
   - Qismlarni tezkor almashtirish va to'liq ekran rejimi.
   - Ko'rish tarixini avtomatik saqlash.

2. **🔥 Animelar va Mangalar Katalogi:**
   - Janrlar, yil, studiya va holat bo'yicha saralash va tezkor qidiruv.
   - Mangalarni o'qish (Manga Reader) rejimi.
   - Chiqish jadvali (Dushanba - Yakshanba).
   - Top 100 reytingi.

3. **💬 Sayt bilan 100% Sinxron Chat va Izohlar:**
   - Saytda yozilgan xabarlar ilovada, ilovada yozilgan xabarlar esa saytda real vaqtda ko'rinadi (Socket.IO).
   - Izoh qoldirish, javob berish (reply) va like bosish.
   - 1-10 ballik yulduzchali baholash tizimi.

4. **👤 Profil va Rasmlar Yuklash:**
   - Qurilma galereyasidan profil rasmi (avatar) va bannerini yuklash (`image_picker`).
   - Ism, bio va ijtimoiy tarmoqlar (Telegram, Instagram, TikTok, YouTube, Discord) sozlamalari.
   - Sevimlilar / Xatcho'plar va Ko'rish tarixi.

5. **🔐 Autentifikatsiya:**
   - Email va Parol orqali kirish / Ro'yxatdan o'tish.
   - Google orqali bitta tugma bilan kirish (Google Sign-In).

---

## 🚀 APK Yaratish (Build APK):

### 1-usul: GitHub Actions orqali (Eng oson 1-click usul)
Loyiha ichiga `.github/workflows/build-apk.yml` fayli qo'shilgan.
1. Kodlarni GitHub-ga push qiling.
2. GitHub-da **Actions** bo'limiga o'ting.
3. **"Build Animem Uz APK"** workflow-ni tanlab **"Run workflow"** tugmasini bosing.
4. 2-3 daqiqada tayyor `Animem-Uz-Release-APK` yuklab olishingiz uchun paydo bo'ladi!

### 2-usul: Kompyuteringizda (Terminal orqali)
```bash
cd ilova
flutter pub get
flutter build apk --release
```
Tayyor APK fayl manzili:
`ilova/build/app/outputs/flutter-apk/app-release.apk`
