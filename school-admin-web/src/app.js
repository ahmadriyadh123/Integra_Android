const state = {
  token: "",
  tenants: [],
  selectedTenantId: "",
  editingTenantId: "",
  configurations: [],
  editingConfiguration: null,
  models: [],
  fields: [],
  relationFields: new Map(),
  selectedFieldNames: new Set(),
  selectedRelations: new Map(),
  activeModel: "",
  metadataRequest: 0,
  toastTimer: null,
};

const $ = (id) => document.getElementById(id);

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[character]);
}

async function api(path, options = {}) {
  const headers = new Headers(options.headers || {});
  headers.set("Accept", "application/json");
  if (state.token) headers.set("Authorization", `Bearer ${state.token}`);
  if (options.body !== undefined) headers.set("Content-Type", "application/json");
  let response;
  try {
    response = await fetch(path, {
      ...options,
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      cache: "no-store",
    });
  } catch {
    throw new Error("School Admin API tidak dapat dihubungi. Pastikan server web berjalan.");
  }
  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new Error(`Server mengembalikan respons yang tidak valid (HTTP ${response.status}).`);
  }
  if (response.status === 401 && state.token) {
    logout("Sesi admin berakhir. Silakan masuk kembali.");
    throw new Error(payload.error || "Sesi admin berakhir.");
  }
  if (!response.ok) throw new Error(payload.error || `Request gagal (HTTP ${response.status}).`);
  return payload;
}

function showToast(message, isError = false) {
  const toast = $("toast");
  toast.textContent = message;
  toast.classList.toggle("error", isError);
  toast.classList.remove("hidden");
  clearTimeout(state.toastTimer);
  state.toastTimer = setTimeout(() => toast.classList.add("hidden"), 4200);
}

function setLoginError(message) {
  $("login-error").textContent = message;
}

function showApp() {
  $("login-screen").classList.add("hidden");
  $("app").classList.remove("hidden");
}

function logout(message = "") {
  state.token = "";
  state.tenants = [];
  state.configurations = [];
  state.selectedTenantId = "";
  $("admin-password").value = "";
  $("configuration-panel").classList.add("hidden");
  $("app").classList.add("hidden");
  $("login-screen").classList.remove("hidden");
  $("login-error").textContent = message;
}

function resetTenantForm() {
  state.editingTenantId = "";
  $("tenant-form").reset();
  $("save-tenant-button").textContent = "Tambah sekolah";
}

async function refreshTenants() {
  const data = await api("/api/tenants");
  state.tenants = data.tenants;
  renderTenants();
}

function renderTenants() {
  const search = $("tenant-search").value.trim().toLowerCase();
  const tenants = state.tenants.filter((tenant) =>
    `${tenant.schoolCode} ${tenant.name} ${tenant.url} ${tenant.database}`
      .toLowerCase()
      .includes(search),
  );
  $("tenant-count").textContent = `Sekolah (${state.tenants.length})`;
  const target = $("tenant-list");
  if (!tenants.length) {
    target.innerHTML = `<div class="empty">${state.tenants.length ? "Tidak ada sekolah yang cocok." : "Belum ada tenant. Tambahkan URL dan database Odoo tenant di atas."}</div>`;
    return;
  }
  target.innerHTML = tenants.map((tenant) => `
    <article class="tenant-row ${tenant.id === state.selectedTenantId ? "selected" : ""}" data-tenant-id="${escapeHtml(tenant.id)}">
      <div class="tenant-info" data-action="select">
        <div class="tenant-title">${escapeHtml(tenant.name)} <span class="code">${escapeHtml(tenant.schoolCode)}</span></div>
        <div class="tenant-subtitle">${escapeHtml(tenant.url)} · ${escapeHtml(tenant.database)}</div>
      </div>
      <div class="tenant-actions">
        <button class="secondary-button small-button" type="button" data-action="edit">Ubah</button>
        <button class="danger-button small-button" type="button" data-action="delete">Hapus</button>
      </div>
    </article>`).join("");
}

async function selectTenant(tenantId) {
  state.selectedTenantId = tenantId;
  const tenant = state.tenants.find((item) => item.id === tenantId);
  if (!tenant) return;
  $("selected-tenant-name").textContent = tenant.name;
  $("selected-tenant-code").textContent = tenant.schoolCode;
  $("selected-tenant-database").textContent = `${tenant.url} · database ${tenant.database}`;
  $("configuration-panel").classList.remove("hidden");
  $("configuration-form").classList.add("hidden");
  $("configuration-error").textContent = "";
  $("tenant-error").textContent = "";
  renderTenants();
  await refreshConfigurations();
  $("configuration-panel").scrollIntoView({ behavior: "smooth", block: "start" });
}

async function refreshConfigurations() {
  if (!state.selectedTenantId) return;
  const data = await api(`/api/tenants/${state.selectedTenantId}/configurations`);
  state.configurations = data.configurations;
  renderConfigurations();
}

function renderConfigurations() {
  const list = $("configuration-list");
  $("configuration-count").textContent = `${state.configurations.length} konfigurasi tersimpan di server web.`;
  if (!state.configurations.length) {
    list.innerHTML = '<div class="empty">Belum ada konfigurasi fitur untuk sekolah ini. Klik <strong>+ Fitur</strong> untuk membuat pemetaan.</div>';
    return;
  }
  list.innerHTML = state.configurations.map((configuration) => {
    const fieldChips = configuration.fields.map((field) =>
      `<span class="chip">${escapeHtml(field)}</span>`).join("");
    const filters = (configuration.filters || []).map((filter) =>
      `${filter.field} ${filter.operator} ${filter.value}`).join(" · ");
    const relationCards = configuration.relations.map((relation) => `
      <div style="margin-top:9px"><div class="config-card-meta">Relasi: <span class="code">${escapeHtml(relation.field)}</span> → <span class="code">${escapeHtml(relation.model)}</span></div>
      <div class="chips">${relation.fields.map((field) => `<span class="chip">${escapeHtml(field)}</span>`).join("")}</div></div>`).join("");
    return `<article class="config-card">
      <h3>${escapeHtml(configuration.name)}</h3>
      <p class="config-card-meta">Model utama: <span class="code">${escapeHtml(configuration.model)}</span></p>
      <div class="chips">${fieldChips}</div>
      ${relationCards}
      <p class="config-card-meta">Judul: <span class="code">${escapeHtml(configuration.displayField || configuration.fields[0] || "")}</span>
        · Urutan: <span class="code">${escapeHtml(configuration.sortField ? `${configuration.sortField} ${configuration.order || "asc"}` : "id desc")}</span>
        · Maksimum ${escapeHtml(configuration.limit || 50)} record</p>
      ${filters ? `<p class="config-card-meta">Filter: <span class="code">${escapeHtml(filters)}</span></p>` : ""}
      <div class="config-actions">
        <button class="primary-button small-button" type="button" data-configuration-action="preview" data-configuration-id="${escapeHtml(configuration.id)}">Pratinjau data</button>
        <button class="secondary-button small-button" type="button" data-configuration-action="edit" data-configuration-id="${escapeHtml(configuration.id)}">Ubah</button>
        <button class="danger-button small-button" type="button" data-configuration-action="delete" data-configuration-id="${escapeHtml(configuration.id)}">Hapus</button>
      </div>
      <div class="preview-panel hidden" data-preview-panel="${escapeHtml(configuration.id)}">
        <form class="preview-form" data-preview-form="${escapeHtml(configuration.id)}">
          <div class="inline-fields">
            <div class="field"><label>Login Odoo tenant</label><input name="login" autocomplete="username" required></div>
            <div class="field"><label>Password Odoo tenant</label><input name="password" type="password" autocomplete="current-password" required></div>
          </div>
          <button class="secondary-button small-button" type="submit">Ambil ${escapeHtml(configuration.limit || 50)} data terbaru</button>
          <p class="config-card-meta">Akses data mengikuti hak akun Odoo yang dimasukkan. Kredensial tidak disimpan.</p>
        </form>
        <div data-preview-output="${escapeHtml(configuration.id)}"></div>
      </div>
    </article>`;
  }).join("");
}

function resetConfigurationForm() {
  state.editingConfiguration = null;
  state.models = [];
  state.fields = [];
  state.relationFields.clear();
  state.selectedFieldNames = new Set();
  state.selectedRelations = new Map();
  state.activeModel = "";
  $("configuration-form").reset();
  $("configuration-form").classList.add("hidden");
  $("configuration-form-title").textContent = "Konfigurasi fitur";
  $("model-picker").classList.add("hidden");
  $("field-picker").classList.add("hidden");
  $("relation-picker").classList.add("hidden");
  $("display-settings").classList.add("hidden");
  $("field-list").replaceChildren();
  $("relation-list").replaceChildren();
  $("filter-list").replaceChildren();
  $("model-select").replaceChildren(new Option("Pilih model…", ""));
  $("save-configuration-button").disabled = true;
  $("configuration-error").textContent = "";
}

function beginConfiguration(configuration = null) {
  resetConfigurationForm();
  state.editingConfiguration = configuration;
  $("configuration-form").classList.remove("hidden");
  $("configuration-form-title").textContent = configuration
    ? `Ubah fitur: ${configuration.name}`
    : "Konfigurasi fitur baru";
  if (configuration) {
    $("feature-name").value = configuration.name;
    $("model-select").dataset.initialModel = configuration.model;
    state.selectedFieldNames = new Set(configuration.fields);
    state.selectedRelations = new Map(
      configuration.relations.map((relation) => [relation.field, new Set(relation.fields)]),
    );
    $("display-field").dataset.initialValue = configuration.displayField || configuration.fields[0] || "";
    $("sort-field").dataset.initialValue = configuration.sortField || "";
    $("sort-order").value = configuration.order || "desc";
    $("record-limit").value = configuration.limit || 50;
    for (const filter of configuration.filters || []) addFilterRow(filter);
  } else {
    delete $("model-select").dataset.initialModel;
    delete $("display-field").dataset.initialValue;
    delete $("sort-field").dataset.initialValue;
    $("sort-order").value = "desc";
    $("record-limit").value = 50;
  }
  $("feature-name").focus();
}

function credentialPayload() {
  const login = $("odoo-login").value.trim();
  const password = $("odoo-password").value;
  if (!login || !password) throw new Error("Masukkan login dan password administrator Odoo tenant.");
  return { login, password };
}

function renderModelOptions() {
  const select = $("model-select");
  const current = select.dataset.initialModel || select.value;
  select.replaceChildren(new Option("Pilih model…", ""));
  for (const model of state.models) {
    select.add(new Option(`${model.model} — ${model.name}`, model.model));
  }
  select.value = state.models.some((model) => model.model === current) ? current : "";
  $("model-picker").classList.remove("hidden");
}

async function discoverModels() {
  const button = $("discover-models-button");
  button.disabled = true;
  button.textContent = "Mengambil model…";
  $("configuration-error").textContent = "";
  try {
    const credentials = credentialPayload();
    const data = await api(`/api/tenants/${state.selectedTenantId}/models`, {
      method: "POST",
      body: credentials,
    });
    state.models = data.models;
    renderModelOptions();
    $("model-select").dispatchEvent(new Event("change"));
    showToast(`${state.models.length} model berhasil dimuat dari Odoo tenant.`);
  } catch (error) {
    $("configuration-error").textContent = error.message;
  } finally {
    button.disabled = false;
    button.textContent = "Hubungkan & muat model";
  }
}

function renderFieldOptions() {
  const target = $("field-list");
  if (!state.fields.length) {
    target.innerHTML = '<span class="config-card-meta">Model tidak memiliki field yang dapat dikonfigurasi.</span>';
    return;
  }
  target.innerHTML = state.fields.map((field) => {
    const selected = state.selectedFieldNames.has(field.name) ? "checked" : "";
    const label = field.field_description || field.name;
    const relationInfo = field.relation ? ` → ${field.relation}` : "";
    return `<label class="check-option" title="${escapeHtml(field.name)}${escapeHtml(relationInfo)}">
      <input type="checkbox" data-main-field="${escapeHtml(field.name)}" ${selected}>
      <span>${escapeHtml(label)} <span class="code">${escapeHtml(field.name)}</span>${relationInfo ? `<span class="code">${escapeHtml(relationInfo)}</span>` : ""}</span>
    </label>`;
  }).join("");
}

async function loadFields(modelName) {
  const requestId = ++state.metadataRequest;
  state.fields = [];
  state.relationFields.clear();
  $("field-list").replaceChildren();
  $("relation-list").replaceChildren();
  $("field-picker").classList.remove("hidden");
  $("relation-picker").classList.remove("hidden");
  $("field-list").innerHTML = '<span class="config-card-meta">Memuat field…</span>';
  try {
    const credentials = credentialPayload();
    const data = await api(`/api/tenants/${state.selectedTenantId}/fields`, {
      method: "POST",
      body: { ...credentials, model: modelName },
    });
    if (requestId !== state.metadataRequest) return;
    state.fields = data.fields;
    renderFieldOptions();
    renderConfigurationFieldSettings();
    renderRelationOptions();
    await Promise.all([...state.selectedRelations.keys()].map(loadRelationFields));
    $("save-configuration-button").disabled = false;
  } catch (error) {
    if (requestId !== state.metadataRequest) return;
    $("field-picker").classList.add("hidden");
    $("relation-picker").classList.add("hidden");
    $("configuration-error").textContent = error.message;
    $("save-configuration-button").disabled = true;
  }
}

function getRelationalFields() {
  return state.fields.filter((field) =>
    ["many2one", "one2many", "many2many"].includes(field.ttype) && field.relation,
  );
}

function renderRelationOptions() {
  const relationFields = getRelationalFields();
  const target = $("relation-list");
  if (!relationFields.length) {
    target.innerHTML = '<div class="config-card-meta">Model ini tidak memiliki field relasional.</div>';
    return;
  }
  target.innerHTML = relationFields.map((field) => {
    const selected = state.selectedRelations.has(field.name);
    const targetFields = state.relationFields.get(field.name) || [];
    const selectedTargetFields = state.selectedRelations.get(field.name) || new Set();
    let fieldsHtml = "";
    if (selected && !targetFields.length) {
      fieldsHtml = '<div class="config-card-meta">Memuat field tujuan…</div>';
    } else if (selected) {
      fieldsHtml = `<div class="check-list" style="margin-top:9px">${targetFields.map((targetField) => `
        <label class="check-option">
          <input type="checkbox" data-relation-target="${escapeHtml(field.name)}" data-target-field="${escapeHtml(targetField.name)}" ${selectedTargetFields.has(targetField.name) ? "checked" : ""}>
          <span>${escapeHtml(targetField.field_description || targetField.name)} <span class="code">${escapeHtml(targetField.name)}</span></span>
        </label>`).join("")}</div>`;
    }
    return `<div class="relation-card">
      <label class="check-option"><input type="checkbox" data-relation-source="${escapeHtml(field.name)}" ${selected ? "checked" : ""}><span><strong>${escapeHtml(field.field_description || field.name)}</strong> <span class="code">${escapeHtml(field.name)} → ${escapeHtml(field.relation)}</span></span></label>
      ${fieldsHtml}
    </div>`;
  }).join("");
}

async function loadRelationFields(sourceField) {
  const field = state.fields.find((item) => item.name === sourceField);
  if (!field?.relation) return;
  try {
    const credentials = credentialPayload();
    const data = await api(`/api/tenants/${state.selectedTenantId}/fields`, {
      method: "POST",
      body: { ...credentials, model: field.relation },
    });
    state.relationFields.set(sourceField, data.fields);
    renderRelationOptions();
  } catch (error) {
    state.selectedRelations.delete(sourceField);
    renderRelationOptions();
    $("configuration-error").textContent = error.message;
  }
}

function buildConfigurationPayload() {
  const name = $("feature-name").value.trim();
  const model = $("model-select").value;
  const fields = [...state.selectedFieldNames];
  if (!name || !model || !fields.length) {
    throw new Error("Isi nama fitur, pilih model, dan pilih minimal satu field.");
  }
  const relations = [];
  for (const [fieldName, selectedFields] of state.selectedRelations) {
    if (!selectedFields.size) {
      throw new Error(`Pilih minimal satu field tujuan untuk relasi ${fieldName}.`);
    }
    const relation = state.fields.find((field) => field.name === fieldName);
    if (!relation?.relation) throw new Error(`Metadata relasi ${fieldName} tidak ditemukan.`);
    relations.push({ field: fieldName, model: relation.relation, fields: [...selectedFields] });
  }
  const filters = [...$("filter-list").querySelectorAll("[data-filter-row]")].map((row) => ({
    field: row.querySelector("[data-filter-field]").value,
    operator: row.querySelector("[data-filter-operator]").value,
    value: row.querySelector("[data-filter-value]").value.trim(),
  }));
  return {
    name,
    model,
    fields,
    relations,
    displayField: $("display-field").value,
    sortField: $("sort-field").value,
    order: $("sort-order").value,
    limit: Number($("record-limit").value),
    filters,
  };
}

function renderConfigurationFieldSettings() {
  const fields = state.fields.filter((field) => state.selectedFieldNames.has(field.name));
  $("display-settings").classList.toggle("hidden", fields.length === 0);
  const displayField = $("display-field");
  const sortField = $("sort-field");
  const initialDisplay = displayField.dataset.initialValue || displayField.value;
  const initialSort = sortField.dataset.initialValue ?? sortField.value;
  displayField.replaceChildren(new Option("Pilih field judul…", ""));
  sortField.replaceChildren(new Option("Default: ID terbaru", ""));
  for (const field of fields) {
    const label = `${field.field_description || field.name} (${field.name})`;
    displayField.add(new Option(label, field.name));
    sortField.add(new Option(label, field.name));
  }
  displayField.value = fields.some((field) => field.name === initialDisplay)
    ? initialDisplay
    : fields[0]?.name || "";
  sortField.value = fields.some((field) => field.name === initialSort) ? initialSort : "";
  delete displayField.dataset.initialValue;
  delete sortField.dataset.initialValue;
  for (const row of $("filter-list").querySelectorAll("[data-filter-row]")) {
    const select = row.querySelector("[data-filter-field]");
    const current = select.value || select.dataset.initialValue;
    select.replaceChildren(new Option("Pilih field…", ""));
    for (const field of fields) select.add(new Option(field.name, field.name));
    select.value = fields.some((field) => field.name === current) ? current : "";
    delete select.dataset.initialValue;
  }
}

function addFilterRow(filter = {}) {
  const row = document.createElement("div");
  row.className = "filter-row";
  row.dataset.filterRow = "";
  const field = document.createElement("select");
  field.className = "control";
  field.dataset.filterField = "";
  field.dataset.initialValue = filter.field || "";
  field.required = true;
  field.add(new Option("Pilih field…", ""));
  for (const item of state.fields.filter((candidate) => state.selectedFieldNames.has(candidate.name))) {
    field.add(new Option(item.name, item.name));
  }
  field.value = filter.field || "";
  const operator = document.createElement("select");
  operator.className = "control";
  operator.dataset.filterOperator = "";
  for (const value of ["=", "!=", ">", ">=", "<", "<=", "like", "ilike", "in", "not in"]) {
    operator.add(new Option(value, value));
  }
  operator.value = filter.operator || "=";
  const input = document.createElement("input");
  input.className = "control";
  input.dataset.filterValue = "";
  input.placeholder = "Nilai filter";
  input.maxLength = 500;
  input.value = filter.value || "";
  input.required = true;
  const remove = document.createElement("button");
  remove.type = "button";
  remove.className = "danger-button small-button";
  remove.dataset.removeFilter = "";
  remove.textContent = "Hapus";
  row.append(field, operator, input, remove);
  $("filter-list").append(row);
}

function formatCell(value) {
  if (value === null || value === undefined || value === false) return "";
  if (Array.isArray(value)) {
    if (value.length === 2 && Number.isInteger(value[0])) return String(value[1] ?? "");
    return value.map((item) => String(item)).join(", ");
  }
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}

function renderPreview(preview) {
  const columns = preview.fields;
  const head = columns.map((field) => `<th>${escapeHtml(field)}</th>`).join("");
  const body = preview.rows.map((row) => {
    const cells = columns.map((field) => `<td>${escapeHtml(formatCell(row[field]))}</td>`).join("");
    const related = Object.entries(preview.relations).map(([field, relation]) => {
      const records = row[`__relation_${field}`] || [];
      const values = records.map((record) =>
        relation.fields.map((name) => `${name}: ${formatCell(record[name])}`).join(" · "),
      );
      return `<div><strong>${escapeHtml(field)} → ${escapeHtml(relation.model)}:</strong> ${escapeHtml(values.join(" | ") || "—")}</div>`;
    }).join("");
    return `<tr><td>${escapeHtml(formatCell(row[preview.displayField]))}</td>${cells}${related ? `<td>${related}</td>` : ""}</tr>`;
  }).join("");
  const headers = `<th>Judul</th>${head}${Object.keys(preview.relations).length ? "<th>Detail relasi</th>" : ""}`;
  return `<p class="config-card-meta">${preview.count} record ditampilkan · model <span class="code">${escapeHtml(preview.model)}</span></p>
    ${preview.count
      ? `<div class="table-scroll"><table class="data-table"><thead><tr>${headers}</tr></thead><tbody>${body}</tbody></table></div>`
      : '<div class="empty">Tidak ada record yang cocok dengan filter ini.</div>'}`;
}

async function saveConfiguration(event) {
  event.preventDefault();
  try {
    const payload = buildConfigurationPayload();
    if (state.editingConfiguration) payload.id = state.editingConfiguration.id;
    await api(`/api/tenants/${state.selectedTenantId}/configurations`, {
      method: "POST",
      body: payload,
    });
    resetConfigurationForm();
    await refreshConfigurations();
    $("odoo-password").value = "";
    showToast("Konfigurasi fitur tersimpan di server School Admin.");
  } catch (error) {
    $("configuration-error").textContent = error.message;
  }
}

$("login-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = $("login-button");
  setLoginError("");
  button.disabled = true;
  button.textContent = "Memeriksa…";
  try {
    const response = await api("/api/login", {
      method: "POST",
      body: { password: $("admin-password").value },
    });
    state.token = response.token;
    $("admin-password").value = "";
    showApp();
    await refreshTenants();
  } catch (error) {
    setLoginError(error.message);
  } finally {
    button.disabled = false;
    button.innerHTML = 'Masuk <span>→</span>';
  }
});

$("logout-button").addEventListener("click", () => logout());
$("tenant-search").addEventListener("input", renderTenants);
$("clear-selection-button").addEventListener("click", () => {
  state.selectedTenantId = "";
  $("configuration-panel").classList.add("hidden");
  renderTenants();
});
$("new-configuration-button").addEventListener("click", () => beginConfiguration());
$("cancel-configuration-button").addEventListener("click", resetConfigurationForm);
$("configuration-form").addEventListener("submit", saveConfiguration);
$("discover-models-button").addEventListener("click", discoverModels);
$("add-filter-button").addEventListener("click", () => addFilterRow());
$("filter-list").addEventListener("click", (event) => {
  if (event.target.closest("[data-remove-filter]")) event.target.closest("[data-filter-row]").remove();
});

$("model-select").addEventListener("change", async () => {
  const model = $("model-select").value;
  if (!model) {
    $("field-picker").classList.add("hidden");
    $("relation-picker").classList.add("hidden");
    $("display-settings").classList.add("hidden");
    $("save-configuration-button").disabled = true;
    return;
  }
  if (state.activeModel && state.activeModel !== model) {
    state.selectedFieldNames.clear();
    state.selectedRelations.clear();
    state.relationFields.clear();
    $("filter-list").replaceChildren();
  }
  state.activeModel = model;
  await loadFields(model);
});

$("field-list").addEventListener("change", (event) => {
  const fieldName = event.target.dataset.mainField;
  if (!fieldName) return;
  if (event.target.checked) state.selectedFieldNames.add(fieldName);
  else state.selectedFieldNames.delete(fieldName);
  renderConfigurationFieldSettings();
});

$("relation-list").addEventListener("change", async (event) => {
  const sourceField = event.target.dataset.relationSource;
  if (sourceField) {
    if (event.target.checked) {
      state.selectedRelations.set(sourceField, new Set());
      renderRelationOptions();
      await loadRelationFields(sourceField);
    } else {
      state.selectedRelations.delete(sourceField);
      renderRelationOptions();
    }
    return;
  }
  const targetName = event.target.dataset.relationTarget;
  const targetField = event.target.dataset.targetField;
  if (!targetName || !targetField) return;
  const selected = state.selectedRelations.get(targetName);
  if (!selected) return;
  if (event.target.checked) selected.add(targetField);
  else selected.delete(targetField);
});

$("tenant-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  $("tenant-error").textContent = "";
  const button = $("save-tenant-button");
  button.disabled = true;
  try {
    const payload = {
      schoolCode: $("school-code").value,
      name: $("school-name").value,
      url: $("school-url").value,
      database: $("school-database").value,
    };
    const path = state.editingTenantId
      ? `/api/tenants/${state.editingTenantId}`
      : "/api/tenants";
    await api(path, {
      method: state.editingTenantId ? "PUT" : "POST",
      body: payload,
    });
    resetTenantForm();
    await refreshTenants();
    showToast("Data tenant tersimpan di server web.");
  } catch (error) {
    $("tenant-error").textContent = error.message;
  } finally {
    button.disabled = false;
  }
});

$("tenant-list").addEventListener("click", async (event) => {
  const row = event.target.closest("[data-tenant-id]");
  if (!row) return;
  const tenant = state.tenants.find((item) => item.id === row.dataset.tenantId);
  if (!tenant) return;
  const action = event.target.closest("[data-action]")?.dataset.action;
  try {
    if (action === "edit") {
      state.editingTenantId = tenant.id;
      $("school-code").value = tenant.schoolCode;
      $("school-name").value = tenant.name;
      $("school-url").value = tenant.url;
      $("school-database").value = tenant.database;
      $("save-tenant-button").textContent = "Simpan perubahan";
      $("school-code").focus();
    } else if (action === "delete") {
      if (!window.confirm(`Hapus ${tenant.name} dan seluruh konfigurasi fiturnya?`)) return;
      await api(`/api/tenants/${tenant.id}`, { method: "DELETE" });
      if (state.selectedTenantId === tenant.id) {
        state.selectedTenantId = "";
        $("configuration-panel").classList.add("hidden");
      }
      await refreshTenants();
      showToast(`Tenant ${tenant.name} dan konfigurasinya dihapus.`);
    } else {
      await selectTenant(tenant.id);
    }
  } catch (error) {
    $("tenant-error").textContent = error.message;
  }
});

$("configuration-list").addEventListener("click", async (event) => {
  const button = event.target.closest("[data-configuration-action]");
  if (!button) return;
  const configuration = state.configurations.find(
    (item) => item.id === button.dataset.configurationId,
  );
  if (!configuration) return;
  try {
    if (button.dataset.configurationAction === "preview") {
      const panel = $("configuration-panel").querySelector(
        `[data-preview-panel="${CSS.escape(configuration.id)}"]`,
      );
      panel.classList.toggle("hidden");
      if (!panel.classList.contains("hidden")) panel.querySelector('[name="login"]').focus();
    } else if (button.dataset.configurationAction === "edit") {
      beginConfiguration(configuration);
    } else if (window.confirm(`Hapus konfigurasi ${configuration.name}?`)) {
      await api(
        `/api/tenants/${state.selectedTenantId}/configurations/${configuration.id}`,
        { method: "DELETE" },
      );
      await refreshConfigurations();
      showToast(`Konfigurasi ${configuration.name} dihapus.`);
    }
  } catch (error) {
    showToast(error.message, true);
  }
});

$("configuration-list").addEventListener("submit", async (event) => {
  const form = event.target.closest("[data-preview-form]");
  if (!form) return;
  event.preventDefault();
  const configurationId = form.dataset.previewForm;
  const output = $("configuration-list").querySelector(
    `[data-preview-output="${CSS.escape(configurationId)}"]`,
  );
  const fields = new FormData(form);
  const credentials = {
    login: String(fields.get("login") || "").trim(),
    password: String(fields.get("password") || ""),
  };
  const button = form.querySelector('button[type="submit"]');
  button.disabled = true;
  button.textContent = "Mengambil data…";
  output.innerHTML = '<p class="config-card-meta">Mengambil data dari Odoo tenant…</p>';
  try {
    const data = await api(
      `/api/tenants/${state.selectedTenantId}/configurations/${configurationId}/preview`,
      { method: "POST", body: credentials },
    );
    output.innerHTML = renderPreview(data.preview);
  } catch (error) {
    output.innerHTML = `<p class="error" role="alert">${escapeHtml(error.message)}</p>`;
  } finally {
    form.querySelector('[name="password"]').value = "";
    button.disabled = false;
    button.textContent = `Ambil ${escapeHtml(configuration.limit || 50)} data terbaru`;
  }
});
