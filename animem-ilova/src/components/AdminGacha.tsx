import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { 
  Box, Sparkles, Plus, Edit2, Trash2, Search, Video, Image, 
  Check, X, AlertCircle, RefreshCw, Star, Shield, Film, Award, Upload
} from 'lucide-react';
import { CardData, GachaCard } from './GachaCard';
import { VideoMedia, isVideoUrl } from './VideoMedia';

interface BoxData {
  id: number;
  name: string;
  price_coins: number;
  image_url: string;
  description?: string;
  type_filter: 'all' | 'waifu' | 'husbando';
}

export default function AdminGacha() {
  const { token } = useAuth();
  const [activeSubTab, setActiveSubTab] = useState<'boxes' | 'cards'>('boxes');
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [statusMsg, setStatusMsg] = useState({ type: '', text: '' });

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, target: 'box' | 'card') => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setStatusMsg({ type: '', text: '' });
    try {
      const formData = new FormData();
      formData.append('file', file);

      const API_BASE = import.meta.env.VITE_API_BASE_URL || '';
      const res = await fetch(`${API_BASE}/api/upload`, {
        method: 'POST',
        body: formData,
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Faylni yuklashda xatolik yuz berdi");

      if (target === 'box') {
        setBoxForm((prev) => ({ ...prev, image_url: data.url }));
      } else {
        setCardForm((prev) => ({ ...prev, image_url: data.url }));
      }
      setStatusMsg({ type: 'success', text: "Fayl muvaffaqiyatli yuklandi!" });
    } catch (err: any) {
      setStatusMsg({ type: 'error', text: err.message || "Fayl yuklashda xatolik" });
    } finally {
      setUploading(false);
    }
  };

  // Data
  const [boxes, setBoxes] = useState<BoxData[]>([]);
  const [cards, setCards] = useState<CardData[]>([]);

  // Search & Filter
  const [searchQuery, setSearchQuery] = useState('');
  const [rarityFilter, setRarityFilter] = useState<string>('all');

  // Box Modal & Form
  const [isBoxModalOpen, setIsBoxModalOpen] = useState(false);
  const [editingBox, setEditingBox] = useState<BoxData | null>(null);
  const [boxForm, setBoxForm] = useState({
    name: '',
    price_coins: 200,
    image_url: '',
    description: '',
    type_filter: 'all' as 'all' | 'waifu' | 'husbando'
  });

  // Card Modal & Form
  const [isCardModalOpen, setIsCardModalOpen] = useState(false);
  const [editingCard, setEditingCard] = useState<CardData | null>(null);
  const [cardForm, setCardForm] = useState({
    name: '',
    anime: '',
    type: 'waifu' as 'waifu' | 'husbando',
    rarity: 'SR' as 'C' | 'R' | 'SR' | 'UR' | 'SSR',
    power: 2000,
    image_url: '',
    description: ''
  });

  const API_BASE = import.meta.env.VITE_API_BASE_URL || '';

  const fetchData = async () => {
    setLoading(true);
    try {
      const [boxesRes, cardsRes] = await Promise.all([
        fetch(`${API_BASE}/api/gacha/boxes`),
        fetch(`${API_BASE}/api/gacha/cards`)
      ]);
      if (boxesRes.ok) {
        const bData = await boxesRes.json();
        setBoxes(bData);
      }
      if (cardsRes.ok) {
        const cData = await cardsRes.json();
        setCards(cData);
      }
    } catch (err) {
      console.error("Gacha admin fetch error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Box Submit
  const handleBoxSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatusMsg({ type: '', text: '' });
    try {
      const payload = {
        id: editingBox ? editingBox.id : undefined,
        ...boxForm
      };
      const res = await fetch(`${API_BASE}/api/admin/gacha/boxes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Qutini saqlashda xatolik');

      setStatusMsg({ type: 'success', text: data.message });
      setIsBoxModalOpen(false);
      fetchData();
    } catch (err: any) {
      setStatusMsg({ type: 'error', text: err.message });
    }
  };

  // Delete Box
  const handleDeleteBox = async (id: number) => {
    if (!window.confirm("Haqiqatan ham ushbu qutini o'chirmoqchimisiz?")) return;
    try {
      const res = await fetch(`${API_BASE}/api/admin/gacha/boxes/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setStatusMsg({ type: 'success', text: "Quti o'chirildi!" });
      fetchData();
    } catch (err: any) {
      setStatusMsg({ type: 'error', text: err.message });
    }
  };

  // Card Submit
  const handleCardSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatusMsg({ type: '', text: '' });
    try {
      const payload = {
        id: editingCard ? editingCard.id : undefined,
        ...cardForm
      };
      const res = await fetch(`${API_BASE}/api/admin/gacha/cards`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Kartani saqlashda xatolik');

      setStatusMsg({ type: 'success', text: data.message });
      setIsCardModalOpen(false);
      fetchData();
    } catch (err: any) {
      setStatusMsg({ type: 'error', text: err.message });
    }
  };

  // Delete Card
  const handleDeleteCard = async (id: number) => {
    if (!window.confirm("Haqiqatan ham ushbu kartani o'chirmoqchimisiz?")) return;
    try {
      const res = await fetch(`${API_BASE}/api/admin/gacha/cards/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setStatusMsg({ type: 'success', text: "Karta o'chirildi!" });
      fetchData();
    } catch (err: any) {
      setStatusMsg({ type: 'error', text: err.message });
    }
  };

  // Filtered Cards
  const filteredCards = cards.filter(c => {
    const matchesQuery = c.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                         c.anime.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesRarity = rarityFilter === 'all' || c.rarity === rarityFilter;
    return matchesQuery && matchesRarity;
  });

  return (
    <div className="space-y-6">
      {/* Sub-tab Switcher & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-[#111] p-4 rounded border border-[#222]">
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setActiveSubTab('boxes')}
            className={`px-4 py-2 rounded text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeSubTab === 'boxes'
                ? 'bg-amber-500 text-black shadow-lg shadow-amber-500/20'
                : 'bg-[#222] text-white/60 hover:text-white'
            }`}
          >
            <Box size={16} />
            <span>Lootboxlar ({boxes.length})</span>
          </button>
          <button
            onClick={() => setActiveSubTab('cards')}
            className={`px-4 py-2 rounded text-xs sm:text-sm font-bold flex items-center gap-2 transition ${
              activeSubTab === 'cards'
                ? 'bg-purple-600 text-white shadow-lg shadow-purple-600/20'
                : 'bg-[#222] text-white/60 hover:text-white'
            }`}
          >
            <Sparkles size={16} />
            <span>Gacha Kartalar ({cards.length})</span>
          </button>
        </div>

        <div>
          {activeSubTab === 'boxes' ? (
            <button
              onClick={() => {
                setEditingBox(null);
                setBoxForm({
                  name: '',
                  price_coins: 200,
                  image_url: '',
                  description: '',
                  type_filter: 'all'
                });
                setIsBoxModalOpen(true);
              }}
              className="w-full sm:w-auto px-4 py-2 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-black font-extrabold rounded text-xs sm:text-sm flex items-center justify-center gap-2 transition shadow-lg"
            >
              <Plus size={16} />
              <span>Yangi Box / Quti Qo'shish</span>
            </button>
          ) : (
            <button
              onClick={() => {
                setEditingCard(null);
                setCardForm({
                  name: '',
                  anime: '',
                  type: 'waifu',
                  rarity: 'SR',
                  power: 2000,
                  image_url: '',
                  description: ''
                });
                setIsCardModalOpen(true);
              }}
              className="w-full sm:w-auto px-4 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-extrabold rounded text-xs sm:text-sm flex items-center justify-center gap-2 transition shadow-lg"
            >
              <Plus size={16} />
              <span>Yangi Gacha Karta Qo'shish</span>
            </button>
          )}
        </div>
      </div>

      {/* Status Messages */}
      {statusMsg.text && (
        <div className={`p-4 rounded text-sm font-bold flex items-center gap-3 ${
          statusMsg.type === 'success' ? 'bg-emerald-500/10 border border-emerald-500/30 text-emerald-400' : 'bg-red-500/10 border border-red-500/30 text-red-400'
        }`}>
          {statusMsg.type === 'success' ? <Check size={18} /> : <AlertCircle size={18} />}
          <span>{statusMsg.text}</span>
        </div>
      )}

      {loading ? (
        <div className="py-12 text-center text-white/40 flex flex-col items-center gap-3">
          <RefreshCw className="animate-spin" size={28} />
          <span>Gacha ma'lumotlari yuklanmoqda...</span>
        </div>
      ) : activeSubTab === 'boxes' ? (
        /* BOXES LIST */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {boxes.map((b) => (
            <div key={b.id} className="bg-[#111] border border-[#222] hover:border-amber-500/50 rounded-xl overflow-hidden flex flex-col justify-between group transition duration-300">
              <div className="relative h-48 bg-black/60 overflow-hidden">
                {isVideoUrl(b.image_url) ? (
                  <VideoMedia src={b.image_url} autoPlay loop muted playsInline className="w-full h-full object-cover group-hover:scale-105 transition duration-500" />
                ) : (
                  <img src={b.image_url} alt={b.name} className="w-full h-full object-cover group-hover:scale-105 transition duration-500" />
                )}
                <div className="absolute top-2 right-2 px-2.5 py-1 bg-black/80 backdrop-blur rounded-full border border-amber-400/40 text-amber-300 font-black text-xs">
                  🪙 {b.price_coins} Tangalar
                </div>
                <div className="absolute top-2 left-2 px-2 py-0.5 bg-purple-900/80 backdrop-blur rounded text-[10px] uppercase font-extrabold text-purple-200 border border-purple-500/30">
                  {b.type_filter}
                </div>
              </div>

              <div className="p-4 flex-1 flex flex-col justify-between space-y-3">
                <div>
                  <h3 className="font-extrabold text-white text-base group-hover:text-amber-400 transition">{b.name}</h3>
                  <p className="text-xs text-white/50 line-clamp-2 mt-1">{b.description || "Tavsif mavjud emas."}</p>
                </div>

                <div className="flex items-center justify-end space-x-2 pt-2 border-t border-[#222]">
                  <button
                    onClick={() => {
                      setEditingBox(b);
                      setBoxForm({
                        name: b.name,
                        price_coins: b.price_coins,
                        image_url: b.image_url,
                        description: b.description || '',
                        type_filter: b.type_filter
                      });
                      setIsBoxModalOpen(true);
                    }}
                    className="p-2 bg-[#222] hover:bg-amber-500 hover:text-black text-white/80 rounded transition"
                    title="Tahrirlash"
                  >
                    <Edit2 size={15} />
                  </button>
                  <button
                    onClick={() => handleDeleteBox(b.id)}
                    className="p-2 bg-[#222] hover:bg-red-600 text-white/80 hover:text-white rounded transition"
                    title="O'chirish"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* CARDS LIST WITH SEARCH & RARITY FILTERS */
        <div className="space-y-4">
          <div className="flex flex-col sm:flex-row items-center gap-3 bg-[#111] p-3 rounded border border-[#222]">
            <div className="relative flex-1 w-full">
              <Search className="absolute left-3 top-2.5 text-white/40" size={16} />
              <input
                type="text"
                placeholder="Karta nomi yoki anime bo'yicha qidirish..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-[#181818] border border-[#2a2a2a] rounded pl-9 pr-3 py-2 text-xs text-white focus:outline-none focus:border-purple-500"
              />
            </div>

            <div className="flex items-center gap-1 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
              {['all', 'C', 'R', 'SR', 'UR', 'SSR'].map((r) => (
                <button
                  key={r}
                  onClick={() => setRarityFilter(r)}
                  className={`px-3 py-1.5 rounded text-xs font-bold transition whitespace-nowrap ${
                    rarityFilter === r
                      ? 'bg-purple-600 text-white'
                      : 'bg-[#222] text-white/60 hover:text-white'
                  }`}
                >
                  {r === 'all' ? 'Barchasi' : r}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {filteredCards.map((card) => (
              <div key={card.id} className="relative group flex flex-col items-center">
                <GachaCard card={card} size="sm" showActions={false} />
                <div className="mt-2 flex items-center justify-center space-x-2 w-full max-w-[11rem]">
                  <button
                    onClick={() => {
                      setEditingCard(card);
                      setCardForm({
                        name: card.name,
                        anime: card.anime,
                        type: card.type,
                        rarity: card.rarity,
                        power: card.power,
                        image_url: card.image_url,
                        description: card.description || ''
                      });
                      setIsCardModalOpen(true);
                    }}
                    className="flex-1 py-1.5 bg-[#222] hover:bg-purple-600 text-white/80 hover:text-white rounded text-xs font-bold flex items-center justify-center gap-1 transition"
                  >
                    <Edit2 size={12} />
                    <span>Tahrirlash</span>
                  </button>
                  <button
                    onClick={() => handleDeleteCard(card.id)}
                    className="p-1.5 bg-[#222] hover:bg-red-600 text-white/80 hover:text-white rounded transition"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* BOX MODAL */}
      {isBoxModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
          <div className="bg-[#141414] border border-[#2a2a2a] w-full max-w-lg rounded-2xl p-6 shadow-2xl relative space-y-5 overflow-y-auto max-h-[90vh]">
            <button
              onClick={() => setIsBoxModalOpen(false)}
              className="absolute top-4 right-4 text-white/40 hover:text-white p-1 rounded-full bg-[#222]"
            >
              <X size={18} />
            </button>

            <h3 className="text-xl font-extrabold text-white flex items-center gap-2">
              <Box className="text-amber-400" size={22} />
              <span>{editingBox ? "Lootboxni Tahrirlash" : "Yangi Lootbox Qo'shish"}</span>
            </h3>

            <form onSubmit={handleBoxSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-white/70 mb-1">Quti Nomi *</label>
                <input
                  type="text"
                  required
                  placeholder="masalan: VIP Waifu Qutisi"
                  value={boxForm.name}
                  onChange={(e) => setBoxForm({ ...boxForm, name: e.target.value })}
                  className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Narxi (Tangada) *</label>
                  <input
                    type="number"
                    required
                    min={1}
                    value={boxForm.price_coins}
                    onChange={(e) => setBoxForm({ ...boxForm, price_coins: Number(e.target.value) })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Quti Turi</label>
                  <select
                    value={boxForm.type_filter}
                    onChange={(e: any) => setBoxForm({ ...boxForm, type_filter: e.target.value })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400"
                  >
                    <option value="all">Barchasi (All)</option>
                    <option value="waifu">Faqat Waifular</option>
                    <option value="husbando">Faqat Husbandolar</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-white/70 mb-1">Rasm yoki MP4 Video URL *</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    required
                    placeholder="https://... image.jpg yoki /uploads/..."
                    value={boxForm.image_url}
                    onChange={(e) => setBoxForm({ ...boxForm, image_url: e.target.value })}
                    className="flex-1 bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400"
                  />
                  <label className="cursor-pointer px-3 py-2 bg-amber-500/20 hover:bg-amber-500/30 border border-amber-500/40 text-amber-300 rounded text-xs font-bold flex items-center gap-1.5 transition shrink-0">
                    <Upload size={14} />
                    <span>{uploading ? "Yuklanmoqda..." : "Fayl Yuklash"}</span>
                    <input
                      type="file"
                      accept="image/*,video/mp4,video/webm"
                      className="hidden"
                      onChange={(e) => handleFileUpload(e, 'box')}
                      disabled={uploading}
                    />
                  </label>
                </div>
                <p className="text-[10px] text-white/40 mt-1">
                  💡 Rasm/Video URL paste qilishingiz yoki tugma orqali to'g'ridan-to'g'ri fayl yuklashingiz mumkin!
                </p>
              </div>

              {/* Media Preview */}
              {boxForm.image_url && (
                <div className="rounded-lg overflow-hidden border border-[#333] h-36 bg-black flex items-center justify-center relative">
                  {isVideoUrl(boxForm.image_url) ? (
                    <VideoMedia src={boxForm.image_url} autoPlay loop muted playsInline className="w-full h-full object-cover" />
                  ) : (
                    <img src={boxForm.image_url} alt="Preview" className="w-full h-full object-cover" />
                  )}
                  <span className="absolute bottom-2 left-2 px-2 py-0.5 bg-black/80 rounded text-[10px] text-amber-300 font-bold border border-amber-400/40">
                    Jonli Ko'rinish
                  </span>
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-white/70 mb-1">Tavsif (Tavsiya) </label>
                <textarea
                  rows={3}
                  placeholder="Lootbox haqida qisqacha ma'lumot..."
                  value={boxForm.description}
                  onChange={(e) => setBoxForm({ ...boxForm, description: e.target.value })}
                  className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-amber-400"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-3 border-t border-[#2a2a2a]">
                <button
                  type="button"
                  onClick={() => setIsBoxModalOpen(false)}
                  className="px-4 py-2 bg-[#222] hover:bg-[#333] text-white/70 hover:text-white rounded text-xs font-bold"
                >
                  Bekor qilish
                </button>
                <button
                  type="submit"
                  className="px-6 py-2 bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-600 hover:to-yellow-600 text-black font-extrabold rounded text-xs transition shadow-lg"
                >
                  {editingBox ? "Yangilash" : "Saqlash"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* CARD MODAL */}
      {isCardModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
          <div className="bg-[#141414] border border-[#2a2a2a] w-full max-w-2xl rounded-2xl p-6 shadow-2xl relative space-y-5 overflow-y-auto max-h-[92vh]">
            <button
              onClick={() => setIsCardModalOpen(false)}
              className="absolute top-4 right-4 text-white/40 hover:text-white p-1 rounded-full bg-[#222]"
            >
              <X size={18} />
            </button>

            <h3 className="text-xl font-extrabold text-white flex items-center gap-2">
              <Sparkles className="text-purple-400" size={22} />
              <span>{editingCard ? "Gacha Kartani Tahrirlash" : "Yangi Gacha Karta Qo'shish"}</span>
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Form Side */}
              <form onSubmit={handleCardSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Karta Nomi *</label>
                  <input
                    type="text"
                    required
                    placeholder="masalan: Gojo Satoru"
                    value={cardForm.name}
                    onChange={(e) => setCardForm({ ...cardForm, name: e.target.value })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Anime *</label>
                  <input
                    type="text"
                    required
                    placeholder="masalan: Jujutsu Kaisen"
                    value={cardForm.anime}
                    onChange={(e) => setCardForm({ ...cardForm, anime: e.target.value })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-white/70 mb-1">Toifa</label>
                    <select
                      value={cardForm.type}
                      onChange={(e: any) => setCardForm({ ...cardForm, type: e.target.value })}
                      className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                    >
                      <option value="waifu">Waifu (Qiz)</option>
                      <option value="husbando">Husbando (Yigit)</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-white/70 mb-1">Noyoblik (Rarity)</label>
                    <select
                      value={cardForm.rarity}
                      onChange={(e: any) => setCardForm({ ...cardForm, rarity: e.target.value })}
                      className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                    >
                      <option value="C">C (Common)</option>
                      <option value="R">R (Rare)</option>
                      <option value="SR">SR (Super Rare)</option>
                      <option value="UR">UR (Ultra Rare)</option>
                      <option value="SSR">SSR (Secret Super Rare)</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Kuch Tangasi (Power) *</label>
                  <input
                    type="number"
                    required
                    min={10}
                    value={cardForm.power}
                    onChange={(e) => setCardForm({ ...cardForm, power: Number(e.target.value) })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Rasm yoki MP4 Video URL *</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      required
                      placeholder="https://... card.jpg yoki /uploads/..."
                      value={cardForm.image_url}
                      onChange={(e) => setCardForm({ ...cardForm, image_url: e.target.value })}
                      className="flex-1 bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                    />
                    <label className="cursor-pointer px-3 py-2 bg-purple-600/20 hover:bg-purple-600/30 border border-purple-500/40 text-purple-300 rounded text-xs font-bold flex items-center gap-1.5 transition shrink-0">
                      <Upload size={14} />
                      <span>{uploading ? "Yuklanmoqda..." : "Fayl Yuklash"}</span>
                      <input
                        type="file"
                        accept="image/*,video/mp4,video/webm"
                        className="hidden"
                        onChange={(e) => handleFileUpload(e, 'card')}
                        disabled={uploading}
                      />
                    </label>
                  </div>
                  <p className="text-[10px] text-white/40 mt-1">
                    🎥 Rasm/Video URL paste qilishingiz yoki tugma orqali to'g'ridan-to'g'ri fayl yuklashingiz mumkin!
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-white/70 mb-1">Tavsif / Iqtibos</label>
                  <textarea
                    rows={2}
                    placeholder="Karta egasi haqida mashhur ibora..."
                    value={cardForm.description}
                    onChange={(e) => setCardForm({ ...cardForm, description: e.target.value })}
                    className="w-full bg-[#1c1c1c] border border-[#333] rounded px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
                  />
                </div>

                <div className="flex justify-end space-x-3 pt-3 border-t border-[#2a2a2a]">
                  <button
                    type="button"
                    onClick={() => setIsCardModalOpen(false)}
                    className="px-4 py-2 bg-[#222] hover:bg-[#333] text-white/70 hover:text-white rounded text-xs font-bold"
                  >
                    Bekor qilish
                  </button>
                  <button
                    type="submit"
                    className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-extrabold rounded text-xs transition shadow-lg"
                  >
                    {editingCard ? "Yangilash" : "Saqlash"}
                  </button>
                </div>
              </form>

              {/* Preview Side */}
              <div className="flex flex-col items-center justify-center p-4 bg-black/40 rounded-xl border border-[#222]">
                <span className="text-xs font-extrabold text-purple-400 uppercase tracking-widest mb-3">
                  Karta Jonli Ko'rinishi
                </span>
                <GachaCard
                  card={{
                    id: 9999,
                    name: cardForm.name || "Karta Nomi",
                    anime: cardForm.anime || "Anime Nomi",
                    type: cardForm.type,
                    rarity: cardForm.rarity,
                    power: cardForm.power || 1000,
                    image_url: cardForm.image_url || "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600",
                    description: cardForm.description
                  }}
                  size="md"
                  showActions={false}
                />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
