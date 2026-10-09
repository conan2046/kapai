import fs from "node:fs/promises";
import path from "node:path";
import { execFileSync } from "node:child_process";

const repoRoot = path.resolve(new URL("../..", import.meta.url).pathname.replace(/^\/(.:)/, "$1"));
const exportRoot = path.join(repoRoot, ".local", "unity-validation", "fish-g0", "exporter");
const serverConfigRoot = path.join(repoRoot, "server", "config", "json");
const unityConfigRoot = path.join(repoRoot, "unityclient", "Assets", "ProjectX", "Resources", "Configs");
const fishItemIds = new Set([580, 581, 582, 10580, 10581, 10582, 10583, 10584, 10585, 10586]);
const restoreCleanHeadOrder = process.argv.includes("--restore-clean-head-order");

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  try {
    return JSON.parse(raw);
  } catch (error) {
    // The legacy exporter preserves historical array cells such as `[29,]`.
    // Normalize only that known trailing-comma form before selecting Fish rows.
    return JSON.parse(raw.replace(/,\s*]/g, "]"));
  }
}

async function writeJson(filePath, value) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, `${JSON.stringify(value)}\n`, "utf8");
}

function readHeadJson(repoRelativePath) {
  const git = "C:\\Program Files\\Git\\cmd\\git.exe";
  return JSON.parse(execFileSync(git, ["show", `HEAD:${repoRelativePath}`], {
    cwd: repoRoot,
    encoding: "utf8",
  }));
}

function mergeById(current, additions, key, accepted, insertBefore) {
  const retained = current.filter((row) => !accepted.has(Number(row[key])));
  const index = retained.findIndex((row) => insertBefore(Number(row[key])));
  if (index < 0) return [...retained, ...additions];
  return [...retained.slice(0, index), ...additions, ...retained.slice(index)];
}

const generatedFunction = await readJson(path.join(exportRoot, "json_client", "function.json"));
const functionAddition = generatedFunction.filter((row) => Number(row.function_id) === 32);
if (functionAddition.length !== 1) throw new Error("Expected exactly one function_id=32 row.");
const currentFunction = restoreCleanHeadOrder
  ? readHeadJson("server/config/json/function.json")
  : await readJson(path.join(serverConfigRoot, "function.json"));
const mergedFunction = mergeById(currentFunction, functionAddition, "function_id", new Set([32]), (id) => id > 32);
await writeJson(path.join(serverConfigRoot, "function.json"), mergedFunction);

const generatedItems = await readJson(path.join(exportRoot, "json_server", "item.json"));
const itemAdditions = generatedItems.filter((row) => fishItemIds.has(Number(row.id)));
if (itemAdditions.length !== fishItemIds.size) throw new Error("Expected all ten fish item rows.");
for (const target of [path.join(serverConfigRoot, "item.json"), path.join(unityConfigRoot, "item.json")]) {
  const relativeTarget = path.relative(repoRoot, target).replaceAll("\\", "/");
  const currentItems = restoreCleanHeadOrder ? readHeadJson(relativeTarget) : await readJson(target);
  await writeJson(target, mergeById(currentItems, itemAdditions, "id", fishItemIds, (id) => id >= 610 && id < 60000));
}

for (const fileName of ["fish_settings.json", "fish_reward.json"]) {
  const serverValue = await readJson(path.join(exportRoot, "json_server", fileName));
  const clientValue = await readJson(path.join(exportRoot, "json_client", fileName));
  await writeJson(path.join(serverConfigRoot, fileName), serverValue);
  await writeJson(path.join(unityConfigRoot, fileName), clientValue);
}

const serverPosition = await readJson(path.join(exportRoot, "json_server", "fish_position.json"));
const clientPosition = await readJson(path.join(exportRoot, "json_client", "fish_position.json"));
await writeJson(path.join(serverConfigRoot, "fish_position.json"), serverPosition);
await writeJson(path.join(unityConfigRoot, "fish_position.json"), clientPosition);

console.log(JSON.stringify({
  functionId: functionAddition[0].function_id,
  fishItems: itemAdditions.map((row) => row.id),
  serverConfigs: ["fish_settings.json", "fish_reward.json", "fish_position.json"],
  unityConfigs: ["fish_settings.json", "fish_reward.json", "fish_position.json", "item.json"],
}, null, 2));
