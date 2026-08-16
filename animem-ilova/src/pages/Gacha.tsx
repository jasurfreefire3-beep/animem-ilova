import React, { useState, useEffect } from "react";
import confetti from "canvas-confetti";
import {
  Sparkles,
  Gift,
  Coins,
  Shield,
  Trophy,
  ShoppingCart,
  Repeat,
  Heart,
  Search,
  Filter,
  Zap,
  CheckCircle,
  X,
  Play,
  RotateCcw,
  Star,
  Users,
  Flame,
  Swords,
  Crown,
  ShieldAlert,
  Plus,
  HelpCircle,
  ChevronRight
} from "lucide-react";
import { GachaCard, CardData } from "../components/GachaCard";
import { VideoMedia, isVideoUrl } from "../components/VideoMedia";
import { soundFx } from "../lib/audio-effects";

interface BoxData {
  id: number;
  name: string;
  price_coins: number;
  image_url: string;
  description: string;
  type_filter: string;
}

interface MarketItem {
  market_id: number;
  price_coins: number;
  listed_at: string;
  seller_id: number;
  seller_name: string;
  seller_avatar?: string;
  user_card_id: number;
  serial_number: number;
  card_id: number;
  name: string;
  anime: string;
  type: "waifu" | "husbando";
  rarity: "C" | "R" | "SR" | "UR" | "SSR";
  power: number;
  image_url: string;
  description?: string;
}

interface LeaderboardUser {
  id: number;
  name: string;
  avatar_url?: string;
  coins: number;
  total_cards: number;
  total_power: number;
  ssr_count: number;
}

export default function Gacha() {
  const [activeTab, setActiveTab] = useState<"boxes" | "squad" | "inventory" | "market" | "leaderboard" | "catalog">("boxes");

  // User State
  const [coins, setCoins] = useState<number>(0);
  const [canClaimDaily, setCanClaimDaily] = useState<boolean>(false);
  const [userToken, setUserToken] = useState<string | null>(localStorage.getItem("token"));

  // Data States
  const [boxes, setBoxes] = useState<BoxData[]>([]);
  const [myCards, setMyCards] = useState<CardData[]>([]);
  const [totalPower, setTotalPower] = useState<number>(0);
  const [marketItems, setMarketItems] = useState<MarketItem[]>([]);
  const [leaderboard, setLeaderboard] = useState<LeaderboardUser[]>([]);
  const [catalog, setCatalog] = useState<CardData[]>([]);

  // Squad State (Max 5 cards)
  const [squadIds, setSquadIds] = useState<number[]>(() => {
    try {
      return JSON.parse(localStorage.getItem("gacha_squad_ids") || "[]");
    } catch {
      return [];
    }
  });

  // Filter States
  const [filterRarity, setFilterRarity] = useState<string>("ALL");
  const [filterType, setFilterType] = useState<string>("ALL");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Messages
  const [errorMsg, setErrorMsg] = useState<string>("");
  const [successMsg, setSuccessMsg] = useState<string>("");

  // Animation Pull Modal State
  const [isPulling, setIsPulling] = useState<boolean>(false);
  const [pullStage, setPullStage] = useState<"charging" | "shaking" | "exploding" | "revealed">("charging");
  const [selectedBox, setSelectedBox] = useState<BoxData | null>(null);
  const [pulledCards, setPulledCards] = useState<CardData[]>([]);

  // Sell Modal State
  const [sellModalCard, setSellModalCard] = useState<CardData | null>(null);
  const [sellPriceInput, setSellPriceInput] = useState<string>("500");

  // Battle Arena Arena Modal
  const [showBattleModal, setShowBattleModal] = useState<boolean>(false);
  const [battleStage, setBattleStage] = useState<"prep" | "fighting" | "won" | "lost">("prep");
  const [playerHp, setPlayerHp] = useState<number>(100);
  const [opponentHp, setOpponentHp] = useState<number>(100);
  const [battleLog, setBattleLog] = useState<string[]>([]);

  // Initial Fetching
  useEffect(() => {
    fetchCoins();
    fetchBoxes();
    fetchInventory();
  }, []);

  useEffect(() => {
    localStorage.setItem("gacha_squad_ids", JSON.stringify(squadIds));
  }, [squadIds]);

  useEffect(() => {
    if (activeTab === "inventory") fetchInventory();
    if (activeTab === "market") fetchMarket();
    if (activeTab === "leaderboard") fetchLeaderboard();
    if (activeTab === "catalog") fetchCatalog();
  }, [activeTab, filterRarity, filterType, searchQuery]);

  // Fetch Coins & Daily
  const fetchCoins = async () => {
    const token = localStorage.getItem("token");
    if (!token) return;
    try {
      const res = await fetch("/api/gacha/coins", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setCoins(data.coins);
        setCanClaimDaily(data.canClaimDaily);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Fetch Boxes
  const fetchBoxes = async () => {
    try {
      const res = await fetch("/api/gacha/boxes");
      if (res.ok) {
        const data = await res.json();
        setBoxes(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Fetch Inventory
  const fetchInventory = async () => {
    const token = localStorage.getItem("token");
    if (!token) return;
    try {
      const params = new URLSearchParams({
        rarity: filterRarity,
        type: filterType,
        search: searchQuery,
      });
      const res = await fetch(`/api/gacha/inventory?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        const cardsWithSquad: CardData[] = (data.cards || []).map((c: CardData) => ({
          ...c,
          in_squad: c.user_card_id ? squadIds.includes(c.user_card_id) : false,
        }));
        setMyCards(cardsWithSquad);
        setTotalPower(data.totalPower || 0);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Fetch Market
  const fetchMarket = async () => {
    try {
      const params = new URLSearchParams({
        rarity: filterRarity,
        type: filterType,
        search: searchQuery,
      });
      const res = await fetch(`/api/gacha/market?${params.toString()}`);
      if (res.ok) {
        const data = await res.json();
        setMarketItems(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Fetch Leaderboard
  const fetchLeaderboard = async () => {
    try {
      const res = await fetch("/api/gacha/leaderboard");
      if (res.ok) {
        const data = await res.json();
        setLeaderboard(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Fetch Catalog
  const fetchCatalog = async () => {
    try {
      const res = await fetch("/api/gacha/cards");
      if (res.ok) {
        const data = await res.json();
        setCatalog(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  // Toggle Squad Member (Max 5)
  const handleToggleSquad = (card: CardData) => {
    if (!card.user_card_id) return;
    soundFx.playClick();
    if (squadIds.includes(card.user_card_id)) {
      setSquadIds(squadIds.filter((id) => id !== card.user_card_id));
    } else {
      if (squadIds.length >= 5) {
        setErrorMsg("Jangiy squadda ko'pi bilan 5 ta karta bo'lishi mumkin!");
        setTimeout(() => setErrorMsg(""), 3500);
        return;
      }
      setSquadIds([...squadIds, card.user_card_id]);
    }
  };

  // Calculate Squad Combat Power
  const squadCards = myCards.filter((c) => c.user_card_id && squadIds.includes(c.user_card_id));
  const squadCombatPower = squadCards.reduce((acc, curr) => acc + curr.power, 0);

  // Daily Coin Claim
  const handleDailyClaim = async () => {
    const token = localStorage.getItem("token");
    if (!token) {
      setErrorMsg("Iltimos, tizimga kiring!");
      return;
    }
    soundFx.playClick();
    try {
      const res = await fetch("/api/gacha/daily-claim", {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      if (res.ok) {
        soundFx.playCoin();
        setCoins(data.newCoins);
        setCanClaimDaily(false);
        setSuccessMsg(`+${data.reward} kunlik tangalar balansingizga qo'shildi! 🎉`);
        setTimeout(() => setSuccessMsg(""), 4000);
      } else {
        setErrorMsg(data.error || "Xatolik yuz berdi");
        setTimeout(() => setErrorMsg(""), 4000);
      }
    } catch (e) {
      setErrorMsg("Tarmoq xatosi!");
    }
  };

  // Start Explosive Gacha Box Pull
  const handlePullBox = async (box: BoxData, count: 1 | 10) => {
    const token = localStorage.getItem("token");
    if (!token) {
      setErrorMsg("Qutini ochish uchun avval tizimga kiring!");
      setTimeout(() => setErrorMsg(""), 4000);
      return;
    }

    const totalCost = box.price_coins * count;
    if (coins < totalCost) {
      setErrorMsg(`Tanga mablag'i yetarli emas! Sizga ${totalCost} tanga kerak.`);
      setTimeout(() => setErrorMsg(""), 4000);
      return;
    }

    soundFx.playClick();
    setSelectedBox(box);
    setIsPulling(true);
    setPullStage("charging");
    setPulledCards([]);

    // Charging phase -> Shaking phase
    setTimeout(() => {
      setPullStage("shaking");
      let shakeCount = 0;
      const interval = setInterval(() => {
        soundFx.playShake();
        shakeCount++;
        if (shakeCount > 5) clearInterval(interval);
      }, 200);
    }, 600);

    try {
      const res = await fetch("/api/gacha/pull", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ box_id: box.id, count }),
      });

      const data = await res.json();

      if (!res.ok) {
        setIsPulling(false);
        setErrorMsg(data.error || "Qutini ochishda xatolik!");
        setTimeout(() => setErrorMsg(""), 4000);
        return;
      }

      setCoins(data.remainingCoins);

      // Transition to EXPLOSION Stage!
      setTimeout(() => {
        setPullStage("exploding");
        soundFx.playExplosion();

        // Determine highest rarity drawn
        const rarities = data.cards.map((c: CardData) => c.rarity);
        let highestRarity = "C";
        if (rarities.includes("SSR")) highestRarity = "SSR";
        else if (rarities.includes("UR")) highestRarity = "UR";
        else if (rarities.includes("SR")) highestRarity = "SR";
        else if (rarities.includes("R")) highestRarity = "R";

        // Confetti burst
        if (highestRarity === "SSR") {
          soundFx.playLegendary();
          confetti({
            particleCount: 200,
            spread: 120,
            origin: { y: 0.5 },
            colors: ["#ff0000", "#ffd700", "#ff00ff", "#00ffff", "#ffffff"],
          });
        } else if (highestRarity === "UR") {
          soundFx.playUltraRare();
          confetti({
            particleCount: 120,
            spread: 90,
            origin: { y: 0.5 },
            colors: ["#ffd700", "#ffa500", "#ffffff"],
          });
        } else if (highestRarity === "SR") {
          soundFx.playSuperRare();
        } else {
          soundFx.playCommon();
        }

        // Show Revealed Cards
        setTimeout(() => {
          setPulledCards(data.cards);
          setPullStage("revealed");
          fetchInventory();
        }, 1100);
      }, 2000);
    } catch (e) {
      setIsPulling(false);
      setErrorMsg("Aloqa xatosi!");
      setTimeout(() => setErrorMsg(""), 4000);
    }
  };

  // Toggle Favorite
  const handleFavoriteToggle = async (userCardId: number) => {
    const token = localStorage.getItem("token");
    if (!token) return;
    soundFx.playClick();
    try {
      await fetch("/api/gacha/favorite", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ user_card_id: userCardId }),
      });
      fetchInventory();
    } catch (e) {
      console.error(e);
    }
  };

  // Sell Card
  const handleConfirmSell = async () => {
    if (!sellModalCard?.user_card_id) return;
    const price = Number(sellPriceInput);
    if (!price || price <= 0) return;

    const token = localStorage.getItem("token");
    if (!token) return;

    soundFx.playClick();
    try {
      const res = await fetch("/api/gacha/market/sell", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          user_card_id: sellModalCard.user_card_id,
          price_coins: price,
        }),
      });

      if (res.ok) {
        setSellModalCard(null);
        setSuccessMsg("Karta bozorga muvaffaqiyatli qo'shildi!");
        setTimeout(() => setSuccessMsg(""), 4000);
        fetchInventory();
      } else {
        const data = await res.json();
        setErrorMsg(data.error || "Xatolik yuz berdi");
        setTimeout(() => setErrorMsg(""), 4000);
      }
    } catch (e) {
      setErrorMsg("Sotuvga qo'yishda xatolik");
    }
  };

  // Buy Card from Market
  const handleBuyMarketItem = async (card: CardData) => {
    const token = localStorage.getItem("token");
    if (!token) {
      setErrorMsg("Sotib olish uchun avval tizimga kiring!");
      setTimeout(() => setErrorMsg(""), 4000);
      return;
    }

    if (coins < (card.price_coins || 0)) {
      setErrorMsg("Tanga mablag'ingiz yetarli emas!");
      setTimeout(() => setErrorMsg(""), 4000);
      return;
    }

    soundFx.playClick();
    try {
      const item = marketItems.find((m) => m.user_card_id === card.user_card_id);
      if (!item) return;

      const res = await fetch("/api/gacha/market/buy", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ market_id: item.market_id }),
      });

      const data = await res.json();
      if (res.ok) {
        soundFx.playCoin();
        setCoins(data.remainingCoins);
        setSuccessMsg(`Tabriklaymiz! ${card.name} kartasi kolleksiyangizga qo'shildi! 🥳`);
        setTimeout(() => setSuccessMsg(""), 4000);
        fetchMarket();
        fetchCoins();
      } else {
        setErrorMsg(data.error || "Sotib olishda xatolik");
        setTimeout(() => setErrorMsg(""), 4000);
      }
    } catch (e) {
      setErrorMsg("Tarmoq xatosi");
    }
  };

  // Execute Arena Battle Duel
  const startBattleDuel = () => {
    if (squadCards.length === 0) {
      setErrorMsg("Avval jangiy squaddan kamida 1 ta karta tanlang!");
      setTimeout(() => setErrorMsg(""), 3500);
      return;
    }

    setShowBattleModal(true);
    setBattleStage("fighting");
    setPlayerHp(100);
    setOpponentHp(100);
    setBattleLog(["⚡ Jang boshlandi! Squadingiz maydonga tushdi!"]);

    const opponentPower = 83391;
    let pHP = 100;
    let oHP = 100;

    let turn = 0;
    const battleInterval = setInterval(() => {
      turn++;
      soundFx.playExplosion();

      // Damage calculation
      const pDamage = Math.floor((squadCombatPower / 1000) * (Math.random() * 0.4 + 0.8));
      const oDamage = Math.floor((opponentPower / 1000) * (Math.random() * 0.3 + 0.7));

      oHP = Math.max(0, oHP - pDamage);
      pHP = Math.max(0, pHP - oDamage);

      setOpponentHp(oHP);
      setPlayerHp(pHP);

      setBattleLog((prev) => [
        `Round ${turn}: Siz -${pDamage} HP zarba berdingiz! Raqib -${oDamage} HP qaytardi.`,
        ...prev,
      ]);

      if (oHP <= 0 || pHP <= 0 || turn >= 5) {
        clearInterval(battleInterval);
        if (squadCombatPower >= opponentPower * 0.75 || oHP < pHP) {
          setBattleStage("won");
          soundFx.playLegendary();
          confetti({ particleCount: 100, spread: 80 });
          setCoins((c) => c + 500);
          setSuccessMsg("G'alaba! +500 Jangiy Tanga mukofoti olindi! 🏆");
        } else {
          setBattleStage("lost");
          soundFx.playShake();
        }
      }
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-gray-100 font-sans pb-24 pt-4">
      <div className="max-w-7xl mx-auto px-4 sm:px-6">
        
        {/* TOP GAME HUD BANNER */}
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-slate-900 via-purple-950 to-slate-950 p-6 border-2 border-purple-500/40 shadow-2xl mb-8">
          <div className="absolute top-0 right-0 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-amber-400 via-pink-500 to-purple-600 p-0.5 shadow-xl">
                <div className="w-full h-full bg-slate-950 rounded-[14px] flex items-center justify-center">
                  <Crown className="w-8 h-8 text-yellow-400" />
                </div>
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded text-[10px] font-black bg-gradient-to-r from-amber-500 to-yellow-600 text-black uppercase tracking-wider shadow">
                    VIP 5 SUMMONER
                  </span>
                  <span className="text-xs text-purple-300 font-bold flex items-center gap-1">
                    <Trophy className="w-3.5 h-3.5 text-yellow-400" />
                    Winrate 90%
                  </span>
                </div>
                <h1 className="text-2xl md:text-3xl font-black text-white tracking-tight mt-1 flex items-center gap-2">
                  Animem Gacha Arena <Flame className="w-6 h-6 text-red-500 fill-current animate-pulse" />
                </h1>
                <p className="text-xs text-gray-400 mt-0.5">
                  Noyob ★5 SSR anime kartalarini to'plang va otryadingiz jangiy kuchini oshiring!
                </p>
              </div>
            </div>

            {/* TOP STATS DISPLAY */}
            <div className="flex flex-wrap items-center gap-3 bg-black/60 backdrop-blur p-3.5 rounded-2xl border border-white/10 shadow-xl">
              {/* Coin Balance */}
              <div className="flex items-center gap-2.5 px-3 py-1.5 bg-amber-950/60 border border-amber-500/40 rounded-xl">
                <Coins className="w-6 h-6 text-yellow-400" />
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-bold block">Tangalar</span>
                  <span className="text-base font-black text-yellow-400">{coins.toLocaleString()}</span>
                </div>
              </div>

              {/* Combat Power */}
              <div className="flex items-center gap-2.5 px-3 py-1.5 bg-purple-950/60 border border-purple-500/40 rounded-xl">
                <Zap className="w-6 h-6 text-purple-400 fill-current" />
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-bold block">Боевая сила</span>
                  <span className="text-base font-black text-purple-300">
                    {squadCombatPower > 0 ? squadCombatPower.toLocaleString() : totalPower.toLocaleString()}
                  </span>
                </div>
              </div>

              {/* Daily Claim */}
              <button
                onClick={handleDailyClaim}
                disabled={!canClaimDaily}
                className={`px-4 py-2.5 rounded-xl font-extrabold text-xs flex items-center gap-1.5 shadow-lg transition ${
                  canClaimDaily
                    ? "bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white animate-bounce"
                    : "bg-gray-800 text-gray-500 cursor-not-allowed border border-gray-700"
                }`}
              >
                <Gift className="w-4 h-4" />
                <span>{canClaimDaily ? "+1,000 Bonus" : "Tayyor (24s)"}</span>
              </button>
            </div>
          </div>
        </div>

        {/* NOTIFICATION MESSAGES */}
        {errorMsg && (
          <div className="mb-6 p-4 rounded-xl bg-red-950/90 border border-red-500/60 text-red-200 text-sm flex items-center gap-3 animate-bounce shadow-xl">
            <X className="w-5 h-5 text-red-400 shrink-0" />
            <span className="font-semibold">{errorMsg}</span>
          </div>
        )}
        {successMsg && (
          <div className="mb-6 p-4 rounded-xl bg-emerald-950/90 border border-emerald-500/60 text-emerald-200 text-sm flex items-center gap-3 shadow-xl">
            <CheckCircle className="w-5 h-5 text-emerald-400 shrink-0" />
            <span className="font-semibold">{successMsg}</span>
          </div>
        )}

        {/* BATTLE SQUAD SECTION (5-CARD ARENA TEAM) */}
        <div className="mb-8 bg-slate-900/90 border-2 border-purple-500/30 rounded-2xl p-5 shadow-2xl relative overflow-hidden">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-4 pb-3 border-b border-white/10">
            <div>
              <div className="flex items-center gap-2">
                <Swords className="w-5 h-5 text-red-400" />
                <h2 className="text-lg font-black text-white tracking-wide uppercase">
                  Otryad Jangiy Tarkibi (5/5)
                </h2>
              </div>
              <p className="text-xs text-gray-400 mt-0.5">
                Kartalaringizni tanlang va jang arenasiga tayyorlang
              </p>
            </div>

            <div className="flex items-center gap-4">
              <div className="text-right">
                <span className="text-[11px] text-gray-400 uppercase font-bold block">ОТРЯД БОЕВАЯ СИЛА</span>
                <span className="text-2xl font-black text-amber-400 tracking-wider flex items-center justify-end gap-1">
                  ⚡ {squadCombatPower > 0 ? squadCombatPower.toLocaleString() : "0"}
                </span>
              </div>

              <button
                onClick={startBattleDuel}
                className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-red-600 via-pink-600 to-purple-600 hover:from-red-500 hover:to-purple-500 text-white font-black text-xs uppercase tracking-wider shadow-lg transition flex items-center gap-2 animate-pulse"
              >
                <Swords className="w-4 h-4" />
                <span>PvP Jangiy Arena</span>
              </button>
            </div>
          </div>

          {/* 5 Squad Slots */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
            {[0, 1, 2, 3, 4].map((index) => {
              const card = squadCards[index];
              return card ? (
                <div key={card.user_card_id} className="relative group">
                  <GachaCard
                    card={card}
                    size="sm"
                    onToggleSquad={handleToggleSquad}
                    showActions={true}
                  />
                  <button
                    onClick={() => handleToggleSquad(card)}
                    className="absolute top-2 left-2 p-1 rounded-full bg-red-600 text-white opacity-0 group-hover:opacity-100 transition z-30 shadow"
                    title="Otryaddan chiqarish"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              ) : (
                <div
                  key={index}
                  onClick={() => setActiveTab("inventory")}
                  className="h-72 rounded-xl border-2 border-dashed border-gray-700 hover:border-purple-500/60 bg-black/40 flex flex-col items-center justify-center p-4 text-center cursor-pointer transition group"
                >
                  <div className="w-10 h-10 rounded-full bg-purple-950/50 border border-purple-500/30 flex items-center justify-center text-purple-400 mb-2 group-hover:scale-110 transition">
                    <Plus className="w-5 h-5" />
                  </div>
                  <span className="text-xs font-bold text-gray-500 group-hover:text-purple-300">
                    Karta Tanlash
                  </span>
                  <span className="text-[10px] text-gray-600 mt-1">Slot #{index + 1}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* NAVIGATION TABS */}
        <div className="flex items-center gap-2 overflow-x-auto pb-4 mb-6 border-b border-gray-800 scrollbar-none">
          {[
            { id: "boxes", label: "Lootbox Qutilari", icon: Gift },
            { id: "inventory", label: `Kolleksiya (${myCards.length})`, icon: Sparkles },
            { id: "market", label: "Bozor", icon: ShoppingCart },
            { id: "leaderboard", label: "Reyting", icon: Trophy },
            { id: "catalog", label: "Katalog", icon: Shield },
          ].map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => {
                  soundFx.playClick();
                  setActiveTab(tab.id as any);
                }}
                className={`px-5 py-2.5 rounded-xl text-xs sm:text-sm font-black flex items-center gap-2 whitespace-nowrap transition ${
                  isActive
                    ? "bg-gradient-to-r from-purple-600 to-indigo-600 text-white shadow-lg shadow-purple-500/30 border border-purple-400/40"
                    : "bg-slate-900 text-gray-400 hover:bg-slate-800 hover:text-white border border-white/5"
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? "text-amber-300" : ""}`} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>

        {/* TAB 1: LOOTBOX CHESTS */}
        {activeTab === "boxes" && (
          <div>
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h2 className="text-xl font-extrabold text-white flex items-center gap-2">
                  <Gift className="w-5 h-5 text-amber-400" />
                  Eksklyuziv Lootbox Qutilari
                </h2>
                <p className="text-xs text-gray-400 mt-0.5">
                  Super noyob ★5 SSR anime kartalarini chiqarish uchun qutini tanlang
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {boxes.map((box) => (
                <div
                  key={box.id}
                  className="bg-slate-900 border-2 border-purple-500/30 rounded-2xl overflow-hidden hover:border-amber-400/80 hover:shadow-[0_0_30px_rgba(245,158,11,0.2)] transition-all duration-300 flex flex-col justify-between group"
                >
                  <div className="relative h-56 bg-black overflow-hidden flex items-center justify-center p-4">
                    {isVideoUrl(box.image_url) ? (
                      <VideoMedia
                        src={box.image_url}
                        autoPlay
                        loop
                        muted
                        playsInline
                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500 brightness-[1.08] contrast-[1.05]"
                      />
                    ) : (
                      <img
                        src={box.image_url}
                        alt={box.name}
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-contain group-hover:scale-110 transition-transform duration-500 drop-shadow-[0_10px_20px_rgba(0,0,0,0.8)]"
                      />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-transparent to-transparent pointer-events-none" />
                    <div className="absolute top-3 right-3 bg-black/80 backdrop-blur border border-amber-500/50 text-yellow-400 font-black px-3 py-1 rounded-full text-xs flex items-center gap-1 shadow-lg z-10">
                      <Coins className="w-3.5 h-3.5 text-yellow-400" />
                      {box.price_coins.toLocaleString()}
                    </div>
                  </div>

                  <div className="p-5 flex-1 flex flex-col justify-between bg-slate-900/95 border-t border-white/5">
                    <div>
                      <h3 className="text-lg font-black text-white group-hover:text-amber-300 transition-colors">
                        {box.name}
                      </h3>
                      <p className="text-xs text-gray-400 mt-2 leading-relaxed">
                        {box.description}
                      </p>
                    </div>

                    <div className="mt-6 flex items-center gap-2">
                      <button
                        onClick={() => handlePullBox(box, 1)}
                        className="flex-1 py-2.5 rounded-xl bg-purple-700 hover:bg-purple-600 text-white font-extrabold text-xs shadow-lg transition flex items-center justify-center gap-1.5"
                      >
                        <Sparkles className="w-4 h-4 text-amber-300" />
                        <span>1x Ochish</span>
                      </button>
                      <button
                        onClick={() => handlePullBox(box, 10)}
                        className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-600 hover:from-amber-400 hover:to-yellow-500 text-black font-black text-xs shadow-lg transition flex items-center justify-center gap-1.5"
                      >
                        <Zap className="w-4 h-4 fill-current" />
                        <span>10x Ochish</span>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 2: INVENTORY */}
        {activeTab === "inventory" && (
          <div>
            <div className="mb-6 bg-slate-900/90 p-4 rounded-xl border border-white/10 flex flex-wrap items-center justify-between gap-4">
              <div className="flex flex-wrap items-center gap-3">
                <div className="flex items-center gap-1 bg-black/50 p-1 rounded-lg border border-white/10">
                  {["ALL", "C", "R", "SR", "UR", "SSR"].map((r) => (
                    <button
                      key={r}
                      onClick={() => setFilterRarity(r)}
                      className={`px-3 py-1 rounded-md text-xs font-bold transition ${
                        filterRarity === r
                          ? "bg-purple-600 text-white shadow"
                          : "text-gray-400 hover:text-white"
                      }`}
                    >
                      {r}
                    </button>
                  ))}
                </div>

                <div className="flex items-center gap-1 bg-black/50 p-1 rounded-lg border border-white/10">
                  {["ALL", "waifu", "husbando"].map((t) => (
                    <button
                      key={t}
                      onClick={() => setFilterType(t)}
                      className={`px-3 py-1 rounded-md text-xs font-bold uppercase transition ${
                        filterType === t
                          ? "bg-purple-600 text-white shadow"
                          : "text-gray-400 hover:text-white"
                      }`}
                    >
                      {t === "ALL" ? "Hammasi" : t}
                    </button>
                  ))}
                </div>
              </div>

              <div className="relative w-full sm:w-64">
                <Search className="absolute left-3 top-2.5 w-4 h-4 text-gray-500" />
                <input
                  type="text"
                  placeholder="Karta yoki anime qidirish..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-black/50 border border-white/10 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-gray-500 focus:outline-none focus:border-purple-500"
                />
              </div>
            </div>

            {myCards.length === 0 ? (
              <div className="text-center py-16 bg-slate-900/50 rounded-2xl border border-white/5">
                <Sparkles className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400 text-sm font-medium">Sizda hali kartalar yo'q. Quti ochib o'yiningizni boshlang!</p>
                <button
                  onClick={() => setActiveTab("boxes")}
                  className="mt-4 px-6 py-2.5 rounded-xl bg-purple-600 text-white font-black text-xs shadow-lg"
                >
                  Qutini Ochish
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
                {myCards.map((card) => (
                  <GachaCard
                    key={card.user_card_id}
                    card={card}
                    onFavoriteToggle={handleFavoriteToggle}
                    onSellClick={(c) => setSellModalCard(c)}
                    onToggleSquad={handleToggleSquad}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* TAB 3: MARKETPLACE */}
        {activeTab === "market" && (
          <div>
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <ShoppingCart className="w-5 h-5 text-amber-400" />
                  O'yinchilar Bozori
                </h2>
                <p className="text-xs text-gray-400 mt-1">
                  Boshqa o'yinchilar sotuvga qo'ygan kartalarni tangalarga xarid qiling!
                </p>
              </div>
            </div>

            {marketItems.length === 0 ? (
              <div className="text-center py-16 bg-slate-900/50 rounded-2xl border border-white/5">
                <ShoppingCart className="w-12 h-12 text-gray-600 mx-auto mb-3" />
                <p className="text-gray-400 text-sm">Hozirda bozor bo'sh.</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
                {marketItems.map((item) => (
                  <GachaCard
                    key={item.market_id}
                    card={{
                      user_card_id: item.user_card_id,
                      id: item.card_id,
                      name: item.name,
                      anime: item.anime,
                      type: item.type,
                      rarity: item.rarity,
                      power: item.power,
                      image_url: item.image_url,
                      description: item.description,
                      serial_number: item.serial_number,
                      price_coins: item.price_coins,
                      seller_name: item.seller_name,
                    }}
                    onBuyClick={handleBuyMarketItem}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* TAB 4: LEADERBOARD */}
        {activeTab === "leaderboard" && (
          <div className="max-w-4xl mx-auto">
            <div className="mb-6 text-center">
              <h2 className="text-2xl font-black text-white flex items-center justify-center gap-2">
                <Trophy className="w-6 h-6 text-yellow-400" />
                Global Summonerlar Reytingi
              </h2>
              <p className="text-xs text-gray-400 mt-1">
                Kolleksiyaning umumiy kuchi va kartalar soni bo'yicha eng kuchli foydalanuvchilar
              </p>
            </div>

            <div className="bg-slate-900 border border-white/10 rounded-2xl overflow-hidden shadow-2xl">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-950 text-gray-400 text-xs uppercase border-b border-white/10">
                    <th className="p-4">O'rin</th>
                    <th className="p-4">Foydalanuvchi</th>
                    <th className="p-4">Kartalar</th>
                    <th className="p-4">SSR</th>
                    <th className="p-4">Umumiy Kuch</th>
                    <th className="p-4">Balans</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5 text-sm">
                  {leaderboard.map((user, idx) => (
                    <tr key={user.id} className="hover:bg-white/5 transition">
                      <td className="p-4 font-bold text-center w-12">
                        {idx === 0 ? "🥇" : idx === 1 ? "🥈" : idx === 2 ? "🥉" : `#${idx + 1}`}
                      </td>
                      <td className="p-4 flex items-center gap-3">
                        <img
                          src={user.avatar_url || "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop"}
                          alt={user.name}
                          referrerPolicy="no-referrer"
                          className="w-8 h-8 rounded-full object-cover border border-purple-500/40"
                        />
                        <span className="font-bold text-white">{user.name}</span>
                      </td>
                      <td className="p-4 text-gray-300 font-semibold">{user.total_cards} ta</td>
                      <td className="p-4">
                        <span className="px-2 py-0.5 rounded bg-red-950 text-red-400 border border-red-500/40 font-bold text-xs">
                          {user.ssr_count} SSR
                        </span>
                      </td>
                      <td className="p-4 text-purple-300 font-black">
                        ⚡ {user.total_power.toLocaleString()}
                      </td>
                      <td className="p-4 text-yellow-400 font-bold">
                        🪙 {user.coins.toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 5: CATALOG */}
        {activeTab === "catalog" && (
          <div>
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <Shield className="w-5 h-5 text-indigo-400" />
                  Mavjud Barcha Anime Kartalari
                </h2>
                <p className="text-xs text-gray-400 mt-1">O'yindagi mavjud waifu va husbando kartalari katalogi</p>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
              {catalog.map((card) => (
                <GachaCard key={card.id} card={card} showActions={false} />
              ))}
            </div>
          </div>
        )}

        {/* EXPLOSIVE LOOTBOX OPENING MODAL */}
        {isPulling && selectedBox && (
          <div className="fixed inset-0 z-50 bg-black/95 backdrop-blur-2xl flex items-center justify-center p-4">
            <div className="text-center max-w-3xl w-full">
              {/* STAGE 1: CHARGING & SHAKING */}
              {(pullStage === "charging" || pullStage === "shaking") && (
                <div className="flex flex-col items-center justify-center min-h-[350px]">
                  <div className="relative">
                    {/* Energy Rings around chest */}
                    <div className="absolute -inset-8 rounded-full border-2 border-purple-500/40 animate-ping pointer-events-none" />
                    <div className="absolute -inset-16 rounded-full border border-amber-400/20 animate-spin pointer-events-none" />

                    {/* Glowing Box Image */}
                    <div
                      className={`relative w-56 h-56 rounded-3xl overflow-hidden border-4 border-amber-400 shadow-[0_0_50px_rgba(245,158,11,0.6)] ${
                        pullStage === "shaking" ? "animate-bounce" : ""
                      }`}
                    >
                      <img
                        src={selectedBox.image_url}
                        alt={selectedBox.name}
                        referrerPolicy="no-referrer"
                        className="w-full h-full object-contain p-2 bg-black"
                      />
                    </div>
                  </div>

                  <h2 className="text-2xl md:text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 via-pink-400 to-purple-400 mt-10 tracking-widest uppercase animate-pulse">
                    {pullStage === "charging" ? "ENERGIYA YIG'ILMOQDA..." : "QUTI OCHILMOQDA... ⚡"}
                  </h2>
                </div>
              )}

              {/* STAGE 2: SUPER EXPLOSION SHOCKWAVE */}
              {pullStage === "exploding" && (
                <div className="flex flex-col items-center justify-center min-h-[350px]">
                  <div className="w-64 h-64 rounded-full bg-gradient-to-r from-yellow-400 via-red-500 to-purple-600 animate-ping flex items-center justify-center shadow-[0_0_100px_#f59e0b]">
                    <Sparkles className="w-24 h-24 text-white animate-spin" />
                  </div>
                  <h2 className="text-3xl font-black text-white mt-8 tracking-widest uppercase">
                    PORTLASH! ✨
                  </h2>
                </div>
              )}

              {/* STAGE 3: REVEALED CARDS */}
              {pullStage === "revealed" && (
                <div>
                  <h2 className="text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 via-pink-400 to-purple-400 mb-6 tracking-wide">
                    MUVAFFAQIYATLI OCHILDI! 🎉
                  </h2>

                  <div className="flex flex-wrap justify-center gap-4 max-h-[60vh] overflow-y-auto p-2">
                    {pulledCards.map((card, idx) => (
                      <div key={idx} className="animate-fade-in">
                        <GachaCard card={card} size="sm" showActions={false} />
                      </div>
                    ))}
                  </div>

                  <div className="mt-8 flex items-center justify-center gap-4">
                    <button
                      onClick={() => handlePullBox(selectedBox, pulledCards.length as any)}
                      className="px-6 py-3 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-black text-sm shadow-xl transition flex items-center gap-2"
                    >
                      <RotateCcw className="w-4 h-4" />
                      <span>Yana Ochish ({selectedBox.price_coins * pulledCards.length} 🪙)</span>
                    </button>
                    <button
                      onClick={() => {
                        setIsPulling(false);
                        setActiveTab("inventory");
                      }}
                      className="px-6 py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-sm transition"
                    >
                      Kolleksiyaga O'tish
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* PVP ARENA BATTLE DUEL MODAL */}
        {showBattleModal && (
          <div className="fixed inset-0 z-50 bg-black/95 backdrop-blur-2xl flex items-center justify-center p-4">
            <div className="bg-slate-900 border-2 border-purple-500/40 rounded-2xl p-6 max-w-2xl w-full shadow-2xl">
              <div className="flex items-center justify-between pb-4 border-b border-white/10 mb-6">
                <div className="flex items-center gap-2">
                  <Swords className="w-6 h-6 text-red-500" />
                  <h3 className="text-xl font-black text-white uppercase tracking-wider">
                    Jangiy Otryadlar Duel Arenasi
                  </h3>
                </div>
                <button
                  onClick={() => setShowBattleModal(false)}
                  className="p-1.5 rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* HEALTH BARS */}
              <div className="grid grid-cols-2 gap-6 mb-6">
                {/* Player Squad */}
                <div className="bg-black/50 p-4 rounded-xl border border-emerald-500/40">
                  <span className="text-xs font-bold text-emerald-400 block mb-1">Mening Squadim (⚡ {squadCombatPower.toLocaleString()})</span>
                  <div className="w-full h-4 bg-gray-800 rounded-full overflow-hidden border border-white/20">
                    <div
                      className="h-full bg-emerald-500 transition-all duration-500"
                      style={{ width: `${playerHp}%` }}
                    />
                  </div>
                  <span className="text-[11px] text-gray-400 mt-1 block">{playerHp} / 100 HP</span>
                </div>

                {/* Opponent Squad */}
                <div className="bg-black/50 p-4 rounded-xl border border-red-500/40">
                  <span className="text-xs font-bold text-red-400 block mb-1">Demon Monarch Squad (⚡ 83,391)</span>
                  <div className="w-full h-4 bg-gray-800 rounded-full overflow-hidden border border-white/20">
                    <div
                      className="h-full bg-red-500 transition-all duration-500"
                      style={{ width: `${opponentHp}%` }}
                    />
                  </div>
                  <span className="text-[11px] text-gray-400 mt-1 block">{opponentHp} / 100 HP</span>
                </div>
              </div>

              {/* BATTLE LOG DISPLAY */}
              <div className="bg-black/70 rounded-xl p-4 h-40 overflow-y-auto border border-white/10 font-mono text-xs space-y-2 mb-6">
                {battleLog.map((log, idx) => (
                  <p key={idx} className="text-purple-300">{log}</p>
                ))}
              </div>

              {/* BATTLE OUTCOME RESULT */}
              {battleStage === "won" && (
                <div className="p-4 rounded-xl bg-emerald-950/80 border border-emerald-500/50 text-center text-emerald-200 font-bold mb-4">
                  🏆 G'ALABA! Otryadingiz dushmanni mag'lub etdi! Mukofot: +500 🪙
                </div>
              )}
              {battleStage === "lost" && (
                <div className="p-4 rounded-xl bg-red-950/80 border border-red-500/50 text-center text-red-200 font-bold mb-4">
                  ☠️ MAG'LUBIYAT! Otryad kuchi yetmadi. Kartalaringizni rivojlantiring!
                </div>
              )}

              <div className="flex justify-end">
                <button
                  onClick={() => setShowBattleModal(false)}
                  className="px-6 py-2.5 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-bold text-xs"
                >
                  Yopish
                </button>
              </div>
            </div>
          </div>
        )}

        {/* SELL CARD MODAL */}
        {sellModalCard && (
          <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
            <div className="bg-slate-900 border border-white/10 rounded-2xl p-6 max-w-sm w-full shadow-2xl">
              <h3 className="text-lg font-bold text-white mb-2">Kartani Sotuvga Qo'yish</h3>
              <p className="text-xs text-gray-400 mb-4">{sellModalCard.name} ({sellModalCard.rarity}) kartangiz uchun narx belgilang:</p>

              <div className="mb-4">
                <label className="text-xs text-gray-400 block mb-1">Narx (Tangalarda):</label>
                <div className="relative">
                  <span className="absolute left-3 top-2.5 text-yellow-400">🪙</span>
                  <input
                    type="number"
                    value={sellPriceInput}
                    onChange={(e) => setSellPriceInput(e.target.value)}
                    className="w-full bg-black/60 border border-white/10 rounded-xl pl-8 pr-4 py-2 text-sm text-white font-bold"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={handleConfirmSell}
                  className="flex-1 py-2.5 rounded-xl bg-amber-500 text-black font-bold text-xs"
                >
                  Tasdiqlash & Sotuvga Qo'yish
                </button>
                <button
                  onClick={() => setSellModalCard(null)}
                  className="px-4 py-2.5 rounded-xl bg-gray-800 text-gray-300 font-bold text-xs"
                >
                  Bekor qilish
                </button>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
