import { resolve } from "node:path";
import { REPO_DIR } from "../core/paths.js";

export function cmdCompletions(shell: string | undefined): void {
  const detected = shell ?? detectShell();

  if (detected === "zsh") {
    printZshInstructions();
  } else if (detected === "bash") {
    printBashInstructions();
  } else if (detected === "fish") {
    printFishInstructions();
  } else {
    console.error(`Unsupported shell: ${detected}`);
    console.error('Supported shells: zsh, bash, fish');
    process.exit(1);
  }
}

function detectShell(): string {
  const shellEnv = process.env.SHELL ?? "";
  if (shellEnv.endsWith("/zsh")) return "zsh";
  if (shellEnv.endsWith("/bash")) return "bash";
  if (shellEnv.endsWith("/fish")) return "fish";
  return "zsh"; // default
}

function printZshInstructions(): void {
  const src = resolve(REPO_DIR, "cli/completions/_ravencito.zsh");
  const ohmyzsh = "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/completions";

  console.log(`# Zsh completions for ravencito
#
# Option 1 — oh-my-zsh (recommended):
mkdir -p "${ohmyzsh}"
cp "${src}" "${ohmyzsh}/_ravencito"
# Then reload: exec zsh

# Option 2 — manual fpath:
# Add this to your ~/.zshrc BEFORE compinit:
#   fpath=("${resolve(REPO_DIR, "cli/completions")}" $fpath)
#   autoload -Uz compinit && compinit
`);
}

function printBashInstructions(): void {
  const src = resolve(REPO_DIR, "cli/completions/ravencito.bash");

  console.log(`# Bash completions for ravencito
#
# Add this to your ~/.bashrc or ~/.bash_profile:
source "${src}"
`);
}

function printFishInstructions(): void {
  const src = resolve(REPO_DIR, "cli/completions/ravencito.fish");
  const fishDir = "~/.config/fish/completions";

  console.log(`# Fish completions for ravencito
#
# Copy the completions file to your fish completions directory:
mkdir -p ${fishDir}
cp "${src}" ${fishDir}/ravencito.fish
# Completions load automatically — no reload needed.
`);
}
