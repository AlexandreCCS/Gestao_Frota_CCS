// [09/05/2026 - Alexandre Carvalho] Cliente Postgres do tenant central CCS
// Pool unico exportado, conexoes lazy (sobe sob demanda).
import pg from 'pg';
import { config } from '../config.js';

const pool = new pg.Pool({
  host:     config.tenant.host,
  port:     config.tenant.port,
  database: config.tenant.database,
  user:     config.tenant.user,
  password: config.tenant.password,
  // Pool conservador — esta API e single-tenant a cada request.
  max:                  10,
  idleTimeoutMillis:    10_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  // Conexao morreu no pool — log mas nao derruba o processo.
  console.error('[tenant pool error]', err.message);
});

/**
 * Executa uma query no Postgres do tenant.
 * @param {string} text
 * @param {Array}  [params]
 * @returns {Promise<pg.QueryResult>}
 */
export function tenantQuery(text, params) {
  return pool.query(text, params);
}

/**
 * Health do tenant — usado pelo /health da API.
 * Retorna { ok, latency_ms, error }.
 */
export async function tenantHealth() {
  const t0 = Date.now();
  try {
    await pool.query('SELECT 1');
    return { ok: true, latency_ms: Date.now() - t0 };
  } catch (err) {
    return { ok: false, latency_ms: Date.now() - t0, error: err.message };
  }
}

export async function closeTenantPool() {
  await pool.end();
}
