import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Mail, Lock, User, Phone, ArrowLeft, Loader2, CheckCircle2, Send, ShieldCheck, KeyRound, X } from 'lucide-react';
import { motion } from 'motion/react';
import { signInWithPopup, signInWithRedirect, getRedirectResult, RecaptchaVerifier, signInWithPhoneNumber, ConfirmationResult } from 'firebase/auth';
import { auth, googleProvider, facebookAuth, facebookProvider } from '../lib/firebase';

declare global {
  interface Window {
    recaptchaVerifier?: RecaptchaVerifier;
    confirmationResult?: ConfirmationResult;
  }
}

export default function Register() {
  const [signupMethod, setSignupMethod] = useState<'email' | 'phone'>('email');
  const [emailStep, setEmailStep] = useState<'email' | 'code' | 'details'>('email');
  const [phoneStep, setPhoneStep] = useState<'phone' | 'code' | 'details'>('phone');

  // Email form states
  const [email, setEmail] = useState('');
  const [verificationCode, setVerificationCode] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Phone form states
  const [phoneNumber, setPhoneNumber] = useState('');
  const [phoneCode, setPhoneCode] = useState('');
  const [phoneName, setPhoneName] = useState('');
  const [phonePassword, setPhonePassword] = useState('');
  const [phoneConfirmPassword, setPhoneConfirmPassword] = useState('');
  const [firebaseUid, setFirebaseUid] = useState('');

  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [resendMessage, setResendMessage] = useState('');
  const [error, setError] = useState('');

  const { login } = useAuth();
  const navigate = useNavigate();

  // Check for Google Auth redirect result
  useEffect(() => {
    let isMounted = true;
    getRedirectResult(auth)
      .then(async (result) => {
        if (!result || !isMounted) return;
        const user = result.user;
        const API_BASE = import.meta.env.VITE_API_BASE_URL || '';
        const res = await fetch(`${API_BASE}/api/auth/google`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ 
            email: user.email, 
            name: user.displayName || 'Google User', 
            uid: user.uid,
            avatar_url: user.photoURL
          }),
        });

        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.error || 'Google orqali kirishda xatolik');
        }

        login(data.token, data.user);
        navigate('/');
      })
      .catch((err: any) => {
        if (!isMounted) return;
        console.error("Redirect auth error:", err);
        if (err.code === 'auth/unauthorized-domain') {
          setError(
            `Google tizimiga kirish xatosi (unauthorized domain): Ushbu domen Firebase ruxsat etilgan domenlar ro'yxatida yo'q.`
          );
        } else if (err.code !== 'auth/popup-closed-by-user') {
          setError(err.message || 'Google orqali kirishda xatolik');
        }
      });

    return () => { isMounted = false; };
  }, [login, navigate]);

  // Telegram Login States
  const [showTelegramModal, setShowTelegramModal] = useState(false);
  const [telegramSessionId, setTelegramSessionId] = useState('');
  const [telegramStatus, setTelegramStatus] = useState<'pending' | 'pending_phone' | 'authorized' | 'expired' | ''>('');
  const [telegramProgress, setTelegramProgress] = useState(1);

  // Listen for OAuth popup callbacks
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.origin !== window.location.origin) return;

      if (event.data?.type === 'YANDEX_AUTH_SUCCESS' || event.data?.type === 'DISCORD_AUTH_SUCCESS') {
        const { token: userToken, user: authUser } = event.data;
        if (userToken && authUser) {
          login(userToken, authUser);
          navigate('/');
        }
      } else if (event.data?.type === 'YANDEX_AUTH_ERROR') {
        setError(event.data.error || 'Yandex avtorizatsiyasida xatolik yuz berdi');
      } else if (event.data?.type === 'DISCORD_AUTH_ERROR') {
        setError(event.data.error || 'Discord avtorizatsiyasida xatolik yuz berdi');
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [login, navigate]);

  const handleYandexLoginStart = async () => {
    try {
      setError('');
      const res = await fetch('/api/auth/yandex/url');
      const data = await res.json();

      if (data.url) {
        const authWindow = window.open(
          data.url,
          'yandex_oauth_popup',
          'width=600,height=700,top=100,left=100'
        );

        if (!authWindow) {
          window.location.href = data.url;
        }
      } else {
        throw new Error('Yandex avtorizatsiya havolasini olib bo\'lmadi');
      }
    } catch (err: any) {
      setError(err.message || 'Yandex orqali kirishda xatolik');
    }
  };

  const handleDiscordLoginStart = async () => {
    try {
      setError('');
      const res = await fetch('/api/auth/discord/url');
      const data = await res.json();
      if (!res.ok || !data.url) throw new Error(data.error || 'Discord avtorizatsiya havolasi olinmadi');

      const authWindow = window.open(data.url, 'discord_oauth_popup', 'width=600,height=700,top=100,left=100');
      if (!authWindow) window.location.href = data.url;
    } catch (err: any) {
      setError(err.message || 'Discord orqali kirishda xatolik');
    }
  };

  // Poll Telegram auth session status
  useEffect(() => {
    if (!telegramSessionId || showTelegramModal === false || telegramStatus === 'authorized') return;

    let isMounted = true;
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/auth/telegram/status/${telegramSessionId}`);
        const data = await res.json();
        
        if (!isMounted) return;

        if (data.status) {
          setTelegramStatus(data.status);
          if (data.status === 'pending_phone') {
            setTelegramProgress(2);
          } else if (data.status === 'authorized') {
            setTelegramProgress(3);
            clearInterval(interval);
            
            setTimeout(() => {
              login(data.token, data.user);
              setShowTelegramModal(false);
              navigate('/');
            }, 2500);
          } else if (data.status === 'expired') {
            setError('Telegram avtorizatsiya vaqti tugadi.');
            setShowTelegramModal(false);
            clearInterval(interval);
          }
        }
      } catch (err) {
        console.error('Error polling Telegram session:', err);
      }
    }, 2000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [telegramSessionId, showTelegramModal, telegramStatus, login, navigate]);

  const handleTelegramLoginStart = async () => {
    try {
      setError('');
      setTelegramProgress(1);
      setTelegramStatus('pending');
      
      const res = await fetch('/api/auth/telegram/session');
      const data = await res.json();
      
      if (data.sessionId) {
        setTelegramSessionId(data.sessionId);
        setShowTelegramModal(true);
      } else {
        throw new Error('Telegram seansini yaratib bo\'lmadi');
      }
    } catch (err: any) {
      setError(err.message || 'Telegram orqali kirishni boshlashda xatolik');
    }
  };

  const handleGoogleLogin = async () => {
    try {
      setError('');
      googleProvider.setCustomParameters({ prompt: 'select_account' });
      const result = await signInWithPopup(auth, googleProvider);

      if (!result || !result.user) {
        throw new Error('Google foydalanuvchi ma\'lumotlari olinmadi');
      }

      const user = result.user;
      const API_BASE = import.meta.env.VITE_API_BASE_URL || '';
      const res = await fetch(`${API_BASE}/api/auth/google`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: user.email,
          name: user.displayName || 'Google User',
          uid: user.uid,
          avatar_url: user.photoURL,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Google login failed');
      }

      login(data.token, data.user);
      navigate('/');
    } catch (err: any) {
      console.error('Google login popup error:', err);
      setError(err.message || 'Google orqali kirishda xatolik');
    }
  };

  const handleFacebookLogin = async () => {
    try {
      setError('');
      const result = await signInWithPopup(facebookAuth, facebookProvider);

      if (!result || !result.user) {
        throw new Error('Facebook foydalanuvchi ma\'lumotlari olinmadi');
      }

      const user = result.user;
      const API_BASE = import.meta.env.VITE_API_BASE_URL || '';
      const res = await fetch(`${API_BASE}/api/auth/facebook`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: user.email,
          name: user.displayName || 'Facebook User',
          uid: user.uid,
          avatar_url: user.photoURL,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Facebook login failed');
      }

      login(data.token, data.user);
      navigate('/');
    } catch (err: any) {
      console.error('Facebook login popup error:', err);
      if (err.code === 'auth/account-exists-with-different-credential') {
        setError('Bu email bilan boshqa usulda ro\'yxatdan o\'tilgan. Google yoki email orqali kiring.');
      } else if (err.code !== 'auth/popup-closed-by-user') {
        setError(err.message || 'Facebook orqali kirishda xatolik');
      }
    }
  };

  // Helper to format phone number to international standard (e.g., +998901234567)
  const formatPhone = (input: string) => {
    let digits = input.replace(/\D/g, '');
    if (!digits.startsWith('998') && digits.length <= 9) {
      digits = '998' + digits;
    }
    return '+' + digits;
  };

  // --- PHONE REGISTRATION HANDLERS ---
  const handlePhoneSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setResendMessage('');

    const formatted = formatPhone(phoneNumber);
    if (formatted.length < 12) {
      setError('Iltimos, to\'g\'ri telefon raqamini kiriting! (masalan: 901234567)');
      return;
    }

    setLoading(true);
    try {
      // 1. Try Firebase Auth Recaptcha & Phone Auth
      let firebaseSent = false;
      try {
        if (!window.recaptchaVerifier) {
          window.recaptchaVerifier = new RecaptchaVerifier(auth, 'recaptcha-container', {
            size: 'invisible',
            callback: () => {},
          });
        }
        const appVerifier = window.recaptchaVerifier;
        const confirmationResult = await signInWithPhoneNumber(auth, formatted, appVerifier);
        window.confirmationResult = confirmationResult;
        firebaseSent = true;
      } catch (fbErr: any) {
        console.warn("Firebase Phone Auth attempt:", fbErr?.message || fbErr);
      }

      // 2. Call backend server API
      const res = await fetch('/api/auth/phone-send-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: formatted, type: 'register' }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Kodni yuborishda xatolik yuz berdi');
      }

      if (data.devCode) {
        setPhoneCode(data.devCode);
      }

      setResendMessage(data.message || `SMS tasdiqlash kodi ${formatted} raqamiga yuborildi!`);
      setPhoneStep('code');
    } catch (err: any) {
      setError(err.message || 'Kodni yuborishda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const handlePhoneVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!phoneCode || phoneCode.trim().length !== 6) {
      setError('Iltimos, 6 xonali tasdiqlash kodini kiriting!');
      return;
    }

    setLoading(true);
    try {
      const formatted = formatPhone(phoneNumber);

      // Try Firebase confirm if available
      if (window.confirmationResult) {
        try {
          const result = await window.confirmationResult.confirm(phoneCode);
          if (result && result.user) {
            setFirebaseUid(result.user.uid);
          }
        } catch (fbConfirmErr: any) {
          console.warn("Firebase confirm warning:", fbConfirmErr?.message);
        }
      }

      // Verify with backend
      const res = await fetch('/api/auth/phone-verify-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: formatted, code: phoneCode, type: 'register' }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Tasdiqlash kodi xato');
      }

      setPhoneStep('details');
    } catch (err: any) {
      setError(err.message || 'Tasdiqlash kodi xato');
    } finally {
      setLoading(false);
    }
  };

  const handlePhoneCompleteRegistration = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!phoneName.trim()) {
      setError('Iltimos, ismingizni kiriting!');
      return;
    }

    if (!phonePassword || phonePassword.length < 6) {
      setError('Parol kamida 6 ta belgidan iborat bo\'lishi kerak!');
      return;
    }

    if (phonePassword !== phoneConfirmPassword) {
      setError('Kiritilgan parollar bir-biriga mos kelmadi!');
      return;
    }

    setLoading(true);
    try {
      const formatted = formatPhone(phoneNumber);
      const res = await fetch('/api/auth/phone-register-verified', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: phoneName.trim(),
          phone: formatted,
          password: phonePassword,
          code: phoneCode,
          firebaseUid,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Ro\'yxatdan o\'tishda xatolik');
      }

      login(data.token, data.user);
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Ro\'yxatdan o\'tishda xatolik');
    } finally {
      setLoading(false);
    }
  };

  // --- EMAIL REGISTRATION HANDLERS ---
  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setResendMessage('');

    if (!email || !email.includes('@')) {
      setError('Iltimos, to\'g\'ri email manzilini kiriting!');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/auth/send-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Kodni yuborishda xatolik yuz berdi');
      }

      setResendMessage(data.message || '6 xonali tasdiqlash kodi emailga yuborildi! Pochtani (va Spam papkasini) tekshiring.');
      setEmailStep('code');
    } catch (err: any) {
      setError(err.message || 'Kodni yuborishda xatolik yuz berdi');
    } finally {
      setLoading(false);
    }
  };

  const handleResendCode = async () => {
    setError('');
    setResendMessage('');
    setResending(true);
    try {
      const res = await fetch('/api/auth/send-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Kodni qayta yuborishda xatolik');
      }

      setResendMessage(data.message || 'Yangi 6 xonali kod emailga yuborildi!');
    } catch (err: any) {
      setError(err.message || 'Kodni qayta yuborishda xatolik');
    } finally {
      setResending(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!verificationCode || verificationCode.trim().length !== 6) {
      setError('Iltimos, emailga yuborilgan 6 xonali tasdiqlash kodini to\'liq kiriting!');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/auth/verify-code', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, code: verificationCode }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Kodni tekshirishda xatolik');
      }

      setEmailStep('details');
    } catch (err: any) {
      setError(err.message || 'Tasdiqlash kodi xato');
    } finally {
      setLoading(false);
    }
  };

  const handleCompleteRegistration = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!name.trim()) {
      setError('Iltimos, ismingizni kiriting!');
      return;
    }

    if (!password || password.length < 6) {
      setError('Parol kamida 6 ta belgidan iborat bo\'lishi kerak!');
      return;
    }

    if (password !== confirmPassword) {
      setError('Kiritilgan parollar bir-biriga mos kelmadi!');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/auth/register-verified', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: name.trim(),
          email,
          password,
          code: verificationCode,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Ro\'yxatdan o\'tishda xatolik');
      }

      login(data.token, data.user);
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Ro\'yxatdan o\'tishda xatolik');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[75vh] flex items-center justify-center p-4">
      <div id="recaptcha-container"></div>
      <motion.div 
        initial={{ opacity: 0, scale: 0.96 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-md bg-[#111] border border-[#222] rounded-md p-6 sm:p-8 shadow-2xl relative"
      >
        {/* Header */}
        <div className="text-center mb-6">
          <div className="relative w-16 h-16 mx-auto mb-3">
            <img 
              src="https://s3.devspace.uz/tirikchilik/local/avatar/14265509_206448_avatar.jpeg" 
              alt="Animem.uz Logo" 
              className="w-16 h-16 rounded-full object-cover border-2 border-[#ff006a] shadow-[0_0_20px_rgba(255,0,106,0.5)]"
            />
          </div>
          <h1 className="text-xl sm:text-2xl font-black text-white uppercase tracking-tight">Ro'yxatdan o'tish</h1>
          <p className="text-white/50 text-xs sm:text-sm mt-1">Animem.uz jamiyatiga xush kelibsiz!</p>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs font-bold p-3 rounded-sm mb-5 text-center leading-relaxed">
            {error}
          </div>
        )}

        {resendMessage && (
          <div className="bg-green-500/10 border border-green-500/20 text-green-400 text-xs font-bold p-3 rounded-sm mb-5 text-center">
            {resendMessage}
          </div>
        )}

        {/* ----------------- EMAIL FLOW STEP 1: ENTER EMAIL ----------------- */}
        {emailStep === 'email' && (
          <div>
            <form onSubmit={handleSendCode} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-white/70 mb-1.5 uppercase">
                  Email manzilingiz
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-4 w-4 text-white/30" />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-[#000] border border-[#222] rounded-sm pl-10 pr-4 py-3 text-white placeholder-white/30 focus:outline-none focus:border-[#ff006a] transition-colors text-sm font-medium"
                    placeholder="emailingiz@gmail.com"
                  />
                </div>
                <p className="text-[11px] text-white/40 mt-1.5">
                  Ushbu emailga 6 xonali tasdiqlash kodi yuboriladi.
                </p>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#ff006a] hover:bg-[#d40058] disabled:bg-[#ff006a]/50 text-white font-bold py-3 px-4 rounded-sm transition-colors mt-2 flex items-center justify-center gap-2 cursor-pointer shadow-lg shadow-[#ff006a]/20 text-xs uppercase tracking-wider"
              >
                {loading ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Kod yuborilmoqda...
                  </>
                ) : (
                  <>
                    <Send size={14} />
                    Kod yuborish
                  </>
                )}
              </button>
            </form>
          </div>
        )}

        {/* ----------------- EMAIL FLOW STEP 2: ENTER CODE ----------------- */}
        {signupMethod === 'email' && emailStep === 'code' && (
          <div>
            <button
              onClick={() => {
                setEmailStep('email');
                setError('');
                setResendMessage('');
              }}
              className="flex items-center gap-1.5 text-xs text-white/50 hover:text-white mb-4 transition-colors cursor-pointer"
            >
              <ArrowLeft size={14} /> Emailni o'zgartirish ({email})
            </button>

            <form onSubmit={handleVerifyCode} className="space-y-4">
              <div>
                <div className="text-center mb-4 p-3 bg-white/5 border border-white/10 rounded-sm">
                  <p className="text-xs text-white/70">
                    <strong className="text-white">{email}</strong> manziliga 6 xonali kod yuborildi.
                  </p>
                  <p className="text-[11px] text-white/40 mt-1">
                    Pochtani va Spam papkasini tekshiring
                  </p>
                </div>

                <label className="block text-xs font-bold text-white/70 mb-1.5 uppercase text-center">
                  6 xonali tasdiqlash kodi
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <KeyRound className="h-4 w-4 text-white/30" />
                  </div>
                  <input
                    type="text"
                    required
                    maxLength={6}
                    value={verificationCode}
                    onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, ''))}
                    className="w-full bg-[#000] border border-[#333] rounded-sm pl-10 pr-4 py-3 text-center text-xl font-black text-[#ff006a] tracking-[10px] placeholder-white/20 focus:outline-none focus:border-[#ff006a] transition-colors"
                    placeholder="123456"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#ff006a] hover:bg-[#d40058] text-white font-bold py-3 px-4 rounded-sm transition-colors mt-2 flex items-center justify-center gap-2 cursor-pointer shadow-lg shadow-[#ff006a]/20 text-xs uppercase tracking-wider"
              >
                {loading ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Tekshirilmoqda...
                  </>
                ) : (
                  <>
                    <ShieldCheck size={16} />
                    Kodni tasdiqlash
                  </>
                )}
              </button>

              <div className="text-center pt-2">
                <button
                  type="button"
                  disabled={resending}
                  onClick={handleResendCode}
                  className="text-xs text-[#ff006a] hover:underline disabled:opacity-50 cursor-pointer font-bold"
                >
                  {resending ? 'Qayta yuborilmoqda...' : 'Kodni qayta yuborish'}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ----------------- EMAIL FLOW STEP 3: ENTER DETAILS ----------------- */}
        {signupMethod === 'email' && emailStep === 'details' && (
          <div>
            <div className="mb-4 p-2.5 bg-green-500/10 border border-green-500/30 rounded-sm flex items-center gap-2 text-green-400 text-xs font-bold">
              <CheckCircle2 size={16} className="shrink-0" />
              <span>Email tasdiqlandi: {email}</span>
            </div>

            <form onSubmit={handleCompleteRegistration} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-white/70 mb-1.5 uppercase">
                  Ismingiz yoki Taxallusingiz
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <User className="h-4 w-4 text-white/30" />
                  </div>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full bg-[#000] border border-[#222] rounded-sm pl-10 pr-4 py-2.5 text-white placeholder-white/30 focus:outline-none focus:border-[#ff006a] transition-colors text-sm"
                    placeholder="Ismingizni kiriting"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-white/70 mb-1.5 uppercase">
                  Parol yaratish
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-4 w-4 text-white/30" />
                  </div>
                  <input
                    type="password"
                    required
                    minLength={6}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full bg-[#000] border border-[#222] rounded-sm pl-10 pr-4 py-2.5 text-white placeholder-white/30 focus:outline-none focus:border-[#ff006a] transition-colors text-sm"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-white/70 mb-1.5 uppercase">
                  Parolni tasdiqlash
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-4 w-4 text-white/30" />
                  </div>
                  <input
                    type="password"
                    required
                    minLength={6}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full bg-[#000] border border-[#222] rounded-sm pl-10 pr-4 py-2.5 text-white placeholder-white/30 focus:outline-none focus:border-[#ff006a] transition-colors text-sm"
                    placeholder="••••••••"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#ff006a] hover:bg-[#d40058] text-white font-bold py-3 px-4 rounded-sm transition-colors mt-4 flex items-center justify-center gap-2 cursor-pointer shadow-lg shadow-[#ff006a]/20 text-xs uppercase tracking-wider"
              >
                {loading ? (
                  <>
                    <Loader2 size={16} className="animate-spin" />
                    Ro'yxatdan o'tkazilmoqda...
                  </>
                ) : (
                  "Ro'yxatdan o'tishni yakunlash"
                )}
              </button>
            </form>
          </div>
        )}

        {/* Footer Link */}
        <div className="mt-6 pt-5 border-t border-[#222] text-center text-xs font-bold text-white/50">
          Allaqachon hisobingiz bormi?{' '}
          <Link to="/login" className="text-[#ff006a] hover:text-[#d40058] transition-colors uppercase tracking-wide">
            Kirish
          </Link>
        </div>
      </motion.div>

      {/* Telegram Verification Modal Overlay */}
      {showTelegramModal && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-md flex items-center justify-center p-4 z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            className="w-full max-w-md bg-[#0e0e0e] border border-white/10 rounded-lg overflow-hidden shadow-2xl relative"
          >
            <button
              onClick={() => setShowTelegramModal(false)}
              className="absolute top-4 right-4 text-white/40 hover:text-white transition-colors p-1 bg-white/5 hover:bg-white/10 rounded-full cursor-pointer z-10"
            >
              <X size={16} />
            </button>

            {telegramProgress < 3 ? (
              <div className="p-6 sm:p-8">
                <div className="text-center mb-6">
                  <div className="w-12 h-12 bg-[#0088cc]/10 rounded-full flex items-center justify-center mx-auto mb-3 border border-[#0088cc]/20">
                    <svg viewBox="0 0 24 24" className="w-6 h-6 text-[#0088cc] fill-current">
                      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm4.64 6.8c-.15 1.58-.8 5.42-1.13 7.19-.14.75-.42 1-.68 1.03-.58.05-1.02-.38-1.58-.75-.88-.58-1.38-.94-2.23-1.5-.99-.65-.35-1.01.22-1.59.15-.15 2.71-2.48 2.76-2.69.01-.03.01-.14-.07-.2-.08-.06-.19-.04-.27-.02-.12.02-1.96 1.24-5.54 3.65-.52.36-.97.53-1.34.52-.41-.01-1.21-.23-1.8-.42-.73-.24-1.32-.37-1.27-.78.02-.21.31-.43.87-.67 3.42-1.49 5.71-2.48 6.86-2.96 3.27-1.37 3.95-1.61 4.4-.1.01.03.02.05.02.08.01.12.01.25-.01.37z" />
                    </svg>
                  </div>
                  <h2 className="text-lg font-black text-white uppercase tracking-wider">Telegram orqali kirish</h2>
                  <p className="text-white/40 text-xs mt-1">Xavfsiz va tezkor avtorizatsiya tizimi</p>
                </div>

                <div className="flex justify-center items-center gap-2 mb-8">
                  <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold border transition-colors ${
                    telegramProgress === 1 
                      ? 'bg-[#0088cc]/10 border-[#0088cc]/30 text-[#0088cc]' 
                      : 'bg-white/5 border-white/10 text-white/40'
                  }`}>
                    <span className="w-4 h-4 rounded-full bg-[#0088cc] text-white flex items-center justify-center text-[9px] font-black">1</span>
                    Botga o'tish
                  </div>
                  <div className="w-4 h-[1px] bg-white/10"></div>
                  <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold border transition-colors ${
                    telegramProgress === 2 
                      ? 'bg-[#0088cc]/10 border-[#0088cc]/30 text-[#0088cc]' 
                      : 'bg-white/5 border-white/10 text-white/40'
                  }`}>
                    <span className="w-4 h-4 rounded-full bg-[#0088cc] text-white flex items-center justify-center text-[9px] font-black">2</span>
                    Kontaktni yuborish
                  </div>
                </div>

                {telegramProgress === 1 ? (
                  <div className="space-y-4 text-center">
                    <p className="text-xs text-white/70 leading-relaxed max-w-xs mx-auto">
                      Quyidagi tugmani bosing va Telegram botimizni ochib, pastda <strong className="text-[#0088cc]">"START"</strong> (Boshlash) tugmasini bosing:
                    </p>
                    <div className="py-2">
                      <a
                        href={`https://t.me/Animem_register_bot?start=${telegramSessionId}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-blue-500 to-sky-400 hover:from-blue-600 hover:to-sky-500 text-white font-bold rounded-sm shadow-lg shadow-blue-500/20 transition-all duration-300 hover:scale-[1.03] uppercase text-[10px] tracking-wider cursor-pointer"
                      >
                        <Send size={12} />
                        Telegram Botga o'tish
                      </a>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4 text-center">
                    <p className="text-xs text-white/70 leading-relaxed max-w-xs mx-auto">
                      Botda paydo bo'lgan <strong className="text-green-400">"📱 Telefon raqamni yuborish"</strong> tugmasini bosing.
                    </p>
                    <div className="inline-flex items-center gap-2 px-4 py-2 bg-yellow-500/10 border border-yellow-500/20 text-yellow-500 rounded-sm text-xs font-bold">
                      <Loader2 size={12} className="animate-spin" />
                      Telefon raqami kutilmoqda...
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="p-8 text-center flex flex-col items-center justify-center min-h-[300px]">
                <div className="relative w-24 h-24 mb-6 flex items-center justify-center">
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: [1, 1.15, 1] }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                    className="absolute inset-0 bg-green-500/10 rounded-full"
                  />
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ type: "spring", stiffness: 200, damping: 15 }}
                    className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center shadow-lg shadow-green-500/30 border border-green-400"
                  >
                    <motion.svg
                      viewBox="0 0 24 24"
                      className="w-8 h-8 text-white fill-none stroke-current"
                      strokeWidth={3}
                      initial={{ strokeDasharray: 100, strokeDashoffset: 100 }}
                      animate={{ strokeDashoffset: 0 }}
                      transition={{ delay: 0.2, duration: 0.6, ease: "easeOut" }}
                    >
                      <polyline points="20 6 9 17 4 12" />
                    </motion.svg>
                  </motion.div>
                </div>

                <motion.h2
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                  className="text-xl font-black text-white uppercase tracking-wider mb-2"
                >
                  Muvaffaqiyatli!
                </motion.h2>

                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.6 }}
                  className="text-xs text-green-400 font-bold max-w-sm leading-relaxed"
                >
                  Siz saytga muvaffaqiyatli kirdingiz! 🎉
                </motion.p>

                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.8 }}
                  className="text-[10px] text-white/30 mt-6 animate-pulse"
                >
                  Bosh sahifaga yo'naltirilmoqda...
                </motion.p>
              </div>
            )}
          </motion.div>
        </div>
      )}
    </div>
  );
}
