// [09/05/2026 - Alexandre Carvalho] Bridge SOAP para o webservice Quality (apiquality1)
// Padrao canonico documentado em C:\Claudete\Instrucoes\Conexoes.md
//
// As credenciais de cada cliente (banco/usuario/senha) NAO ficam aqui — sao
// resolvidas pelo tenant central a cada requisicao, com cache curto.
import https from 'node:https';
import { config } from '../config.js';

const xmlEscape = s => String(s)
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;');

/**
 * Executa uma operacao SOAP no webservice Quality.
 *
 * @param {object}  params
 * @param {string}  params.banco     OCPDB do cliente (ex.: OCPDB493)
 * @param {string}  params.usuario   usuario Oracle do cliente
 * @param {string}  params.senha    senha Oracle do cliente
 * @param {string}  params.sql       SQL ou bloco PL/SQL
 * @param {string} [params.op=GetDataSet]  GetDataSet | ExecuteNonQuery | GetXML | ...
 * @returns {Promise<string>} XML cru da resposta
 */
export function soapCall({ banco, usuario, senha, sql, op = 'GetDataSet' }) {
  const xmlSql = xmlEscape(sql);
  const body =
    `<?xml version="1.0" encoding="utf-8"?>` +
    `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="${config.soap.namespace}">` +
      `<soap:Body>` +
        `<tem:${op}>` +
          `<tem:Banco>${xmlEscape(banco)}</tem:Banco>` +
          `<tem:Usuario>${xmlEscape(usuario)}</tem:Usuario>` +
          `<tem:Senha>${xmlEscape(senha)}</tem:Senha>` +
          `<tem:QuerySQL>${xmlSql}</tem:QuerySQL>` +
        `</tem:${op}>` +
      `</soap:Body>` +
    `</soap:Envelope>`;

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: config.soap.host,
      path:     config.soap.path,
      method:   'POST',
      timeout:  config.soap.timeoutMs,
      headers: {
        'Content-Type':   'text/xml; charset=utf-8',
        'SOAPAction':     `${config.soap.namespace}${op}`,
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      let data = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => { data += chunk; });
      res.on('end',  () => resolve(data));
    });

    req.on('error',   reject);
    req.on('timeout', () => {
      req.destroy(new Error(`SOAP timeout apos ${config.soap.timeoutMs}ms`));
    });
    req.write(body);
    req.end();
  });
}

/**
 * Detecta erro Oracle dentro do XML de resposta.
 * Erros podem vir em <MENSAGEM> ou <ERRO> (visto na KR — ver Conexoes.md).
 *
 * @param {string} xml
 * @returns {string|null} mensagem de erro, ou null se sucesso
 */
export function detectSoapError(xml) {
  const m = xml.match(/<(MENSAGEM|ERRO)>([\s\S]*?)<\/\1>/);
  if (!m) return null;
  const msg = m[2].trim();
  if (/^(OK|Sucesso|Success)/i.test(msg)) return null;
  return msg;
}

/**
 * Parse de respostas GetDataSet — converte cada <Table>...</Table> num objeto.
 *
 * @param {string} xml
 * @returns {Array<Object<string,string>>}
 */
export function parseRows(xml) {
  const rows = [];
  for (const m of xml.matchAll(/<Table[^>]*>([\s\S]*?)<\/Table>/g)) {
    const row = {};
    for (const f of m[1].matchAll(/<([A-Z0-9_]+)>([\s\S]*?)<\/\1>/g)) {
      row[f[1]] = f[2].trim();
    }
    rows.push(row);
  }
  return rows;
}

/**
 * Atalho: executa GetDataSet e retorna linhas parseadas, ou lanca erro Oracle.
 *
 * @param {object} params  mesmo shape de soapCall
 * @returns {Promise<Array<Object>>}
 */
export async function query(params) {
  const xml = await soapCall({ ...params, op: 'GetDataSet' });
  const err = detectSoapError(xml);
  if (err) throw new Error(`Oracle error: ${err}`);
  return parseRows(xml);
}
