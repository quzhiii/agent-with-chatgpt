#!/usr/bin/env node
/**
 * Count Markdown files and total lines under docs/.
 * Usage: node scripts/repo-stats.mjs
 */
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const docsDir = join(dirname(fileURLToPath(import.meta.url)), "..", "docs");

function* markdownFiles(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) yield* markdownFiles(path);
    else if (entry.toLowerCase().endsWith(".md")) yield path;
  }
}

function countLines(text) {
  if (text === "") return 0;
  const lines = text.split(/\r?\n/);
  return lines.at(-1) === "" ? lines.length - 1 : lines.length;
}

let fileCount = 0;
let lineCount = 0;
for (const file of markdownFiles(docsDir)) {
  fileCount += 1;
  lineCount += countLines(readFileSync(file, "utf8"));
}

console.log(`Markdown files: ${fileCount}`);
console.log(`Total lines: ${lineCount}`);
