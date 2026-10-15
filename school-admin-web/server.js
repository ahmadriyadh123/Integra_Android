import { createServer } from "node:http";
import { randomBytes, timingSafeEqual, randomUUID } from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { extname, join, normalize, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL(".", import.meta.url));
const PORT = Number.parseInt(process.env.PORT || "4174", 10);
const HOST = process.env.SCHOOL_ADMIN_HOST || "127.0.0.1";
const ADMIN_PASSWORD = process.env.SCHOOL_ADMIN_PASSWORD || "";
const DATA_FILE = resolve(
  ROOT,
  process.env.SCHOOL_ADMIN_DATA_FILE || "data/configuration.json",
);
const SESSION_TTL_MS = 12 * 60 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 15_000;
const MAX_BODY_BYTES = 1024 * 1024;
const sessions = new Map();
const loginAttempts = new Map();
let storageQueue = Promise.resolve();

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
};

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function sendJson(response, status, payload) {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    "Cache-Control": "no-store",
    "Content-Length": Buffer.byteLength(body),
    "Content-Type": "application/json; charset=utf-8",
    "X-Content-Type-Options": "nosniff",
  });
  response.end(body);
}

async function readBody(request) {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of request) {
    bytes += chunk.length;
    if (bytes > MAX_BODY_BYTES) {
      throw new HttpError(413, "Request body terlalu besar.");
    }
    chunks.push(chunk);
  }
  if (!bytes) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new HttpError(400, "Request harus berisi JSON yang valid.");
  }
}

async function readStore() {
  try {
    const value = JSON.parse(await readFile(DATA_FILE, "utf8"));
    if (
      value?.version !== 1 ||
      !Array.isArray(value.tenants) ||
      !Array.isArray(value.configurations)
    ) {
      throw new Error("Skema file konfigurasi tidak dikenal.");
    }
    return value;
  } catch (error) {
    if (error.code === "ENOENT") {
      return { version: 1, tenants: [], configurations: [] };
    }
    throw error;
  }
}

async function writeStore(store) {
  storageQueue = storageQueue.then(async () => {
    await mkdir(join(DATA_FILE, ".."), { recursive: true });
    const temporaryFile = `${DATA_FILE}.${randomUUID()}.tmp`;
    await writeFile(temporaryFile, `${JSON.stringify(store, null, 2)}\n`, {
      encoding: "utf8",
      mode: 0o600,
    });
    await rename(temporaryFile, DATA_FILE);
  });
  return storageQueue;
}

function requireString(value, label, maxLength = 200) {
  if (typeof value !== "string" || !value.trim() || value.trim().length > maxLength) {
    throw new HttpError(400, `${label} wajib diisi (maksimal ${maxLength} karakter).`);
  }
  return value.trim();
}

function normalizeTenantUrl(value) {
  let url;
  try {
    url = new URL(requireString(value, "URL Odoo", 500));
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(400, "URL tenant harus berupa URL HTTP/HTTPS yang valid.");
  }
  if (
    !["https:", "http:"].includes(url.protocol) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash
  ) {
    throw new HttpError(400, "URL tenant tidak boleh berisi kredensial, query, atau fragment.");
  }
  if (
    url.protocol !== "https:" &&
    !["localhost", "127.0.0.1", "::1"].includes(url.hostname)
  ) {
    throw new HttpError(400, "Odoo tenant non-localhost wajib menggunakan HTTPS.");
  }
  return url.href.replace(/\/+$/, "");
}

function normalizeConfiguration(body) {
  const name = requireString(body.name, "Nama fitur", 120);
  const model = requireString(body.model, "Model Odoo", 200);
  if (!/^[a-z][a-z0-9_.]*$/.test(model)) {
    throw new HttpError(400, "Nama model Odoo tidak valid.");
  }
  if (!Array.isArray(body.fields) || body.fields.length === 0) {
    throw new HttpError(400, "Pilih minimal satu field model.");
  }
  const fields = [...new Set(body.fields.map((field) => requireString(field, "Nama field", 200)))];
  if (fields.some((field) => !/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(field))) {
    throw new HttpError(400, "Nama field model tidak valid.");
  }
  if (!Array.isArray(body.relations || [])) {
    throw new HttpError(400, "Daftar relasi harus berupa array.");
  }
  const relations = (body.relations || []).map((relation) => {
    const field = requireString(relation.field, "Field relasi", 200);
    const targetModel = requireString(relation.model, "Model tujuan relasi", 200);
    if (
      !/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(field) ||
      !/^[a-z][a-z0-9_.]*$/.test(targetModel)
    ) {
      throw new HttpError(400, "Nama field atau model relasi tidak valid.");
    }
    if (!Array.isArray(relation.fields) || relation.fields.length === 0) {
      throw new HttpError(400, `Pilih minimal satu field untuk relasi ${field}.`);
    }
    const targetFields = [...new Set(
      relation.fields.map((value) => requireString(value, "Field tujuan", 200)),
    )];
    if (targetFields.some((value) => !/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value))) {
      throw new HttpError(400, `Nama field tujuan relasi ${field} tidak valid.`);
    }
    return {
      field,
      model: targetModel,
      fields: targetFields,
    };
  });
  const displayField = body.displayField
    ? requireString(body.displayField, "Field judul", 200)
    : fields[0];
  const sortField = body.sortField
    ? requireString(body.sortField, "Field pengurutan", 200)
    : "";
  if (!fields.includes(displayField)) {
    throw new HttpError(400, "Field judul harus termasuk field model yang dipilih.");
  }
  if (sortField && !fields.includes(sortField)) {
    throw new HttpError(400, "Field pengurutan harus termasuk field model yang dipilih.");
  }
  const allowedOperators = new Set([
    "=", "!=", ">", ">=", "<", "<=", "like", "ilike", "in", "not in",
  ]);
  if (!Array.isArray(body.filters || [])) {
    throw new HttpError(400, "Daftar filter harus berupa array.");
  }
  const filters = (body.filters || []).map((filter) => {
    const field = requireString(filter.field, "Field filter", 200);
    const operator = requireString(filter.operator, "Operator filter", 20);
    const value = filter.value;
    if (!fields.includes(field)) {
      throw new HttpError(400, `Field filter ${field} harus dipilih sebagai field model.`);
    }
    if (!allowedOperators.has(operator)) {
      throw new HttpError(400, `Operator filter ${operator} tidak didukung.`);
    }
    if (value === undefined || value === null || typeof value === "object") {
      throw new HttpError(400, `Nilai filter ${field} tidak valid.`);
    }
    const stringValue = String(value);
    if (!stringValue.trim() || stringValue.length > 500) {
      throw new HttpError(400, `Nilai filter ${field} wajib diisi (maksimal 500 karakter).`);
    }
    return { field, operator, value: stringValue.trim() };
  });
  if (body.order !== undefined && !["asc", "desc"].includes(body.order)) {
    throw new HttpError(400, "Arah pengurutan harus asc atau desc.");
  }
  const order = body.order || "asc";
  const limit = body.limit === undefined ? 50 : Number(body.limit);
  if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
    throw new HttpError(400, "Batas data harus di antara 1 dan 500.");
  }
  return { name, model, fields, relations, filters, displayField, sortField, order, limit };
}

function requireSession(request) {
  const authorization = request.headers.authorization || "";
  const token = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length)
    : "";
  const expiresAt = sessions.get(token);
  if (!expiresAt || expiresAt <= Date.now()) {
    sessions.delete(token);
    throw new HttpError(401, "Sesi admin berakhir. Silakan masuk kembali.");
  }
  sessions.set(token, Date.now() + SESSION_TTL_MS);
}

function constantTimeMatches(candidate, expected) {
  const candidateHash = Buffer.from(candidate);
  const expectedHash = Buffer.from(expected);
  return (
    candidateHash.length === expectedHash.length &&
    timingSafeEqual(candidateHash, expectedHash)
  );
}

async function odooJsonRpc(baseUrl, route, params, cookie = "") {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(`${baseUrl}${route}`, {
      method: "POST",
      redirect: "error",
      headers: {
        "Content-Type": "application/json",
        ...(cookie ? { Cookie: cookie } : {}),
      },
      body: JSON.stringify({ jsonrpc: "2.0", method: "call", params, id: 1 }),
      signal: controller.signal,
    });
    let payload;
    try {
      payload = await response.json();
    } catch {
      throw new HttpError(502, `Odoo tenant merespons dengan format non-JSON (HTTP ${response.status}).`);
    }
    if (!response.ok || payload.error) {
      const detail =
        payload.error?.data?.message ||
        payload.error?.message ||
        `HTTP ${response.status}`;
      throw new HttpError(502, `Odoo tenant menolak request: ${detail}`);
    }
    return { response, result: payload.result };
  } catch (error) {
    if (error instanceof HttpError) throw error;
    if (error.name === "AbortError") {
      throw new HttpError(504, "Odoo tenant tidak merespons dalam batas waktu 15 detik.");
    }
    throw new HttpError(502, "Server tidak dapat terhubung ke Odoo tenant. Periksa URL dan jaringan server.");
  } finally {
    clearTimeout(timeout);
  }
}

function getSessionCookie(response) {
  const values = response.headers.getSetCookie?.() || [
    response.headers.get("set-cookie") || "",
  ];
  const cookies = values
    .map((value) => value.split(";")[0])
    .filter((value) => value.startsWith("session_id="));
  if (!cookies.length) {
    throw new HttpError(502, "Odoo tidak memberikan cookie sesi. Periksa versi dan konfigurasi Odoo.");
  }
  return cookies.join("; ");
}

async function authenticatedOdooCall(tenant, login, password, model, method, args, kwargs) {
  const { response, result: authResult } = await odooJsonRpc(
    tenant.url,
    "/web/session/authenticate",
    { db: tenant.database, login, password },
  );
  if (!authResult || !Number.isInteger(authResult.uid)) {
    throw new HttpError(401, "Odoo tenant menolak login atau password.");
  }

  async function checkOdooConnection(tenant) {
    const startedAt = Date.now();
    try {
      const { result } = await odooJsonRpc(tenant.url, "/web/webclient/version_info", {});
      return {
        tenantId: tenant.id,
        connected: true,
        latencyMs: Date.now() - startedAt,
        odooVersion: result?.server_version || "",
        message: "Koneksi Odoo berhasil.",
        checkedAt: new Date().toISOString(),
      };
    } catch (error) {
      return {
        tenantId: tenant.id,
        connected: false,
        latencyMs: Date.now() - startedAt,
        message: error instanceof Error ? error.message : "Koneksi Odoo gagal.",
        checkedAt: new Date().toISOString(),
      };
    }
  }
  const cookie = getSessionCookie(response);
  const call = await odooJsonRpc(
    tenant.url,
    `/web/dataset/call_kw/${encodeURIComponent(model)}/${encodeURIComponent(method)}`,
    { model, method, args, kwargs },
    cookie,
  );
  return call.result;
}

async function discoverModels(tenant, login, password) {
  const result = await authenticatedOdooCall(
    tenant,
    login,
    password,
    "ir.model",
    "search_read",
    [[["transient", "=", false]]],
    { fields: ["id", "model", "name"], order: "model", limit: 5000 },
  );
  if (!Array.isArray(result)) {
    throw new HttpError(502, "Odoo tidak mengembalikan daftar model yang valid.");
  }
  return result;
}

async function discoverFields(tenant, login, password, model) {
  const result = await authenticatedOdooCall(
    tenant,
    login,
    password,
    "ir.model.fields",
    "search_read",
    [[["model", "=", model], ["store", "=", true]]],
    {
      fields: ["name", "field_description", "model", "ttype", "relation"],
      order: "name",
      limit: 2000,
    },
  );
  if (!Array.isArray(result)) {
    throw new HttpError(502, "Odoo tidak mengembalikan metadata field yang valid.");
  }
  return result;
}

async function previewConfiguration(tenant, configuration, login, password) {
  const displayField = configuration.displayField || configuration.fields[0];
  const fieldRecords = await discoverFields(tenant, login, password, configuration.model);
  const available = new Map(fieldRecords.map((field) => [field.name, field]));
  for (const field of configuration.fields) {
    if (!available.has(field)) {
      throw new HttpError(409, `Field ${field} pada model ${configuration.model} tidak lagi tersedia di tenant.`);
    }
  }
  if (
    (displayField && !available.has(displayField)) ||
    (configuration.sortField && !available.has(configuration.sortField))
  ) {
    throw new HttpError(409, "Field judul atau pengurutan tidak lagi tersedia pada model tenant.");
  }
  for (const filter of configuration.filters || []) {
    if (!available.has(filter.field)) {
      throw new HttpError(409, `Field filter ${filter.field} tidak ditemukan pada model tenant.`);
    }
  }
  for (const relation of configuration.relations || []) {
    const source = available.get(relation.field);
    if (!source || source.relation !== relation.model) {
      throw new HttpError(409, `Relasi ${relation.field} tidak lagi sesuai dengan model tenant.`);
    }
    const targetFields = new Set(
      (await discoverFields(tenant, login, password, relation.model)).map((field) => field.name),
    );
    if (relation.fields.some((field) => !targetFields.has(field))) {
      throw new HttpError(409, `Field tujuan pada relasi ${relation.field} tidak lagi tersedia di tenant.`);
    }
  }

  const domain = (configuration.filters || []).map((filter) => {
    const isListOperator = filter.operator === "in" || filter.operator === "not in";
    let value = filter.value;
    if (isListOperator) {
      try {
        value = JSON.parse(value);
      } catch {
        value = value.split(",").map((part) => part.trim()).filter(Boolean);
      }
      if (!Array.isArray(value) || !value.length) {
        throw new HttpError(400, `Filter ${filter.field} dengan operator ${filter.operator} memerlukan daftar nilai.`);
      }
    }
    const field = available.get(filter.field);
    let values = Array.isArray(value) ? value : [value];
    if (field.ttype === "integer" || field.ttype === "many2one") {
      values = values.map((item) => {
        const number = Number(item);
        if (!Number.isInteger(number)) {
          throw new HttpError(400, `Filter ${filter.field} harus berisi bilangan bulat.`);
        }
        return number;
      });
    } else if (["float", "monetary"].includes(field.ttype)) {
      values = values.map((item) => {
        const number = Number(item);
        if (!Number.isFinite(number)) {
          throw new HttpError(400, `Filter ${filter.field} harus berisi angka.`);
        }
        return number;
      });
    } else if (field.ttype === "boolean") {
      values = values.map((item) => {
        if (![true, false, "true", "false"].includes(item)) {
          throw new HttpError(400, `Filter ${filter.field} harus bernilai true atau false.`);
        }
        return item === true || item === "true";
      });
    }
    value = isListOperator ? values : values[0];
    return [filter.field, filter.operator, value];
  });
  const order = configuration.sortField
    ? `${configuration.sortField} ${configuration.order}`
    : "id desc";
  const requestedFields = [...new Set([
    "id",
    ...configuration.fields,
    ...(configuration.relations || []).map((relation) => relation.field),
  ])];
  const rows = await authenticatedOdooCall(
    tenant,
    login,
    password,
    configuration.model,
    "search_read",
    [domain],
    {
      fields: requestedFields,
      order,
      limit: configuration.limit || 50,
    },
  );
  if (!Array.isArray(rows)) {
    throw new HttpError(502, "Odoo tidak mengembalikan data menu dengan format yang valid.");
  }

  const relatedFields = {};
  for (const relation of configuration.relations || []) {
    const source = available.get(relation.field);
    const ids = new Set();
    for (const row of rows) {
      const value = row[relation.field];
      if (source.ttype === "many2one" && Array.isArray(value) && Number.isInteger(value[0])) {
        ids.add(value[0]);
      } else if (Array.isArray(value)) {
        for (const item of value) if (Number.isInteger(item)) ids.add(item);
      }
    }
    const relatedRows = ids.size
      ? await authenticatedOdooCall(
        tenant,
        login,
        password,
        relation.model,
        "search_read",
        [[["id", "in", [...ids]]]],
        {
          fields: [...new Set(["id", ...relation.fields])],
          limit: 1000,
        },
      )
      : [];
    if (!Array.isArray(relatedRows)) {
      throw new HttpError(502, `Odoo tidak mengembalikan data relasi ${relation.model} yang valid.`);
    }
    const byId = new Map(relatedRows.map((record) => [record.id, record]));
    relatedFields[relation.field] = {
      model: relation.model,
      fields: relation.fields,
    };
    for (const row of rows) {
      const value = row[relation.field];
      const relatedIds = source.ttype === "many2one" && Array.isArray(value)
        ? (Number.isInteger(value[0]) ? [value[0]] : [])
        : Array.isArray(value)
          ? value.filter(Number.isInteger)
          : [];
      row[`__relation_${relation.field}`] = relatedIds
        .map((id) => byId.get(id))
        .filter(Boolean);
    }
  }
  return {
    menu: configuration.name,
    model: configuration.model,
    fields: configuration.fields,
    displayField,
    relations: relatedFields,
    rows,
    count: rows.length,
    limit: configuration.limit || 50,
  };
}

async function serveStatic(pathname, response) {
  const distRoot = resolve(ROOT, "dist");
  const decoded = decodeURIComponent(pathname);
  const requested = decoded === "/" ? "index.html" : decoded.slice(1);
  const candidate = resolve(distRoot, normalize(requested));
  if (candidate !== distRoot && !candidate.startsWith(`${distRoot}${sep}`)) {
    throw new HttpError(403, "Path tidak diizinkan.");
  }
  let file = candidate;
  try {
    const content = await readFile(file);
    response.writeHead(200, {
      "Cache-Control": file.endsWith("index.html") ? "no-cache" : "public, max-age=3600",
      "Content-Length": content.length,
      "Content-Type": contentTypes[extname(file)] || "application/octet-stream",
      "X-Content-Type-Options": "nosniff",
    });
    response.end(content);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    file = join(distRoot, "index.html");
    const content = await readFile(file);
    response.writeHead(200, {
      "Cache-Control": "no-cache",
      "Content-Length": content.length,
      "Content-Type": "text/html; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    });
    response.end(content);
  }
}

async function handleApi(request, response, url) {
  if (request.method === "GET" && url.pathname === "/api/health") {
    return sendJson(response, 200, { ok: true });
  }

  if (request.method === "POST" && url.pathname === "/api/login") {
    if (!ADMIN_PASSWORD) {
      throw new HttpError(
        503,
        "Atur SCHOOL_ADMIN_PASSWORD sebelum memulai server School Admin.",
      );
    }
    const address = request.socket.remoteAddress || "unknown";
    const attempts = loginAttempts.get(address) || { count: 0, blockedUntil: 0 };
    if (attempts.blockedUntil > Date.now()) {
      throw new HttpError(429, "Terlalu banyak percobaan login. Coba lagi beberapa menit.");
    }
    const body = await readBody(request);
    const valid =
      typeof body.password === "string" &&
      constantTimeMatches(body.password, ADMIN_PASSWORD);
    if (!valid) {
      attempts.count += 1;
      if (attempts.count >= 8) {
        attempts.count = 0;
        attempts.blockedUntil = Date.now() + 5 * 60 * 1000;
      }
      loginAttempts.set(address, attempts);
      throw new HttpError(401, "Password admin tidak benar.");
    }
    loginAttempts.delete(address);
    const token = randomBytes(32).toString("base64url");
    sessions.set(token, Date.now() + SESSION_TTL_MS);
    return sendJson(response, 200, { token });
  }

  requireSession(request);
  const body = ["POST", "PUT", "PATCH", "DELETE"].includes(request.method)
    ? await readBody(request)
    : {};
  const store = await readStore();

  if (request.method === "GET" && url.pathname === "/api/tenants") {
    return sendJson(response, 200, {
      tenants: store.tenants.map((tenant) => ({
        ...tenant,
        active: tenant.active !== false,
      })),
    });
  }

  if (request.method === "POST" && url.pathname === "/api/tenants") {
    const schoolCode = requireString(body.schoolCode, "Kode sekolah", 50).toUpperCase();
    if (store.tenants.some((tenant) => tenant.schoolCode === schoolCode)) {
      throw new HttpError(409, "Kode sekolah sudah digunakan.");
    }
    const tenant = {
      id: randomUUID(),
      schoolCode,
      name: requireString(body.name, "Nama sekolah", 150),
      url: normalizeTenantUrl(body.url),
      database: requireString(body.database, "Database Odoo", 120),
      active: body.active !== false,
      createdAt: new Date().toISOString(),
    };
    store.tenants.push(tenant);
    await writeStore(store);
    return sendJson(response, 201, { tenant });
  }

  const connectionRoute = url.pathname.match(/^\/api\/tenants\/([a-f0-9-]+)\/connection\/check$/i);
  if (connectionRoute && request.method === "POST") {
    const tenant = store.tenants.find((item) => item.id === connectionRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    return sendJson(response, 200, { connection: await checkOdooConnection(tenant) });
  }

  if (request.method === "POST" && url.pathname === "/api/tenants/connections/check") {
    const connections = await Promise.all(store.tenants.map(checkOdooConnection));
    return sendJson(response, 200, { connections });
  }

  const tenantRoute = url.pathname.match(/^\/api\/tenants\/([a-f0-9-]+)$/i);
  if (tenantRoute && ["PUT", "PATCH"].includes(request.method)) {
    const tenant = store.tenants.find((item) => item.id === tenantRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    if (request.method === "PATCH" && body.active !== undefined) {
      tenant.active = body.active === true;
      await writeStore(store);
      return sendJson(response, 200, { tenant });
    }
    const code = requireString(body.schoolCode, "Kode sekolah", 50).toUpperCase();
    if (store.tenants.some((item) => item.id !== tenant.id && item.schoolCode === code)) {
      throw new HttpError(409, "Kode sekolah sudah digunakan.");
    }
    tenant.schoolCode = code;
    tenant.name = requireString(body.name, "Nama sekolah", 150);
    tenant.url = normalizeTenantUrl(body.url);
    tenant.database = requireString(body.database, "Database Odoo", 120);
    tenant.active = body.active !== false;
    await writeStore(store);
    return sendJson(response, 200, { tenant });
  }

  if (tenantRoute && request.method === "DELETE") {
    const tenantIndex = store.tenants.findIndex((item) => item.id === tenantRoute[1]);
    if (tenantIndex < 0) throw new HttpError(404, "Tenant tidak ditemukan.");
    store.tenants.splice(tenantIndex, 1);
    store.configurations = store.configurations.filter(
      (configuration) => configuration.tenantId !== tenantRoute[1],
    );
    await writeStore(store);
    return sendJson(response, 200, { ok: true });
  }

  const tenantModelsRoute = url.pathname.match(/^\/api\/tenants\/([a-f0-9-]+)\/models$/i);
  if (tenantModelsRoute && request.method === "POST") {
    const tenant = store.tenants.find((item) => item.id === tenantModelsRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    const login = requireString(body.login, "Login Odoo tenant", 200);
    const password = requireString(body.password, "Password Odoo tenant", 1000);
    return sendJson(response, 200, {
      models: await discoverModels(tenant, login, password),
    });
  }

  const tenantFieldsRoute = url.pathname.match(/^\/api\/tenants\/([a-f0-9-]+)\/fields$/i);
  if (tenantFieldsRoute && request.method === "POST") {
    const tenant = store.tenants.find((item) => item.id === tenantFieldsRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    const login = requireString(body.login, "Login Odoo tenant", 200);
    const password = requireString(body.password, "Password Odoo tenant", 1000);
    const model = requireString(body.model, "Model Odoo", 200);
    return sendJson(response, 200, {
      fields: await discoverFields(tenant, login, password, model),
    });
  }

  const previewRoute = url.pathname.match(
    /^\/api\/tenants\/([a-f0-9-]+)\/configurations\/([a-f0-9-]+)\/preview$/i,
  );
  if (previewRoute && request.method === "POST") {
    const tenant = store.tenants.find((item) => item.id === previewRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    const configuration = store.configurations.find(
      (item) => item.id === previewRoute[2] && item.tenantId === tenant.id,
    );
    if (!configuration) throw new HttpError(404, "Menu fitur tidak ditemukan.");
    const login = requireString(body.login, "Login Odoo tenant", 200);
    const password = requireString(body.password, "Password Odoo tenant", 1000);
    return sendJson(response, 200, {
      preview: await previewConfiguration(tenant, configuration, login, password),
    });
  }

  const configsRoute = url.pathname.match(/^\/api\/tenants\/([a-f0-9-]+)\/configurations$/i);
  if (configsRoute) {
    const tenant = store.tenants.find((item) => item.id === configsRoute[1]);
    if (!tenant) throw new HttpError(404, "Tenant tidak ditemukan.");
    if (request.method === "GET") {
      return sendJson(response, 200, {
        configurations: store.configurations.filter(
          (configuration) => configuration.tenantId === tenant.id,
        ),
      });
    }
    if (request.method === "POST") {
      const configuration = normalizeConfiguration(body);
      if (body.id) {
        const existing = store.configurations.find(
          (item) => item.id === body.id && item.tenantId === tenant.id,
        );
        if (!existing) throw new HttpError(404, "Konfigurasi fitur tidak ditemukan.");
        Object.assign(existing, configuration, { updatedAt: new Date().toISOString() });
        await writeStore(store);
        return sendJson(response, 200, { configuration: existing });
      }
      const record = {
        id: randomUUID(),
        tenantId: tenant.id,
        ...configuration,
        createdAt: new Date().toISOString(),
      };
      store.configurations.push(record);
      await writeStore(store);
      return sendJson(response, 201, { configuration: record });
    }
  }

  const configRoute = url.pathname.match(
    /^\/api\/tenants\/([a-f0-9-]+)\/configurations\/([a-f0-9-]+)$/i,
  );
  if (configRoute && request.method === "DELETE") {
    const index = store.configurations.findIndex(
      (item) => item.id === configRoute[2] && item.tenantId === configRoute[1],
    );
    if (index < 0) throw new HttpError(404, "Konfigurasi fitur tidak ditemukan.");
    store.configurations.splice(index, 1);
    await writeStore(store);
    return sendJson(response, 200, { ok: true });
  }

  throw new HttpError(404, "Endpoint tidak ditemukan.");
}

const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url, "http://localhost");
    if (url.pathname.startsWith("/api/")) {
      await handleApi(request, response, url);
      return;
    }
    if (request.method !== "GET" && request.method !== "HEAD") {
      throw new HttpError(405, "Method tidak diizinkan.");
    }
    if (request.method === "HEAD") {
      response.writeHead(200);
      response.end();
      return;
    }
    await serveStatic(url.pathname, response);
  } catch (error) {
    if (!(error instanceof HttpError)) {
      console.error("School Admin request failed:", error.message);
    }
    if (!response.headersSent) {
      sendJson(
        response,
        error instanceof HttpError ? error.status : 500,
        { error: error instanceof HttpError ? error.message : "Terjadi kesalahan internal server." },
      );
    } else {
      response.destroy();
    }
  }
});

server.listen(PORT, HOST, () => {
  console.log(`School Admin server listening on http://${HOST}:${PORT}`);
  console.log(`Configuration storage: ${DATA_FILE}`);
  if (!ADMIN_PASSWORD) {
    console.error("SCHOOL_ADMIN_PASSWORD is not set; login will be unavailable.");
  }
});
