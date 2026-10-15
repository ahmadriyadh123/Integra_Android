import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const fixturePath = fileURLToPath(
  new URL("./fixtures/odoo-tenant-directory.json", import.meta.url),
);

test("npm fixture uses the school admin tenant directory schema", async () => {
  const directory = JSON.parse(await readFile(fixturePath, "utf8"));

  assert.equal(directory.version, 1);
  assert.ok(Array.isArray(directory.tenants));
  assert.ok(Array.isArray(directory.configurations));
  assert.ok(directory.tenants.length > 0);

  const codes = new Set();
  for (const tenant of directory.tenants) {
    assert.match(tenant.id, /^[0-9a-f-]{36}$/i);
    assert.match(tenant.schoolCode, /^[A-Z0-9-]+$/);
    assert.ok(tenant.name);
    assert.match(tenant.url, /^https:\/\//);
    assert.match(tenant.database, /^[a-zA-Z0-9_]+$/);
    assert.equal(tenant.active, true);
    assert.equal(codes.has(tenant.schoolCode), false);
    codes.add(tenant.schoolCode);
  }
});
