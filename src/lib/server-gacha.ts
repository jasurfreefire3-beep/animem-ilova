import { Express } from "express";
import mysql from "mysql2/promise";

export async function initGachaDb(pool: mysql.Pool) {
  try {
    const connection = await pool.getConnection();
    try {
      // 1. Alter Users table to ensure coins and daily claim columns exist
      const [userCols]: any = await connection.query(`
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'users' 
          AND TABLE_SCHEMA = DATABASE()
      `);
      const colNames = userCols.map((c: any) => c.COLUMN_NAME);

      if (!colNames.includes("coins")) {
        await connection.query("ALTER TABLE users ADD COLUMN coins INT DEFAULT 1000");
      }

      if (!colNames.includes("last_daily_claim")) {
        await connection.query("ALTER TABLE users ADD COLUMN last_daily_claim TIMESTAMP NULL DEFAULT NULL");
      }

      // 2. Create gacha_cards table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS gacha_cards (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          anime VARCHAR(255) NOT NULL,
          type ENUM('waifu', 'husbando') NOT NULL DEFAULT 'waifu',
          rarity ENUM('C', 'R', 'SR', 'UR', 'SSR') NOT NULL DEFAULT 'C',
          power INT NOT NULL DEFAULT 100,
          image_url TEXT NOT NULL,
          description TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // 3. Create gacha_boxes table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS gacha_boxes (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          price_coins INT NOT NULL DEFAULT 200,
          image_url TEXT NOT NULL,
          description TEXT,
          type_filter VARCHAR(50) DEFAULT 'all',
          is_active TINYINT(1) DEFAULT 1,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // 4. Create user_cards table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS user_cards (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          card_id INT NOT NULL,
          obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          serial_number INT NOT NULL DEFAULT 1,
          is_favorite TINYINT(1) DEFAULT 0,
          market_status ENUM('none', 'selling', 'trading') DEFAULT 'none',
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (card_id) REFERENCES gacha_cards(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // 5. Create gacha_market table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS gacha_market (
          id INT AUTO_INCREMENT PRIMARY KEY,
          seller_id INT NOT NULL,
          user_card_id INT NOT NULL,
          price_coins INT NOT NULL,
          status ENUM('active', 'sold', 'cancelled') DEFAULT 'active',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (user_card_id) REFERENCES user_cards(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // 6. Create gacha_trades table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS gacha_trades (
          id INT AUTO_INCREMENT PRIMARY KEY,
          sender_id INT NOT NULL,
          receiver_id INT NOT NULL,
          sender_card_ids TEXT NOT NULL,
          receiver_card_ids TEXT NOT NULL,
          sender_coins INT DEFAULT 0,
          receiver_coins INT DEFAULT 0,
          status ENUM('pending', 'accepted', 'rejected', 'cancelled') DEFAULT 'pending',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // 7. Create gacha_logs table
      await connection.query(`
        CREATE TABLE IF NOT EXISTS gacha_logs (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          action VARCHAR(50) NOT NULL,
          details TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      `);

      // Seed Cards if empty
      const [existingCards]: any = await connection.query("SELECT COUNT(*) as count FROM gacha_cards");
      if (existingCards[0].count === 0) {
        const sampleCards = [
          ["Nezuko Kamado", "Demon Slayer", "waifu", "SSR", 25000, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Demon Slayer-ning eng sevimli iblis singlisi!"],
          ["Gojo Satoru", "Jujutsu Kaisen", "husbando", "SSR", 28000, "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop", "Cheksizlik texnikasi egasi, eng kuchli shaman!"],
          ["Mikasa Ackerman", "Attack on Titan", "waifu", "SSR", 24000, "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop", "Ackerman urug'ining eng kuchli jangchisi!"],
          ["Roronoa Zoro", "One Piece", "husbando", "SSR", 26000, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "3 qilich ustasi, Samuraylar qiroli!"],
          ["Makima", "Chainsaw Man", "waifu", "SSR", 27000, "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop", "Boshqaruv Iblisi, sirli va xavfli guzal!"],
          ["Yor Forger", "Spy x Family", "waifu", "UR", 7000, "https://images.unsplash.com/photo-1541562232579-512a21360020?w=600&auto=format&fit=crop", "Tikanli qirolicha va mehribon ona!"],
          ["Levi Ackerman", "Attack on Titan", "husbando", "UR", 7500, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "Insoniyatning eng kuchli kapitani!"],
          ["Marin Kitagawa", "My Dress-Up Darling", "waifu", "UR", 6500, "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop", "Cosplay va moda qirolichasi!"],
          ["Megumi Fushiguro", "Jujutsu Kaisen", "husbando", "UR", 6800, "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop", "O'n soyalar texnikasi egasi!"],
          ["Zero Two", "Darling in the Franxx", "waifu", "UR", 7200, "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop", "Qizil shoxli afsonaviy pilot!"],
          ["Ryomen Sukuna", "Jujutsu Kaisen", "husbando", "UR", 7400, "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop", "La'natlar Qiroli!"],
          ["Rem", "Re:Zero", "waifu", "SR", 2200, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "Moviy sochli sodiq iblis xizmatchi!"],
          ["Tanjiro Kamado", "Demon Slayer", "husbando", "SR", 2100, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Kuyosh nafasi ustasi!"],
          ["Anya Forger", "Spy x Family", "waifu", "SR", 1800, "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop", "Fikr o'quvchi shirin qizaloq! Waku Waku!"],
          ["Kageyama Tobio", "Haikyuu!!", "husbando", "SR", 1900, "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop", "Maydon Qiroli, dahshatli bog'lovchi!"],
          ["Shinobu Kocho", "Demon Slayer", "waifu", "SR", 2300, "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop", "Kapalak Hashirasi va zahar ustasi!"],
          ["Zenitsu Agatsuma", "Demon Slayer", "husbando", "R", 750, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Maltillash nafasi, uxlaganda daxshat!"],
          ["Nobara Kugisaki", "Jujutsu Kaisen", "waifu", "R", 720, "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop", "Mux va bolg'a shamani!"],
          ["Megumin", "Konosuba", "waifu", "R", 800, "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop", "EXPLOSION sehri ustasi!"],
          ["Inosuke Hashibira", "Demon Slayer", "husbando", "R", 780, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "To'ng'iz niqobli yirtqich jangchi!"],
          ["Izuku Midoriya", "My Hero Academia", "husbando", "C", 250, "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop", "One For All vorisi!"],
          ["Ochako Uraraka", "My Hero Academia", "waifu", "C", 220, "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop", "Nol tortishish kuchi ustasi!"],
          ["Saitama", "One Punch Man", "husbando", "C", 300, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "Bir zarba bilan mag'lub etuvchi Qahramon!"],
          ["Hinata Hyuga", "Naruto", "waifu", "C", 290, "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop", "Byakugan ko'zi egasi, Hyuga malikasi!"]
        ];

        for (const card of sampleCards) {
          await connection.query(
            "INSERT INTO gacha_cards (name, anime, type, rarity, power, image_url, description) VALUES (?, ?, ?, ?, ?, ?, ?)",
            card
          );
        }
      }

      // Seed Boxes if empty
      const [existingBoxes]: any = await connection.query("SELECT COUNT(*) as count FROM gacha_boxes");
      if (existingBoxes[0].count === 0) {
        const sampleBoxes = [
          [
            "Standart Anime Qutisi",
            200,
            "https://images.unsplash.com/photo-1513151233558-d860c5398176?w=600&auto=format&fit=crop",
            "Hamma noyoblikdagi anime waifu va husbandolar tushishi mumkin bo'lgan standart quti! (C: 50%, R: 30%, SR: 14%, UR: 5%, SSR: 1%)",
            "all"
          ],
          [
            "VIP Waifu Qutisi",
            500,
            "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop",
            "Faqat go'zal anime Waifular tushadigan maxsus VIP quti!",
            "waifu"
          ],
          [
            "VIP Husbando Qutisi",
            500,
            "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop",
            "Faqat eng kuchli Husbandolar tushadigan maxsus VIP quti!",
            "husbando"
          ],
          [
            "Legendary SSR Chest",
            1500,
            "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop",
            "Kafolatlangan kamida SR, UR yoki afsonaviy SSR karta tushadigan xazina qutisi!",
            "all"
          ]
        ];

        for (const box of sampleBoxes) {
          await connection.query(
            "INSERT INTO gacha_boxes (name, price_coins, image_url, description, type_filter) VALUES (?, ?, ?, ?, ?)",
            box
          );
        }
      }

      console.log("Verified Gacha DB tables & initial seed data.");
    } finally {
      connection.release();
    }
  } catch (err) {
    console.error("Gacha DB Init Warning:", err);
  }
}

export function registerGachaRoutes(app: Express, authenticateToken: any, dbQuery: any, pool: mysql.Pool) {
  // 1. Get Gacha Boxes
  app.get("/api/gacha/boxes", async (req, res) => {
    try {
      const [boxes]: any = await dbQuery("SELECT * FROM gacha_boxes WHERE is_active = 1 ORDER BY price_coins ASC");
      
      // Return boxes with custom image_url or fallback if empty
      const mappedBoxes = boxes.map((box: any) => {
        let chestImage = box.image_url;
        if (!chestImage) {
          if (box.name.includes("Standart") || box.price_coins <= 200) {
            chestImage = "/src/assets/images/gacha_chest_bronze_1786413031809.jpg";
          } else if (box.type_filter === "waifu") {
            chestImage = "/src/assets/images/gacha_chest_silver_1786413048657.jpg";
          } else if (box.type_filter === "husbando") {
            chestImage = "/src/assets/images/gacha_chest_gold_1786413066377.jpg";
          } else if (box.price_coins >= 1000 || box.name.includes("Legendary")) {
            chestImage = "/src/assets/images/gacha_chest_legendary_1786413082029.jpg";
          }
        }
        return { ...box, image_url: chestImage };
      });

      res.json(mappedBoxes);
    } catch (err: any) {
      res.status(500).json({ error: "Qutilarni yuklashda xatolik" });
    }
  });

  // 2. Get User Coins & Daily Status
  app.get("/api/gacha/coins", authenticateToken, async (req: any, res) => {
    try {
      const [users]: any = await dbQuery("SELECT coins, last_daily_claim FROM users WHERE id = ?", [req.user.id]);
      const user = users[0];
      if (!user) return res.status(404).json({ error: "Foydalanuvchi topilmadi" });

      const lastClaim = user.last_daily_claim ? new Date(user.last_daily_claim).getTime() : 0;
      const now = Date.now();
      const canClaimDaily = now - lastClaim >= 24 * 60 * 60 * 1000;
      const nextClaimInMs = canClaimDaily ? 0 : 24 * 60 * 60 * 1000 - (now - lastClaim);

      res.json({
        coins: user.coins || 0,
        canClaimDaily,
        nextClaimInMs
      });
    } catch (err: any) {
      res.status(500).json({ error: "Tanga balansi olishda xatolik" });
    }
  });

  // 3. Claim Daily Coins
  app.post("/api/gacha/daily-claim", authenticateToken, async (req: any, res) => {
    try {
      const [users]: any = await dbQuery("SELECT coins, last_daily_claim FROM users WHERE id = ?", [req.user.id]);
      const user = users[0];
      if (!user) return res.status(404).json({ error: "Foydalanuvchi topilmadi" });

      const lastClaim = user.last_daily_claim ? new Date(user.last_daily_claim).getTime() : 0;
      const now = Date.now();
      if (now - lastClaim < 24 * 60 * 60 * 1000) {
        return res.status(400).json({ error: "Kunlik bonusni faqat har 24 soatda bir marta olishingiz mumkin!" });
      }

      const rewardAmount = 1000;
      await dbQuery("UPDATE users SET coins = COALESCE(coins, 0) + ?, last_daily_claim = NOW() WHERE id = ?", [
        rewardAmount,
        req.user.id
      ]);

      await dbQuery("INSERT INTO gacha_logs (user_id, action, details) VALUES (?, 'daily_claim', ?)", [
        req.user.id,
        `Claimed ${rewardAmount} daily coins`
      ]);

      res.json({ success: true, reward: rewardAmount, newCoins: (user.coins || 0) + rewardAmount });
    } catch (err: any) {
      res.status(500).json({ error: "Kunlik bonusni olishda xatolik" });
    }
  });

  // 4. Pull Gacha Box (1x or 10x) with Weighted Probability Algorithm in MySQL Transaction
  app.post("/api/gacha/pull", authenticateToken, async (req: any, res) => {
    const { box_id, count = 1 } = req.body;
    const pullCount = count === 10 ? 10 : 1;

    let connection: mysql.PoolConnection | null = null;
    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();

      // Check Box
      const [boxes]: any = await connection.query("SELECT * FROM gacha_boxes WHERE id = ? AND is_active = 1", [box_id]);
      const box = boxes[0];
      if (!box) {
        await connection.rollback();
        return res.status(404).json({ error: "Quti topilmadi yoki nofaol!" });
      }

      const totalCost = box.price_coins * pullCount;

      // Lock User Row & Check Coins
      const [users]: any = await connection.query("SELECT coins FROM users WHERE id = ? FOR UPDATE", [req.user.id]);
      const user = users[0];
      if (!user || (user.coins || 0) < totalCost) {
        await connection.rollback();
        return res.status(400).json({ error: `Tanga mablag'i yetarli emas! Sizga ${totalCost} tanga kerak.` });
      }

      // Deduct Coins
      await connection.query("UPDATE users SET coins = coins - ? WHERE id = ?", [totalCost, req.user.id]);

      // Fetch all candidate cards
      let filterSql = "";
      const filterParams: any[] = [];
      if (box.type_filter && box.type_filter !== "all") {
        filterSql = " AND type = ?";
        filterParams.push(box.type_filter);
      }

      const [allCards]: any = await connection.query(`SELECT * FROM gacha_cards WHERE 1=1 ${filterSql}`, filterParams);
      if (allCards.length === 0) {
        await connection.rollback();
        return res.status(400).json({ error: "Tizimda kartalar topilmadi!" });
      }

      const pulledResults: any[] = [];

      for (let i = 0; i < pullCount; i++) {
        // Roll rarity
        let targetRarity = "C";
        const roll = Math.floor(Math.random() * 1000) + 1; // 1 to 1000

        if (box.name.includes("SSR") || box.price_coins >= 1500) {
          // SSR Chest rates: SSR 10%, UR 30%, SR 60%
          if (roll <= 100) targetRarity = "SSR";
          else if (roll <= 400) targetRarity = "UR";
          else targetRarity = "SR";
        } else {
          // Standard rates: SSR 1% (1..10), UR 5% (11..60), SR 14% (61..200), R 30% (201..500), C 50% (501..1000)
          if (roll <= 10) targetRarity = "SSR";
          else if (roll <= 60) targetRarity = "UR";
          else if (roll <= 200) targetRarity = "SR";
          else if (roll <= 500) targetRarity = "R";
          else targetRarity = "C";
        }

        // Filter cards matching targetRarity
        let candidates = allCards.filter((c: any) => c.rarity === targetRarity);
        if (candidates.length === 0) {
          // Fallback if no cards of target rarity
          candidates = allCards;
        }

        const chosenCard = candidates[Math.floor(Math.random() * candidates.length)];

        // Get card serial number
        const [serials]: any = await connection.query(
          "SELECT COUNT(*) as cnt FROM user_cards WHERE card_id = ?",
          [chosenCard.id]
        );
        const serialNum = (serials[0]?.cnt || 0) + 1;

        // Insert into user_cards
        const [insertRes]: any = await connection.query(
          "INSERT INTO user_cards (user_id, card_id, serial_number) VALUES (?, ?, ?)",
          [req.user.id, chosenCard.id, serialNum]
        );

        pulledResults.push({
          user_card_id: insertRes.insertId,
          id: chosenCard.id,
          name: chosenCard.name,
          anime: chosenCard.anime,
          type: chosenCard.type,
          rarity: chosenCard.rarity,
          power: chosenCard.power,
          image_url: chosenCard.image_url,
          description: chosenCard.description,
          serial_number: serialNum
        });
      }

      // Log action
      await connection.query(
        "INSERT INTO gacha_logs (user_id, action, details) VALUES (?, 'pull', ?)",
        [req.user.id, `Pulled ${pullCount}x from box '${box.name}' for ${totalCost} coins`]
      );

      await connection.commit();

      res.json({
        success: true,
        cards: pulledResults,
        remainingCoins: user.coins - totalCost
      });
    } catch (err: any) {
      if (connection) await connection.rollback();
      console.error("Gacha pull error:", err);
      res.status(500).json({ error: "Qutini ochishda xatolik yuz berdi" });
    } finally {
      if (connection) connection.release();
    }
  });

  // 5. Get User Card Inventory / Collection
  app.get("/api/gacha/inventory", authenticateToken, async (req: any, res) => {
    try {
      const userId = req.query.user_id ? Number(req.query.user_id) : req.user.id;
      const { rarity, type, search } = req.query;

      let sql = `
        SELECT uc.id as user_card_id, uc.serial_number, uc.is_favorite, uc.market_status, uc.obtained_at,
               gc.id as card_id, gc.name, gc.anime, gc.type, gc.rarity, gc.power, gc.image_url, gc.description
        FROM user_cards uc
        JOIN gacha_cards gc ON uc.card_id = gc.id
        WHERE uc.user_id = ?
      `;
      const params: any[] = [userId];

      if (rarity && rarity !== "ALL") {
        sql += " AND gc.rarity = ?";
        params.push(rarity);
      }
      if (type && type !== "ALL") {
        sql += " AND gc.type = ?";
        params.push(type);
      }
      if (search) {
        sql += " AND (gc.name LIKE ? OR gc.anime LIKE ?)";
        params.push(`%${search}%`, `%${search}%`);
      }

      sql += " ORDER BY FIELD(gc.rarity, 'SSR', 'UR', 'SR', 'R', 'C'), gc.power DESC, uc.obtained_at DESC";

      const [cards]: any = await dbQuery(sql, params);

      // Calculate total stats
      const totalPower = cards.reduce((acc: number, c: any) => acc + (c.power || 0), 0);

      res.json({
        cards,
        totalCards: cards.length,
        totalPower
      });
    } catch (err: any) {
      res.status(500).json({ error: "Kolleksiyani yuklashda xatolik" });
    }
  });

  // 6. Toggle Favorite Card
  app.post("/api/gacha/favorite", authenticateToken, async (req: any, res) => {
    try {
      const { user_card_id } = req.body;
      const [cards]: any = await dbQuery("SELECT is_favorite FROM user_cards WHERE id = ? AND user_id = ?", [
        user_card_id,
        req.user.id
      ]);
      if (cards.length === 0) return res.status(404).json({ error: "Karta topilmadi" });

      const newFav = cards[0].is_favorite ? 0 : 1;
      await dbQuery("UPDATE user_cards SET is_favorite = ? WHERE id = ?", [newFav, user_card_id]);

      res.json({ success: true, is_favorite: newFav });
    } catch (err: any) {
      res.status(500).json({ error: "Sevimlilarga qo'shishda xatolik" });
    }
  });

  // 7. Get All Game Cards Catalog
  app.get("/api/gacha/cards", async (req, res) => {
    try {
      const [cards]: any = await dbQuery(`
        SELECT gc.*, COUNT(uc.id) as total_collected
        FROM gacha_cards gc
        LEFT JOIN user_cards uc ON gc.id = uc.card_id
        GROUP BY gc.id
        ORDER BY FIELD(gc.rarity, 'SSR', 'UR', 'SR', 'R', 'C'), gc.power DESC
      `);
      res.json(cards);
    } catch (err: any) {
      res.status(500).json({ error: "Kartalarni yuklashda xatolik" });
    }
  });

  // 8. Market: List Active Card Items
  app.get("/api/gacha/market", async (req, res) => {
    try {
      const { rarity, type, search } = req.query;

      let sql = `
        SELECT gm.id as market_id, gm.price_coins, gm.created_at as listed_at,
               u.id as seller_id, u.name as seller_name, u.avatar_url as seller_avatar,
               uc.id as user_card_id, uc.serial_number,
               gc.id as card_id, gc.name, gc.anime, gc.type, gc.rarity, gc.power, gc.image_url, gc.description
        FROM gacha_market gm
        JOIN users u ON gm.seller_id = u.id
        JOIN user_cards uc ON gm.user_card_id = uc.id
        JOIN gacha_cards gc ON uc.card_id = gc.id
        WHERE gm.status = 'active'
      `;
      const params: any[] = [];

      if (rarity && rarity !== "ALL") {
        sql += " AND gc.rarity = ?";
        params.push(rarity);
      }
      if (type && type !== "ALL") {
        sql += " AND gc.type = ?";
        params.push(type);
      }
      if (search) {
        sql += " AND (gc.name LIKE ? OR gc.anime LIKE ? OR u.name LIKE ?)";
        params.push(`%${search}%`, `%${search}%`, `%${search}%`);
      }

      sql += " ORDER BY gm.created_at DESC";

      const [items]: any = await dbQuery(sql, params);
      res.json(items);
    } catch (err: any) {
      res.status(500).json({ error: "Bozorni yuklashda xatolik" });
    }
  });

  // 9. Market: Sell Card
  app.post("/api/gacha/market/sell", authenticateToken, async (req: any, res) => {
    const { user_card_id, price_coins } = req.body;
    const price = Number(price_coins);

    if (!price || price <= 0 || price > 1000000) {
      return res.status(400).json({ error: "To'g'ri narx kiriting (1 - 1,000,000 tanga)!" });
    }

    try {
      const [ucards]: any = await dbQuery(
        "SELECT * FROM user_cards WHERE id = ? AND user_id = ?",
        [user_card_id, req.user.id]
      );
      const card = ucards[0];
      if (!card) return res.status(404).json({ error: "Sizga tegishli bunday karta topilmadi!" });

      if (card.market_status !== "none") {
        return res.status(400).json({ error: "Bu karta allaqachon sotuvda yoki almashtirishda!" });
      }

      await dbQuery("UPDATE user_cards SET market_status = 'selling' WHERE id = ?", [user_card_id]);
      await dbQuery(
        "INSERT INTO gacha_market (seller_id, user_card_id, price_coins, status) VALUES (?, ?, ?, 'active')",
        [req.user.id, user_card_id, price]
      );

      res.json({ success: true });
    } catch (err: any) {
      res.status(500).json({ error: "Kartani sotuvga qo'yishda xatolik" });
    }
  });

  // 10. Market: Buy Card with Atomic Transaction
  app.post("/api/gacha/market/buy", authenticateToken, async (req: any, res) => {
    const { market_id } = req.body;

    let connection: mysql.PoolConnection | null = null;
    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();

      const [markets]: any = await connection.query(
        "SELECT * FROM gacha_market WHERE id = ? AND status = 'active' FOR UPDATE",
        [market_id]
      );
      const item = markets[0];
      if (!item) {
        await connection.rollback();
        return res.status(404).json({ error: "Bunday sotuv e'loni topilmadi yoki sotib bo'lingan!" });
      }

      if (item.seller_id === req.user.id) {
        await connection.rollback();
        return res.status(400).json({ error: "O'zingizning kartangizni sotib ololmaysiz!" });
      }

      const price = item.price_coins;

      // Check Buyer Coins
      const [buyers]: any = await connection.query("SELECT coins FROM users WHERE id = ? FOR UPDATE", [req.user.id]);
      const buyer = buyers[0];
      if (!buyer || (buyer.coins || 0) < price) {
        await connection.rollback();
        return res.status(400).json({ error: `Tangalaringiz yetarli emas! ${price} tanga kerak.` });
      }

      // 1. Deduct from buyer
      await connection.query("UPDATE users SET coins = coins - ? WHERE id = ?", [price, req.user.id]);
      // 2. Add to seller
      await connection.query("UPDATE users SET coins = COALESCE(coins, 0) + ? WHERE id = ?", [price, item.seller_id]);
      // 3. Transfer card ownership
      await connection.query("UPDATE user_cards SET user_id = ?, market_status = 'none' WHERE id = ?", [
        req.user.id,
        item.user_card_id
      ]);
      // 4. Update market status
      await connection.query("UPDATE gacha_market SET status = 'sold' WHERE id = ?", [market_id]);

      await connection.commit();

      res.json({ success: true, remainingCoins: buyer.coins - price });
    } catch (err: any) {
      if (connection) await connection.rollback();
      res.status(500).json({ error: "Kartani sotib olishda xatolik yuz berdi" });
    } finally {
      if (connection) connection.release();
    }
  });

  // 11. Market: Cancel Sale Listing
  app.post("/api/gacha/market/cancel", authenticateToken, async (req: any, res) => {
    const { market_id } = req.body;
    try {
      const [markets]: any = await dbQuery("SELECT * FROM gacha_market WHERE id = ? AND seller_id = ? AND status = 'active'", [
        market_id,
        req.user.id
      ]);
      const item = markets[0];
      if (!item) return res.status(404).json({ error: "E'lon topilmadi" });

      await dbQuery("UPDATE gacha_market SET status = 'cancelled' WHERE id = ?", [market_id]);
      await dbQuery("UPDATE user_cards SET market_status = 'none' WHERE id = ?", [item.user_card_id]);

      res.json({ success: true });
    } catch (err: any) {
      res.status(500).json({ error: "E'lonni bekor qilishda xatolik" });
    }
  });

  // 12. P2P Trades: List My Pending Trades
  app.get("/api/gacha/trades", authenticateToken, async (req: any, res) => {
    try {
      const [trades]: any = await dbQuery(
        `
        SELECT gt.*, 
               u_send.name as sender_name, u_send.avatar_url as sender_avatar,
               u_recv.name as receiver_name, u_recv.avatar_url as receiver_avatar
        FROM gacha_trades gt
        JOIN users u_send ON gt.sender_id = u_send.id
        JOIN users u_recv ON gt.receiver_id = u_recv.id
        WHERE (gt.sender_id = ? OR gt.receiver_id = ?)
        ORDER BY gt.created_at DESC
      `,
        [req.user.id, req.user.id]
      );

      res.json(trades);
    } catch (err: any) {
      res.status(500).json({ error: "Savdolarni yuklashda xatolik" });
    }
  });

  // 13. P2P Trades: Create Trade Offer
  app.post("/api/gacha/trade/create", authenticateToken, async (req: any, res) => {
    const { receiver_id, sender_card_ids = [], receiver_card_ids = [], sender_coins = 0, receiver_coins = 0 } = req.body;

    if (req.user.id === Number(receiver_id)) {
      return res.status(400).json({ error: "O'zingiz bilan savdo qila olmaysiz!" });
    }

    try {
      // Check sender cards ownership
      if (sender_card_ids.length > 0) {
        const [scards]: any = await dbQuery(
          "SELECT id FROM user_cards WHERE user_id = ? AND id IN (?) AND market_status = 'none'",
          [req.user.id, sender_card_ids]
        );
        if (scards.length !== sender_card_ids.length) {
          return res.status(400).json({ error: "Siz taklif qilgan ba'zi kartalar mavjud emas yoki sotuvda!" });
        }
      }

      await dbQuery(
        `INSERT INTO gacha_trades 
         (sender_id, receiver_id, sender_card_ids, receiver_card_ids, sender_coins, receiver_coins, status)
         VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
        [
          req.user.id,
          receiver_id,
          JSON.stringify(sender_card_ids),
          JSON.stringify(receiver_card_ids),
          sender_coins,
          receiver_coins
        ]
      );

      res.json({ success: true });
    } catch (err: any) {
      res.status(500).json({ error: "Savdo taklifini yuborishda xatolik" });
    }
  });

  // 14. P2P Trades: Accept / Reject / Cancel Trade Offer (Atomic Swap)
  app.post("/api/gacha/trade/respond", authenticateToken, async (req: any, res) => {
    const { trade_id, action } = req.body; // 'accept', 'reject', 'cancel'

    let connection: mysql.PoolConnection | null = null;
    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();

      const [trades]: any = await connection.query("SELECT * FROM gacha_trades WHERE id = ? FOR UPDATE", [trade_id]);
      const trade = trades[0];
      if (!trade || trade.status !== "pending") {
        await connection.rollback();
        return res.status(400).json({ error: "Taklif topilmadi yoki allaqachon yakunlangan!" });
      }

      if (action === "reject") {
        if (trade.receiver_id !== req.user.id && trade.sender_id !== req.user.id) {
          await connection.rollback();
          return res.status(403).json({ error: "Ruxsat yo'q!" });
        }
        await connection.query("UPDATE gacha_trades SET status = 'rejected' WHERE id = ?", [trade_id]);
        await connection.commit();
        return res.json({ success: true, status: "rejected" });
      }

      if (action === "cancel") {
        if (trade.sender_id !== req.user.id) {
          await connection.rollback();
          return res.status(403).json({ error: "Ruxsat yo'q!" });
        }
        await connection.query("UPDATE gacha_trades SET status = 'cancelled' WHERE id = ?", [trade_id]);
        await connection.commit();
        return res.json({ success: true, status: "cancelled" });
      }

      if (action === "accept") {
        if (trade.receiver_id !== req.user.id) {
          await connection.rollback();
          return res.status(403).json({ error: "Faqat qabul qiluvchi tasdiqlashi mumkin!" });
        }

        const senderCardIds: number[] = JSON.parse(trade.sender_card_ids || "[]");
        const receiverCardIds: number[] = JSON.parse(trade.receiver_card_ids || "[]");

        // Swap Cards ownership
        if (senderCardIds.length > 0) {
          await connection.query("UPDATE user_cards SET user_id = ? WHERE id IN (?) AND user_id = ?", [
            trade.receiver_id,
            senderCardIds,
            trade.sender_id
          ]);
        }
        if (receiverCardIds.length > 0) {
          await connection.query("UPDATE user_cards SET user_id = ? WHERE id IN (?) AND user_id = ?", [
            trade.sender_id,
            receiverCardIds,
            trade.receiver_id
          ]);
        }

        // Swap Coins if any
        if (trade.sender_coins > 0) {
          await connection.query("UPDATE users SET coins = coins - ? WHERE id = ?", [trade.sender_coins, trade.sender_id]);
          await connection.query("UPDATE users SET coins = COALESCE(coins, 0) + ? WHERE id = ?", [trade.sender_coins, trade.receiver_id]);
        }
        if (trade.receiver_coins > 0) {
          await connection.query("UPDATE users SET coins = coins - ? WHERE id = ?", [trade.receiver_coins, trade.receiver_id]);
          await connection.query("UPDATE users SET coins = COALESCE(coins, 0) + ? WHERE id = ?", [trade.receiver_coins, trade.sender_id]);
        }

        await connection.query("UPDATE gacha_trades SET status = 'accepted' WHERE id = ?", [trade_id]);
        await connection.commit();

        return res.json({ success: true, status: "accepted" });
      }

      await connection.rollback();
      res.status(400).json({ error: "Noma'lum amal" });
    } catch (err: any) {
      if (connection) await connection.rollback();
      res.status(500).json({ error: "Savdoni bajarishda xatolik" });
    } finally {
      if (connection) connection.release();
    }
  });

  // 15. Global Leaderboard by Total Collection Power
  app.get("/api/gacha/leaderboard", async (req, res) => {
    try {
      const [topUsers]: any = await dbQuery(`
        SELECT u.id, u.name, u.avatar_url, u.coins,
               COUNT(uc.id) as total_cards,
               COALESCE(SUM(gc.power), 0) as total_power,
               SUM(CASE WHEN gc.rarity = 'SSR' THEN 1 ELSE 0 END) as ssr_count
        FROM users u
        LEFT JOIN user_cards uc ON u.id = uc.user_id
        LEFT JOIN gacha_cards gc ON uc.card_id = gc.id
        GROUP BY u.id
        HAVING total_cards > 0 OR u.coins > 1000
        ORDER BY total_power DESC, total_cards DESC, u.coins DESC
        LIMIT 30
      `);

      res.json(topUsers);
    } catch (err: any) {
      res.status(500).json({ error: "Reytingni yuklashda xatolik" });
    }
  });

  const requireAdmin = (req: any, res: any, next: any) => {
    if (req.user && req.user.role === 'admin') {
      return next();
    }
    return res.status(403).json({ error: "Faqat adminlar uchun ruxsat berilgan!" });
  };

  // ADMIN: Save or Update Gacha Box
  app.post("/api/admin/gacha/boxes", authenticateToken, requireAdmin, async (req: any, res) => {
    try {
      const { id, name, price_coins, image_url, description, type_filter } = req.body;
      if (!name || !price_coins || !image_url) {
        return res.status(400).json({ error: "Quti nomi, narxi va rasmi majburiy!" });
      }

      if (id) {
        await dbQuery(
          "UPDATE gacha_boxes SET name = ?, price_coins = ?, image_url = ?, description = ?, type_filter = ? WHERE id = ?",
          [name, Number(price_coins), image_url, description || "", type_filter || "all", id]
        );
        res.json({ success: true, message: "Quti muvaffaqiyatli yangilandi!" });
      } else {
        await dbQuery(
          "INSERT INTO gacha_boxes (name, price_coins, image_url, description, type_filter) VALUES (?, ?, ?, ?, ?)",
          [name, Number(price_coins), image_url, description || "", type_filter || "all"]
        );
        res.json({ success: true, message: "Yangi quti muvaffaqiyatli qo'shildi!" });
      }
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Qutini saqlashda xatolik" });
    }
  });

  // ADMIN: Delete Gacha Box
  app.delete("/api/admin/gacha/boxes/:id", authenticateToken, requireAdmin, async (req: any, res) => {
    try {
      await dbQuery("DELETE FROM gacha_boxes WHERE id = ?", [req.params.id]);
      res.json({ success: true, message: "Quti o'chirildi!" });
    } catch (err: any) {
      res.status(500).json({ error: "Qutini o'chirishda xatolik" });
    }
  });

  // ADMIN: Save or Update Gacha Card
  app.post("/api/admin/gacha/cards", authenticateToken, requireAdmin, async (req: any, res) => {
    try {
      const { id, name, anime, type, rarity, power, image_url, description } = req.body;
      if (!name || !anime || !image_url) {
        return res.status(400).json({ error: "Karta nomi, animesi va rasmi majburiy!" });
      }

      if (id) {
        await dbQuery(
          "UPDATE gacha_cards SET name = ?, anime = ?, type = ?, rarity = ?, power = ?, image_url = ?, description = ? WHERE id = ?",
          [name, anime, type || "waifu", rarity || "C", Number(power) || 100, image_url, description || "", id]
        );
        res.json({ success: true, message: "Karta muvaffaqiyatli yangilandi!" });
      } else {
        await dbQuery(
          "INSERT INTO gacha_cards (name, anime, type, rarity, power, image_url, description) VALUES (?, ?, ?, ?, ?, ?, ?)",
          [name, anime, type || "waifu", rarity || "C", Number(power) || 100, image_url, description || ""]
        );
        res.json({ success: true, message: "Yangi karta muvaffaqiyatli qo'shildi!" });
      }
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Kartani saqlashda xatolik" });
    }
  });

  // ADMIN: Delete Gacha Card
  app.delete("/api/admin/gacha/cards/:id", authenticateToken, requireAdmin, async (req: any, res) => {
    try {
      await dbQuery("DELETE FROM gacha_cards WHERE id = ?", [req.params.id]);
      res.json({ success: true, message: "Karta o'chirildi!" });
    } catch (err: any) {
      res.status(500).json({ error: "Kartani o'chirishda xatolik" });
    }
  });
}
