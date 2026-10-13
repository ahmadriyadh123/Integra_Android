import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const root = fileURLToPath(new URL(".", import.meta.url));
const apiPort = process.env.SCHOOL_ADMIN_API_PORT || "4174";
const environment = { ...process.env, PORT: apiPort, SCHOOL_ADMIN_API_PORT: apiPort };
const children = [
  spawn(process.execPath, [join(root, "server.js")], {
    cwd: root,
    env: environment,
    stdio: "inherit",
  }),
  spawn(process.execPath, [join(root, "node_modules/vite/bin/vite.js")], {
    cwd: root,
    env: environment,
    stdio: "inherit",
  }),
];

let stopping = false;
function stop(exitCode = 0) {
  if (stopping) return;
  stopping = true;
  for (const child of children) {
    if (child.exitCode === null) child.kill();
  }
  process.exitCode = exitCode;
}

for (const child of children) {
  child.on("error", (error) => {
    console.error("Unable to start development process:", error.message);
    stop(1);
  });
  child.on("exit", (code) => {
    if (!stopping) stop(code || 0);
  });
}

process.on("SIGINT", () => stop(0));
process.on("SIGTERM", () => stop(0));
