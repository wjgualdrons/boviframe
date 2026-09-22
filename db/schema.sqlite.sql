-- Boviframe: SQLite schema for a per-user database
-- Intended to be created per user at: storage/db/{user_id}.sqlite
-- Initialize with: sqlite3 storage/db/{user_id}.sqlite < db/schema.sqlite.sql

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

BEGIN TRANSACTION;

-- Owner / profile info for this DB (single-row table)
CREATE TABLE IF NOT EXISTS owner (
  id TEXT PRIMARY KEY,            -- UUID (text)
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- Projects that the user creates within their DB
CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  visibility TEXT NOT NULL DEFAULT 'private', -- local visibility hints
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_projects_slug ON projects(slug);

-- Frames (artboards) per project
CREATE TABLE IF NOT EXISTS frames (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  width INTEGER NOT NULL,
  height INTEGER NOT NULL,
  metadata TEXT,                 -- JSON stored as TEXT
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_frames_project_id ON frames(project_id);

-- Assets (images, svg, fonts, etc.)
CREATE TABLE IF NOT EXISTS assets (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  path TEXT NOT NULL,            -- local storage path or URL
  type TEXT NOT NULL,            -- 'image', 'svg', 'font', etc.
  size_bytes INTEGER,
  metadata TEXT,                 -- JSON
  uploaded_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_assets_project_id ON assets(project_id);

-- Layers inside frames
CREATE TABLE IF NOT EXISTS layers (
  id TEXT PRIMARY KEY,
  frame_id TEXT NOT NULL REFERENCES frames(id) ON DELETE CASCADE,
  parent_layer_id TEXT REFERENCES layers(id) ON DELETE SET NULL,
  name TEXT,
  type TEXT NOT NULL,            -- 'shape','image','text','group', etc.
  order_index INTEGER NOT NULL DEFAULT 0,
  visible INTEGER NOT NULL DEFAULT 1,
  locked INTEGER NOT NULL DEFAULT 0,
  properties TEXT,               -- JSON
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_layers_frame_id ON layers(frame_id);

-- Frame versions (snapshots)
CREATE TABLE IF NOT EXISTS frame_versions (
  id TEXT PRIMARY KEY,
  frame_id TEXT NOT NULL REFERENCES frames(id) ON DELETE CASCADE,
  snapshot TEXT NOT NULL,        -- serialized JSON snapshot
  message TEXT,
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_frame_versions_frame_id ON frame_versions(frame_id);

-- Annotations and comments
CREATE TABLE IF NOT EXISTS annotations (
  id TEXT PRIMARY KEY,
  frame_id TEXT REFERENCES frames(id) ON DELETE CASCADE,
  layer_id TEXT REFERENCES layers(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  bbox TEXT,                     -- JSON: {x,y,w,h}
  resolved INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  annotation_id TEXT NOT NULL REFERENCES annotations(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

-- Tags and many-to-many relation with frames
CREATE TABLE IF NOT EXISTS tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS frame_tags (
  frame_id TEXT NOT NULL REFERENCES frames(id) ON DELETE CASCADE,
  tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (frame_id, tag_id)
);

-- Evaluations: user enriches their DB with evaluations/ratings/notes
CREATE TABLE IF NOT EXISTS evaluations (
  id TEXT PRIMARY KEY,
  target_type TEXT NOT NULL,     -- 'frame','asset','layer'
  target_id TEXT NOT NULL,       -- id of the target
  score INTEGER,                  -- optional numeric score
  category TEXT,                  -- optional label/category
  notes TEXT,
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_evaluations_target ON evaluations(target_type, target_id);

-- Lightweight activity log
CREATE TABLE IF NOT EXISTS activities (
  id TEXT PRIMARY KEY,
  action TEXT NOT NULL,
  payload TEXT,                  -- JSON
  created_at DATETIME NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON activities(created_at);

COMMIT;

-- Notes:
-- 1) Use TEXT for JSON fields; consider enabling the JSON1 extension when querying JSON parts.
-- 2) IDs use TEXT so UUIDs can be stored; apps may prefer ULIDs or integer IDs.
-- 3) To initialize on user registration: create file storage/db/{user_id}.sqlite, then run the above SQL against it.
-- 4) Example initialization (bash / windows):
--    sqlite3 storage/db/USER_ID.sqlite < db/schema.sqlite.sql
-- 5) Back up per-user DB files for persistence; for sync or server deployments, consider migrating to PostgreSQL and use one schema per tenant or dedicated DB per tenant.
