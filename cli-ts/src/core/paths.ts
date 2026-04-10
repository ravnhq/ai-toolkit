import { homedir } from "node:os";
import { join } from "node:path";

export const CORVUS_VERSION = "0.1.1";

export const CORVUS_DIR = join(homedir(), ".corvus");
export const CORVUS_CONFIG = join(CORVUS_DIR, "config");
export const REPO_DIR = join(CORVUS_DIR, "repo");
export const MARKETPLACE_PATH = join(REPO_DIR, "marketplace.json");
export const LAST_UPDATE_FILE = join(CORVUS_DIR, ".last_update");
export const REPO_URL = "https://github.com/ravnhq/ai-toolkit.git";
export const CORVUSRC = ".corvusrc";
export const UPDATE_CHECK_DAYS = 7;
