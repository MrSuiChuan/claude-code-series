import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const SUPPORTED_EXTENSIONS = new Set([
  ".ts",
  ".tsx",
  ".js",
  ".jsx",
  ".json",
  ".md",
  ".css",
]);

function readHookPayload() {
  try {
    return JSON.parse(fs.readFileSync(0, "utf8"));
  } catch {
    return null;
  }
}

function isWithinProject(filePath, projectDir) {
  const relativePath = path.relative(projectDir, filePath);
  return relativePath && !relativePath.startsWith("..") && !path.isAbsolute(relativePath);
}

function runFormatter(filePath, cwd) {
  const candidates = process.platform === "win32"
    ? [["pnpm.cmd", ["exec", "prettier", "--write", filePath]], ["npx.cmd", ["prettier", "--write", filePath]]]
    : [["pnpm", ["exec", "prettier", "--write", filePath]], ["npx", ["prettier", "--write", filePath]]];

  for (const [command, args] of candidates) {
    const result = spawnSync(command, args, {
      cwd,
      stdio: "ignore",
      shell: false,
    });

    if (!result.error) {
      return result.status ?? 0;
    }
  }

  return 0;
}

const payload = readHookPayload();
const targetPath = payload?.tool_input?.file_path;
const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

if (!targetPath || !fs.existsSync(targetPath)) {
  process.exit(0);
}

if (!SUPPORTED_EXTENSIONS.has(path.extname(targetPath))) {
  process.exit(0);
}

if (!isWithinProject(targetPath, projectDir)) {
  process.exit(0);
}

runFormatter(targetPath, projectDir);
process.exit(0);
