import fs from "node:fs";
import path from "node:path";

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return {};
  }
}

function mergeEventConfig(baseConfig, localConfig, eventName) {
  return {
    ...(baseConfig.events?.[eventName] ?? {}),
    ...(localConfig.events?.[eventName] ?? {}),
  };
}

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const configDir = path.join(projectDir, ".claude", "hooks", "config");
const baseConfig = readJsonIfExists(path.join(configDir, "hooks-config.json"));
const localConfig = readJsonIfExists(path.join(configDir, "hooks-config.local.json"));
const eventName = process.argv[2];

if (!eventName) {
  process.exit(0);
}

const globallyEnabled = (localConfig.enabled ?? baseConfig.enabled ?? true) === true;
const eventConfig = mergeEventConfig(baseConfig, localConfig, eventName);
const eventEnabled = (eventConfig.enabled ?? true) === true;

if (!globallyEnabled || !eventEnabled) {
  process.exit(0);
}

process.exit(0);
