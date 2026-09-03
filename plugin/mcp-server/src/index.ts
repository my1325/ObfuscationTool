#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";
import { z } from "zod";
import { runCli } from "./cli.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PLUGIN_ROOT = resolve(__dirname, "../..");
const REPO_ROOT = resolve(PLUGIN_ROOT, "..");
const EXAMPLE_CONFIG = join(
  REPO_ROOT,
  "ObfuscationTool/SmokeTest/obfuscation.json"
);

const server = new McpServer({
  name: "obfuscation-tool",
  version: "1.0.0",
});

function textResult(text: string, isError = false) {
  return {
    content: [{ type: "text" as const, text }],
    isError,
  };
}

function runInWorkspace(
  args: string[],
  workingDirectory?: string
) {
  const cwd = workingDirectory
    ? resolve(workingDirectory)
    : process.cwd();
  return runCli(args, cwd);
}

server.tool(
  "obfuscate_run",
  "Run Swift/Objective-C obfuscation on a project using a JSON config file. Writes transformed files to the output directory.",
  {
    configPath: z
      .string()
      .describe("Path to obfuscation.json (relative to workingDirectory)"),
    workingDirectory: z
      .string()
      .optional()
      .describe("Project root directory. Defaults to the current workspace."),
  },
  async ({ configPath, workingDirectory }) => {
    const result = runInWorkspace(
      ["run", "-c", configPath],
      workingDirectory
    );

    const output = [result.stdout, result.stderr].filter(Boolean).join("\n");
    if (result.exitCode !== 0) {
      return textResult(output || "obfuscate_run failed", true);
    }
    return textResult(output || "run success");
  }
);

server.tool(
  "obfuscate_scan_prefixes",
  "Scan Swift source files for symbol prefixes not covered by the config rules. Returns JSON with prefix hits grouped by symbol kind.",
  {
    configPath: z
      .string()
      .describe("Path to obfuscation.json (relative to workingDirectory)"),
    workingDirectory: z
      .string()
      .optional()
      .describe("Project root directory. Defaults to the current workspace."),
  },
  async ({ configPath, workingDirectory }) => {
    const result = runInWorkspace(
      ["scan", "-c", configPath],
      workingDirectory
    );

    const output = result.stdout.trim();
    if (result.exitCode !== 0) {
      const detail = [output, result.stderr].filter(Boolean).join("\n");
      return textResult(detail || "obfuscate_scan_prefixes failed", true);
    }
    return textResult(output);
  }
);

server.tool(
  "obfuscate_example_config",
  "Return the bundled SmokeTest obfuscation.json example for Swift/OC projects.",
  {},
  async () => {
    const example = readFileSync(EXAMPLE_CONFIG, "utf8");
    return textResult(example);
  }
);

server.tool(
  "obfuscate_validate_config",
  "Validate an obfuscation.json file without writing output files.",
  {
    configPath: z
      .string()
      .describe("Path to obfuscation.json (relative to workingDirectory)"),
    workingDirectory: z
      .string()
      .optional()
      .describe("Project root directory. Defaults to the current workspace."),
  },
  async ({ configPath, workingDirectory }) => {
    const result = runInWorkspace(
      ["validate", "-c", configPath],
      workingDirectory
    );

    const output = [result.stdout, result.stderr].filter(Boolean).join("\n");
    if (result.exitCode !== 0) {
      return textResult(output || "obfuscate_validate_config failed", true);
    }
    return textResult(output || "config is valid");
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
