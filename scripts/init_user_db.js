#!/usr/bin/env node
// scripts/init_user_db.js
// Usage: node scripts/init_user_db.js <user_id> <email>
// Requires: npm install sqlite3

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const [,, userId, email] = process.argv;
if (!userId) {
  console.error('Usage: node scripts/init_user_db.js <user_id> [email]');
  process.exit(2);
}

const projectRoot = path.resolve(__dirname, '..');
const schemaFile = path.join(projectRoot, 'db', 'schema.sqlite.sql');
const storageDir = path.join(projectRoot, 'storage', 'db');
const dbPath = path.join(storageDir, `${userId}.sqlite`);

if (!fs.existsSync(schemaFile)) {
  console.error('Schema file missing:', schemaFile);
  process.exit(3);
}

fs.mkdirSync(storageDir, { recursive: true });

const sql = fs.readFileSync(schemaFile, 'utf8');

console.log(`Initializing DB for user ${userId} at ${dbPath}`);

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to open DB:', err.message);
    process.exit(4);
  }

  db.exec('PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL;', (pragmaErr) => {
    if (pragmaErr) console.warn('PRAGMA warning:', pragmaErr.message);

    db.exec(sql, function(execErr) {
      if (execErr) {
        console.error('Failed to initialize schema:', execErr.message);
        db.close(() => process.exit(5));
        return;
      }

      // Insert owner row (single-row table) if present
      try {
        const now = new Date().toISOString();
        const ownerId = userId;
        const insertOwner = `INSERT OR IGNORE INTO owner (id, email, display_name, created_at) VALUES (?, ?, ?, ?);`;
        db.run(insertOwner, [ownerId, email || null, null, now], (insErr) => {
          if (insErr) console.warn('Could not insert owner row:', insErr.message);
          console.log('Database created and initialized successfully.');
          db.close();
        });
      } catch (e) {
        console.warn('Owner insert skipped:', e.message);
        console.log('Database created and initialized successfully.');
        db.close();
      }
    });
  });
});
