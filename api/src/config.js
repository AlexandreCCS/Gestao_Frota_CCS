// [09/05/2026 - Alexandre Carvalho] Carregamento de .env sem dependencia (padrao CCS)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ENV_PATH = path.join(__dirname, '..', '.env');

if (fs.existsSync(ENV_PATH)) {
  for (const line of fs.readFileSync(ENV_PATH, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (m && process.env[m[1]] === undefined) {
      process.env[m[1]] = m[2];
    }
  }
}

function int(name, def) {
  const v = process.env[name];
  return v === undefined || v === '' ? def : Number.parseInt(v, 10);
}

function str(name, def) {
  const v = process.env[name];
  return v === undefined || v === '' ? def : v;
}

function csv(name, def = []) {
  const v = process.env[name];
  if (!v) return def;
  return v.split(',').map(s => s.trim()).filter(Boolean);
}

export const config = {
  env:        str('NODE_ENV', 'development'),
  port:       int('PORT', 3030),
  host:       str('HOST', '0.0.0.0'),
  logLevel:   str('LOG_LEVEL', 'info'),

  jwt: {
    secret:    str('JWT_SECRET', 'dev-only-change-me'),
    expiresIn: str('JWT_EXPIRES_IN', '12h'),
  },

  tenant: {
    host:     str('TENANT_DB_HOST', '127.0.0.1'),
    port:     int('TENANT_DB_PORT', 5435),
    database: str('TENANT_DB_NAME', 'frota_tenant'),
    user:     str('TENANT_DB_USER', 'frota'),
    password: str('TENANT_DB_PASSWORD', ''),
  },

  soap: {
    host:      str('SOAP_HOST', 'apiquality1.ccstecno.com.br'),
    path:      str('SOAP_PATH', '/webService.asmx'),
    namespace: str('SOAP_NAMESPACE', 'http://tempuri.org/'),
    timeoutMs: int('SOAP_TIMEOUT_MS', 30000),
  },

  cors: {
    origin: csv('CORS_ORIGIN', ['http://localhost:3031']),
  },
};
