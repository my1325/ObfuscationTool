import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = resolve(__dirname, "../..");
const REPO_ROOT = resolve(PLUGIN_ROOT, "..");

const CANDIDATE_PATHS = [
  process.env.OBFUSCATION_CLI,
  join(REPO_ROOT, ".build/obfuscation-cli/Release/Command"),
  join(REPO_ROOT, ".build/obfuscation-cli/Debug/Command"),
  join(
    REPO_ROOT,
    "ObfuscationTool/DerivedData/Build/Products/Release/Command"
  ),
  join(
    REPO_ROOT,
    "ObfuscationTool/DerivedData/Build/Products/Debug/Command"
  ),
].filter((p): p is string => Boolean(p));

export function resolveCliBinary(): string {
  for (const candidate of CANDIDATE_PATHS) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  return buildCli();
}

function buildCli(): string {
  const outputDir = join(REPO_ROOT, ".build/obfuscation-cli");
  const binaryPath = join(outputDir, "Release/Command");

  const result = spawnSync(
    "xcodebuild",
    [
      "-project",
      join(REPO_ROOT, "ObfuscationTool/ObfuscationTool.xcodeproj"),
      "-scheme",
      "Commond",
      "-configuration",
      "Release",
      "-derivedDataPath",
      join(REPO_ROOT, "ObfuscationTool/DerivedData"),
      "SYMROOT=" + outputDir,
      "ONLY_ACTIVE_ARCH=NO",
      "build",
    ],
    { cwd: REPO_ROOT, encoding: "utf8" }
  );

  if (result.status !== 0) {
    const detail = [result.stdout, result.stderr].filter(Boolean).join("\n");
    throw new Error(`Failed to build ObfuscationTool CLI:\n${detail}`);
  }

  if (!existsSync(binaryPath)) {
    throw new Error(
      `CLI binary not found after build. Set OBFUSCATION_CLI to the Command executable path.`
    );
  }

  return binaryPath;
}

export interface CliResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export function runCli(
  args: string[],
  cwd: string
): CliResult {
  const binary = resolveCliBinary();
  const result = spawnSync(binary, args, {
    cwd,
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });

  return {
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    exitCode: result.status ?? 1,
  };
}
