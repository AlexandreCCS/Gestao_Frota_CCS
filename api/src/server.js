// [09/05/2026 - Alexandre Carvalho] Entry point da frota-api
// Padrao similar ao gestor-financeiro CCS (Fastify + plugins + rotas modulares)
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';

import { config } from './config.js';
import healthRoutes from './routes/health.js';
import authRoutes from './routes/auth.js';
import { closeTenantPool } from './lib/tenant.js';

async function buildApp() {
  const app = Fastify({
    logger: {
      level: config.logLevel,
      transport: config.env === 'development'
        ? { target: 'pino-pretty', options: { translateTime: 'HH:MM:ss.l', ignore: 'pid,hostname' } }
        : undefined,
    },
    trustProxy: true,
  });

  // CORS — origem controlada por env CORS_ORIGIN
  await app.register(cors, {
    origin: config.cors.origin,
    credentials: true,
  });

  // JWT — usado a partir do proximo PR (auth real)
  await app.register(jwt, {
    secret: config.jwt.secret,
    sign:   { expiresIn: config.jwt.expiresIn },
  });

  // Rotas
  await app.register(healthRoutes);
  await app.register(authRoutes, { prefix: '/auth' });

  return app;
}

async function start() {
  const app = await buildApp();

  const shutdown = async (signal) => {
    app.log.info({ signal }, 'shutdown recebido');
    try {
      await app.close();
      await closeTenantPool();
      process.exit(0);
    } catch (err) {
      app.log.error(err, 'falha durante shutdown');
      process.exit(1);
    }
  };
  process.on('SIGINT',  () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));

  try {
    await app.listen({ port: config.port, host: config.host });
    app.log.info(`frota-api escutando em ${config.host}:${config.port}`);
  } catch (err) {
    app.log.error(err, 'falha ao subir servidor');
    process.exit(1);
  }
}

start();
