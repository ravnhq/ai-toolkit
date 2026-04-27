# .env.qa Template

Copy this to `.env.qa` in your project root. Do NOT commit — it contains credentials.

```bash
# ---- Application URLs ----
QA_PORTAL_URL=http://localhost:3000
QA_API_URL=http://localhost:8080
QA_API_BASE_PATH=/api

# ---- Test Account Credentials ----
QA_TEST_USER_EMAIL=
QA_TEST_USER_PASSWORD=
QA_TEST_USER_2_EMAIL=
QA_TEST_USER_2_PASSWORD=
QA_ADMIN_EMAIL=
QA_ADMIN_PASSWORD=

# ---- Authentication ----
# cookie | bearer | api-key | none
QA_AUTH_METHOD=bearer
QA_AUTH_TOKEN=
QA_API_KEY=
QA_API_KEY_HEADER=X-API-Key

# ---- Integration Variables ----
# Uncomment sections relevant to your custom QA personalities

# -- Slack Integration --
# QA_SLACK_SIGNING_SECRET=
# QA_SLACK_TEAM_ID=
# QA_SLACK_BOT_USER_ID=
# QA_SLACK_CHANNEL_ID=

# -- Stripe Integration --
# QA_STRIPE_WEBHOOK_SECRET=
# QA_STRIPE_TEST_CUSTOMER_ID=

# -- Generic Webhook --
# QA_WEBHOOK_ENDPOINT=
# QA_WEBHOOK_SECRET=

# ---- Issue Tracker Overrides ----
# QA_LINEAR_TEAM_ID=
# QA_GITHUB_REPO=owner/repo

# ---- Settings ----
QA_AGENT_TIMEOUT=300
QA_AUTO_CREATE_ISSUES=true
```
