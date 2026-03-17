import { homedir } from "node:os";
import { join } from "node:path";

export const RAVENCITO_VERSION = "0.1.0";

export const RAVENCITO_DIR = join(homedir(), ".ravencito");
export const RAVENCITO_CONFIG = join(RAVENCITO_DIR, "config");
export const REPO_DIR = join(RAVENCITO_DIR, "repo");
export const MARKETPLACE_PATH = join(REPO_DIR, "marketplace.json");
export const LAST_UPDATE_FILE = join(RAVENCITO_DIR, ".last_update");
export const REPO_URL = "https://github.com/ravnhq/ai-toolkit.git";
export const RAVENCITORC = ".ravencitorc";
export const UPDATE_CHECK_DAYS = 7;
