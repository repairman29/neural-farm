# This project uses the Neural Farm

**Cursor:** Use the local farm so prompts stay on your devices.

- **Override Base URL:** `http://localhost:4000/v1`
- **API Key:** `sk-local-farm`
- **Model:** Pick **GPT-4o mini** (or GPT-3.5 Turbo) in the model dropdown — not Cursor Pro or Claude.

**Start the farm** (once per session, from the neural-farm repo):

```bash
cd /path/to/neural-farm && ./dev_farm.sh
```

**Status:** `cd /path/to/neural-farm && ./status.sh`

See [ONBOARDING_CURSOR.md](https://github.com/your-org/neural-farm/blob/main/ONBOARDING_CURSOR.md) for full onboarding.
