import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Prefer discrete fields so passwords with /, +, = do not break a URL.
function poolConfig() {
  if (process.env.PGHOST || process.env.POSTGRES_HOST) {
    return {
      host: process.env.PGHOST || process.env.POSTGRES_HOST || 'selah-postgres',
      port: Number(process.env.PGPORT || process.env.POSTGRES_PORT || 5432),
      user: process.env.PGUSER || process.env.POSTGRES_USER || 'selah',
      password: process.env.PGPASSWORD || process.env.POSTGRES_PASSWORD || '',
      database: process.env.PGDATABASE || process.env.POSTGRES_DB || 'selah',
    };
  }
  if (process.env.DATABASE_URL) {
    return { connectionString: process.env.DATABASE_URL };
  }
  return {
    host: 'localhost',
    port: 5432,
    user: 'selah',
    password: 'selah',
    database: 'selah',
  };
}

const pool = new pg.Pool(poolConfig());

export async function query(text, params) {
  return pool.query(text, params);
}

export async function withClient(fn) {
  const client = await pool.connect();
  try {
    return await fn(client);
  } finally {
    client.release();
  }
}

export async function migrate() {
  await query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
  const dir = path.join(__dirname, '..', 'migrations');
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) {
    const { rows } = await query(
      'SELECT 1 FROM schema_migrations WHERE filename = $1',
      [file],
    );
    if (rows.length) continue;
    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    await withClient(async (client) => {
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query(
          'INSERT INTO schema_migrations (filename) VALUES ($1)',
          [file],
        );
        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      }
    });
    console.log(`Applied migration ${file}`);
  }
}

export async function closePool() {
  await pool.end();
}
