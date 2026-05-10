// [09/05/2026 - Alexandre Carvalho] Auth STUB — apenas estrutura.
// O fluxo real (validacao contra Oracle Mega + emissao JWT) sera implementado
// em PR proprio. Este arquivo expoe os endpoints com retorno placeholder
// para que o frontend possa comecar a integrar.

export default async function authRoutes(app) {
  /**
   * POST /auth/login
   * Body: { ocpdb, usuario, senha }
   * STUB: retorna 501 Not Implemented com a estrutura esperada.
   */
  app.post('/auth/login', async (req, reply) => {
    reply.code(501);
    return {
      error: 'not_implemented',
      message: 'Auth/login ainda nao implementado — proximo PR.',
      expected_request_body: {
        ocpdb:   'string (ex.: OCPDB493)',
        usuario: 'string',
        senha:   'string',
      },
      expected_response_200: {
        token:        'JWT string',
        token_type:   'Bearer',
        expires_in:   43200,
        user: {
          ocpdb:   'OCPDB493',
          usuario: 'string',
          nome:    'string',
        },
      },
    };
  });

  /**
   * GET /auth/me
   * STUB: retorna 501 Not Implemented.
   */
  app.get('/auth/me', async (req, reply) => {
    reply.code(501);
    return {
      error: 'not_implemented',
      message: 'Auth/me ainda nao implementado — proximo PR.',
    };
  });

  /**
   * POST /auth/logout
   * STUB: retorna 204 sempre (logout sem estado pelo cliente apagar token).
   */
  app.post('/auth/logout', async (req, reply) => {
    reply.code(204);
    return null;
  });
}
