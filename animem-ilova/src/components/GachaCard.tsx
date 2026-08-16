import React, { useState } from "react";
import { Sparkles, Heart, Zap, Award, Flame, Shield, ShoppingCart, Star, Swords, Check } from "lucide-react";
import { VideoMedia, isVideoUrl } from "./VideoMedia";

export interface CardData {
  user_card_id?: number;
  id: number;
  name: string;
  anime: string;
  type: "waifu" | "husbando";
  rarity: "C" | "R" | "SR" | "UR" | "SSR";
  power: number;
  image_url: string;
  description?: string;
  serial_number?: number;
  is_favorite?: boolean;
  market_status?: "none" | "selling" | "trading";
  price_coins?: number;
  seller_name?: string;
  in_squad?: boolean;
}

interface GachaCardProps {
  card: CardData;
  onFavoriteToggle?: (userCardId: number) => void;
  onSellClick?: (card: CardData) => void;
  onBuyClick?: (card: CardData) => void;
  onToggleSquad?: (card: CardData) => void;
  onClick?: (card: CardData) => void;
  size?: "sm" | "md" | "lg";
  showActions?: boolean;
}

export const GachaCard: React.FC<GachaCardProps> = ({
  card,
  onFavoriteToggle,
  onSellClick,
  onBuyClick,
  onToggleSquad,
  onClick,
  size = "md",
  showActions = true,
}) => {
  const [rotate, setRotate] = useState({ x: 0, y: 0 });
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;

    const rotateX = -((y - centerY) / centerY) * 14;
    const rotateY = ((x - centerX) / centerX) * 14;

    setRotate({ x: rotateX, y: rotateY });
  };

  const handleMouseLeave = () => {
    setRotate({ x: 0, y: 0 });
    setIsHovered(false);
  };

  // Rarity Configuration: Stars, Frame Borders, Badge Gradients & Stat Boosts
  const rarityConfig = {
    C: {
      stars: 1,
      starText: "★1",
      plusBadge: "+10",
      plusColor: "bg-gray-800 text-gray-300 border-gray-600",
      border: "border-gray-600/60 bg-slate-900/90 shadow-gray-900/50",
      outerGlow: "hover:shadow-gray-500/20",
      innerFrame: "border-gray-500/30",
      headerBg: "from-gray-900 via-slate-900 to-black",
      nameColor: "text-gray-200",
      accent: "text-gray-400",
      shine: "from-white/5 to-transparent",
    },
    R: {
      stars: 2,
      starText: "★2",
      plusBadge: "+20",
      plusColor: "bg-blue-900/90 text-blue-200 border-blue-500/80",
      border: "border-blue-500/80 bg-slate-900/90 shadow-blue-500/20",
      outerGlow: "hover:shadow-[0_0_25px_rgba(59,130,246,0.4)]",
      innerFrame: "border-blue-400/40",
      headerBg: "from-blue-950 via-slate-900 to-black",
      nameColor: "text-blue-200",
      accent: "text-blue-400",
      shine: "from-blue-400/10 to-transparent",
    },
    SR: {
      stars: 3,
      starText: "★3",
      plusBadge: "+30",
      plusColor: "bg-purple-900/90 text-purple-200 border-purple-400",
      border: "border-purple-500/90 bg-slate-900/90 shadow-purple-500/30",
      outerGlow: "hover:shadow-[0_0_30px_rgba(168,85,247,0.5)]",
      innerFrame: "border-purple-400/50",
      headerBg: "from-purple-950 via-slate-900 to-black",
      nameColor: "text-purple-200",
      accent: "text-purple-300",
      shine: "from-purple-400/15 to-transparent",
    },
    UR: {
      stars: 4,
      starText: "★4",
      plusBadge: "+40",
      plusColor: "bg-gradient-to-r from-red-600 to-pink-600 text-white font-extrabold border-red-400 shadow-md",
      border: "border-amber-400 bg-slate-900/90 shadow-amber-500/40",
      outerGlow: "hover:shadow-[0_0_35px_rgba(245,158,11,0.6)]",
      innerFrame: "border-amber-300/60",
      headerBg: "from-amber-950 via-purple-950 to-black",
      nameColor: "text-amber-200",
      accent: "text-amber-400",
      shine: "from-amber-300/20 via-pink-500/10 to-transparent",
    },
    SSR: {
      stars: 5,
      starText: "★5",
      plusBadge: "+45",
      plusColor: "bg-gradient-to-r from-purple-600 via-pink-600 to-yellow-500 text-white font-black border-yellow-300 shadow-lg animate-pulse",
      border: "border-2 border-amber-300 bg-slate-950/95 shadow-red-500/50",
      outerGlow: "hover:shadow-[0_0_45px_rgba(239,68,68,0.7)]",
      innerFrame: "border-amber-300/80 shadow-[inset_0_0_15px_rgba(245,158,11,0.3)]",
      headerBg: "from-red-950 via-purple-950 to-black",
      nameColor: "text-yellow-300",
      accent: "text-red-400",
      shine: "from-pink-500/30 via-yellow-400/20 to-purple-600/30",
    },
  };

  const style = rarityConfig[card.rarity] || rarityConfig.C;

  const sizeClasses = {
    sm: "w-44 h-72 text-xs",
    md: "w-56 h-[23rem] text-sm",
    lg: "w-64 h-[26rem] text-base",
  };

  return (
    <div
      onClick={() => onClick && onClick(card)}
      onMouseMove={handleMouseMove}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={handleMouseLeave}
      style={{
        transform: `perspective(1000px) rotateX(${rotate.x}deg) rotateY(${rotate.y}deg) scale3d(${isHovered ? 1.05 : 1}, ${isHovered ? 1.05 : 1}, 1)`,
        transition: isHovered ? "transform 0.08s ease-out" : "transform 0.4s ease-out",
      }}
      className={`relative rounded-xl border-2 overflow-hidden flex flex-col justify-between shadow-2xl cursor-pointer transition-all duration-300 select-none ${style.border} ${style.outerGlow} ${sizeClasses[size]}`}
    >
      {/* Holographic Sheen Filter Overlay */}
      <div
        className={`absolute inset-0 bg-gradient-to-tr ${style.shine} pointer-events-none z-10 opacity-70 transition-opacity duration-300 ${
          isHovered ? "opacity-100" : ""
        }`}
      />

      {/* SSR Sparkles & Frame Corner Jewels */}
      {card.rarity === "SSR" && (
        <>
          <div className="absolute top-1 left-1 w-2 h-2 rounded-full bg-yellow-300 shadow-[0_0_8px_#fde047] z-30" />
          <div className="absolute top-1 right-1 w-2 h-2 rounded-full bg-yellow-300 shadow-[0_0_8px_#fde047] z-30" />
          <div className="absolute bottom-1 left-1 w-2 h-2 rounded-full bg-red-400 shadow-[0_0_8px_#f87171] z-30" />
          <div className="absolute bottom-1 right-1 w-2 h-2 rounded-full bg-red-400 shadow-[0_0_8px_#f87171] z-30" />
        </>
      )}

      {/* TOP HEADER BAR: Star Rating Badge (Left) & Power Enhancement Tag (Right) */}
      <div className={`p-2 bg-gradient-to-b ${style.headerBg} flex items-center justify-between border-b border-white/10 z-20`}>
        {/* Star Badge (e.g., ★5, ★4) */}
        <div className="flex items-center gap-1 bg-black/80 border border-white/20 px-2 py-0.5 rounded-md shadow">
          <Star className={`w-3.5 h-3.5 fill-current ${card.rarity === "SSR" ? "text-yellow-400" : card.rarity === "UR" ? "text-amber-400" : "text-purple-400"}`} />
          <span className="font-extrabold text-xs text-white tracking-wider">{style.starText}</span>
        </div>

        {/* Right Badges: Squad Indicator + Stat Boost Tag */}
        <div className="flex items-center gap-1.5">
          {card.in_squad && (
            <span className="px-1.5 py-0.5 rounded bg-emerald-500 text-black font-black text-[10px] uppercase tracking-tighter flex items-center gap-0.5 shadow">
              <Check className="w-3 h-3 stroke-[3]" /> SQUAD
            </span>
          )}

          {/* Stat Boost Tag (e.g. +45, +40) */}
          <span className={`px-2 py-0.5 rounded-md text-xs font-black border ${style.plusColor}`}>
            {style.plusBadge}
          </span>
        </div>
      </div>

      {/* MAIN ARTWORK CONTAINER */}
      <div className="relative flex-1 w-full overflow-hidden bg-black/90 group">
        {isVideoUrl((card as any).video_url || card.image_url) ? (
          <VideoMedia
            src={(card as any).video_url || card.image_url}
            autoPlay
            loop
            muted
            playsInline
            className="w-full h-full object-cover object-top transition-transform duration-700 group-hover:scale-110 brightness-[1.08] contrast-[1.05]"
          />
        ) : (
          <img
            src={card.image_url}
            alt={card.name}
            referrerPolicy="no-referrer"
            className="w-full h-full object-cover object-top transition-transform duration-700 group-hover:scale-110 brightness-[1.05] contrast-[1.02]"
            loading="lazy"
          />
        )}

        {/* Clear overlay with subtle gradient only at the very bottom for name legibility */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent z-10 pointer-events-none" />

        {/* Favorite Heart Button */}
        {card.user_card_id && onFavoriteToggle && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              onFavoriteToggle(card.user_card_id!);
            }}
            className="absolute top-2 right-2 p-1.5 rounded-full bg-black/60 hover:bg-black/80 border border-white/20 text-red-400 transition z-20 backdrop-blur"
            title="Saralanganlarga qo'shish"
          >
            <Heart className={`w-3.5 h-3.5 ${card.is_favorite ? "fill-red-500 text-red-500" : "text-gray-300"}`} />
          </button>
        )}

        {/* Serial Number Badge (e.g. #001) */}
        {card.serial_number && (
          <div className="absolute top-2 left-2 bg-black/80 backdrop-blur border border-yellow-500/40 text-yellow-400 text-[10px] px-1.5 py-0.5 rounded font-mono font-black z-20">
            #{String(card.serial_number).padStart(3, "0")}
          </div>
        )}

        {/* STYLIZED CHARACTER NAME BANNER OVER ARTWORK */}
        <div className="absolute bottom-2 left-0 right-0 px-2 text-center z-20">
          <span className="inline-block px-3 py-0.5 rounded-lg bg-black/80 backdrop-blur border border-white/20 text-white font-black tracking-wide text-xs sm:text-sm drop-shadow-[0_2px_4px_rgba(0,0,0,0.9)] italic transform -skew-x-6">
            {card.name}
          </span>
        </div>
      </div>

      {/* CARD DETAILS & POWER STAT PANEL */}
      <div className={`p-2.5 bg-slate-950/95 border-t ${style.innerFrame} flex flex-col justify-between z-20`}>
        <div className="flex items-center justify-between text-xs">
          <span className="text-[11px] text-gray-400 font-medium truncate max-w-[110px]">{card.anime}</span>
          {/* Power Level Display */}
          <span className="font-extrabold text-amber-300 flex items-center gap-1 bg-amber-950/80 border border-amber-500/40 px-1.5 py-0.5 rounded text-[11px]">
            <Zap className="w-3 h-3 text-yellow-400 fill-current" />
            {card.power.toLocaleString()}
          </span>
        </div>

        {/* Market seller price if listed */}
        {card.price_coins !== undefined && (
          <div className="mt-1.5 flex items-center justify-between text-xs bg-amber-950/60 border border-amber-500/30 px-2 py-0.5 rounded">
            <span className="text-gray-400 text-[10px]">{card.seller_name || "Sotuvchi"}</span>
            <span className="font-black text-yellow-400 flex items-center gap-0.5 text-xs">
              🪙 {card.price_coins.toLocaleString()}
            </span>
          </div>
        )}

        {/* ACTION BUTTONS */}
        {showActions && (
          <div className="mt-2 flex items-center gap-1.5">
            {onToggleSquad && card.user_card_id && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onToggleSquad(card);
                }}
                className={`flex-1 py-1 rounded-lg text-xs font-bold flex items-center justify-center gap-1 transition ${
                  card.in_squad
                    ? "bg-emerald-600 hover:bg-emerald-500 text-white"
                    : "bg-slate-800 hover:bg-slate-700 text-gray-200 border border-white/10"
                }`}
              >
                <Swords className="w-3 h-3" />
                <span>{card.in_squad ? "Squadda" : "+ Squad"}</span>
              </button>
            )}

            {onBuyClick && card.price_coins !== undefined && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onBuyClick(card);
                }}
                className="w-full py-1.5 rounded-lg bg-gradient-to-r from-amber-500 to-yellow-600 hover:from-amber-400 hover:to-yellow-500 text-black font-extrabold text-xs flex items-center justify-center gap-1 shadow-md transition"
              >
                <ShoppingCart className="w-3.5 h-3.5" />
                <span>Xarid qilish</span>
              </button>
            )}

            {onSellClick && card.market_status === "none" && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onSellClick(card);
                }}
                className="py-1 px-2 rounded-lg bg-purple-900/80 hover:bg-purple-800 text-purple-200 border border-purple-500/40 font-bold text-xs flex items-center justify-center gap-1 transition"
                title="Bozorga sotish"
              >
                <ShoppingCart className="w-3 h-3" />
                <span>Sotish</span>
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
