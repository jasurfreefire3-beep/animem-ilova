import mysql from "mysql2/promise";
import dotenv from "dotenv";
dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || "db.fr-pari1.bengt.wasmernet.com",
  port: Number(process.env.DB_PORT) || 10272,
  user: process.env.DB_USER || "user_b1d5fdb1",
  password: process.env.DB_PASSWORD || "pw_7GNRdocASAIUzobl5Ezatle9fwRC3oYq",
  database: process.env.DB_NAME || "dataanime",
});

async function initGacha() {
  const connection = await pool.getConnection();
  try {
    console.log("Initializing Gacha & Economy Tables in MySQL...");

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
      console.log("Added 'coins' column to users.");
    }

    if (!colNames.includes("last_daily_claim")) {
      await connection.query("ALTER TABLE users ADD COLUMN last_daily_claim TIMESTAMP NULL DEFAULT NULL");
      console.log("Added 'last_daily_claim' column to users.");
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

    console.log("All Gacha tables created successfully!");

    // 8. Seed Cards if empty
    const [existingCards]: any = await connection.query("SELECT COUNT(*) as count FROM gacha_cards");
    if (existingCards[0].count === 0) {
      console.log("Seeding initial Anime Waifu & Husbando Cards...");
      const sampleCards = [
        // SSR (Legendary)
        ["Nezuko Kamado", "Demon Slayer", "waifu", "SSR", 25000, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Demon Slayer-ning eng sevimli iblis singlisi!"],
        ["Gojo Satoru", "Jujutsu Kaisen", "husbando", "SSR", 28000, "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop", "Cheksizlik texnikasi egasi, eng kuchli shaman!"],
        ["Mikasa Ackerman", "Attack on Titan", "waifu", "SSR", 24000, "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop", "Ackerman urug'ining eng kuchli jangchisi!"],
        ["Roronoa Zoro", "One Piece", "husbando", "SSR", 26000, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "3 qilich ustasi, Samuraylar qiroli!"],
        ["Makima", "Chainsaw Man", "waifu", "SSR", 27000, "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop", "Boshqaruv Iblisi, sirli va xavfli guzal!"],

        // UR (Ultra Rare)
        ["Yor Forger", "Spy x Family", "waifu", "UR", 7000, "https://images.unsplash.com/photo-1541562232579-512a21360020?w=600&auto=format&fit=crop", "Tikanli qirolicha va mehribon ona!"],
        ["Levi Ackerman", "Attack on Titan", "husbando", "UR", 7500, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "Insoniyatning eng kuchli kapitani!"],
        ["Marin Kitagawa", "My Dress-Up Darling", "waifu", "UR", 6500, "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop", "Cosplay va moda qirolichasi!"],
        ["Megumi Fushiguro", "Jujutsu Kaisen", "husbando", "UR", 6800, "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop", "O'n soyalar texnikasi egasi!"],
        ["Zero Two", "Darling in the Franxx", "waifu", "UR", 7200, "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop", "Qizil shoxli afsonaviy pilot!"],
        ["Ryomen Sukuna", "Jujutsu Kaisen", "husbando", "UR", 7400, "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop", "La'natlar Qiroli!"],

        // SR (Super Rare)
        ["Rem", "Re:Zero", "waifu", "SR", 2200, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "Moviy sochli sodiq iblis xizmatchi!"],
        ["Tanjiro Kamado", "Demon Slayer", "husbando", "SR", 2100, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Kuyosh nafasi ustasi!"],
        ["Anya Forger", "Spy x Family", "waifu", "SR", 1800, "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop", "Fikr o'quvchi shirin qizaloq! Waku Waku!"],
        ["Kageyama Tobio", "Haikyuu!!", "husbando", "SR", 1900, "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop", "Maydon Qiroli, dahshatli bog'lovchi!"],
        ["Shinobu Kocho", "Demon Slayer", "waifu", "SR", 2300, "https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop", "Kapalak Hashirasi va zahar ustasi!"],

        // R (Rare)
        ["Zenitsu Agatsuma", "Demon Slayer", "husbando", "R", 750, "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop", "Maltillash nafasi, uxlaganda daxshat!"],
        ["Nobara Kugisaki", "Jujutsu Kaisen", "waifu", "R", 720, "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop", "Mux va bolg'a shamani!"],
        ["Megumin", "Konosuba", "waifu", "R", 800, "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop", "EXPLOSION sehri ustasi!"],
        ["Inosuke Hashibira", "Demon Slayer", "husbando", "R", 780, "https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop", "To'ng'iz niqobli yirtqich jangchi!"],

        // C (Common)
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
      console.log("Seeded cards!");
    }

    // 9. Seed Boxes if empty
    const [existingBoxes]: any = await connection.query("SELECT COUNT(*) as count FROM gacha_boxes");
    if (existingBoxes[0].count === 0) {
      console.log("Seeding Gacha Boxes...");
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
          "Faqat go'zal anime Waifular tushadigan maxsus VIP quti! Yuqori darajadagi kartalar ehtimoli yuqori!",
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
      console.log("Seeded boxes!");
    }

  } catch (err: any) {
    console.error("Gacha init error:", err);
  } finally {
    connection.release();
    process.exit(0);
  }
}

initGacha();
