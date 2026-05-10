// [09/05/2026 - Alexandre Carvalho] Healthcheck publico — usado pelo Caddy/Docker
import { tenantHealth } from '../lib/tenant.js';

export default async function healthRoutes(app) {
  // Liveness — proceso esta de pe? Sem deps externas.
  app.get('/health', async () => ({
    status: 'ok',
    service: 'frota-api',
    version: '0.1.0',
    timestamp: new Date().toISOString(),
  }));

  // Readiness — todas as deps funcionando? Inclui ping no Postgres tenant.
  app.get('/health/ready', async (req, reply) => {
    const tenant = await tenantHealth();
    const allOk = tenant.ok;
    reply.code(allOk ? 200 : 503);
    return {
      status: allOk ? 'ready' : 'degraded',
      checks: { tenant_db: tenant },
      timestamp: new Date().toISOString(),
    };
  });
}
