# Briefing - OpenClaw Projektstatus & Deployment (v2)

Detta dokument är en sammanfattning av arbetet med **OpenClaw**-projektet, baserat på den fullständiga konversationen och implementerade fixar. Syftet är att ge nästa agent en komplett bild av läget.

## Projektkontext
**Projekt**: [OpenClaw](https://github.com/openclaw/openclaw) - AI Gateway & Agent system.
**Fork**: [sflorin-git/openclaw](https://github.com/sflorin-git/openclaw) (main branch).
**Miljö**: Deployment sker via Coolify/Cloudforge.

## Dokumentation i Obsidian
Det finns två centrala guider skapade i användarens Obsidian-vault:
1.  `Projects/OpenClaw/Deployment Guide - Coolify.md` - Hanterar Fork -> Deploy-processen.
2.  `Projects/OpenClaw/Post-Deploy Setup Guide.md` - Hanterar modeller, säkerhetsaudit och kanaler.

## Genomförda åtgärder & Historik

### 1. Säkerhet & Miljövariabler
- **Tidigare**: Det fanns en oro för att `OPENCLAW_GATEWAY_TOKEN` var hårdkodad i Dockerfilen.
- **Nu**: Bekräftat att Dockerfilen endast refererar till `${OPENCLAW_GATEWAY_TOKEN}`. Själva värdet (UUID-token) lagras säkert i Coolify:s Environment Variables.
- **Förbättring**: Vi har implementerat stöd för `OPENCLAW_*` miljövariabler direkt i koden ([src/config/io.ts](file:///D:/openclaw/src/config/io.ts)) för att slippa köra manuella `oc config set` kommandon efter att containern startat.

### 2. OpenAI Auto-Enablement
- **Fix**: Lagt till `openai` i `PROVIDER_PLUGIN_IDS` ([src/config/plugin-auto-enable.ts](file:///d:/openclaw/src/config/plugin-auto-enable.ts)). Pluginet aktiveras nu automatiskt vid start om `OPEN_API_KEY` finns. Detta ersätter de manuella kommandon som användes tidigare.

### 3. Resilient Build Process (`SOFT_FAIL`)
- **Fix**: Implementerat `OPENCLAW_BUILD_SOFT_FAIL=true` i [scripts/tsdown-build.mjs](file:///d:/openclaw/scripts/tsdown-build.mjs) och [Dockerfile](file:///d:/openclaw/Dockerfile).
- **Rational**: Vissa extensions (speciellt `@tloncorp/api`) har ofta TypeScript-fel som förhindrar hela bygget i Coolify. Med `SOFT_FAIL` tillåts bygget fortsätta med varningar för extensions, så länge kärnsystemet fungerar.

### 4. JSON-härdning & Permissions
- **Härdning**: Dockerfilen har säkrats mot malformade bygg-argument (JSON-injektion).
- **Permissions**: Fixat ägarskap på `.openclaw`-katalogen (`node:node`) för att tillåta containern att skriva sina lokala config-filer vid runtime.

## Konfigurations-Workflow (Nu vs Då)

### Tidigare (Manuellt via `docker exec`):
Användaren behövde köra kommandon som:
```bash
oc config set agents.defaults.model.primary "anthropic/claude-sonnet-4-5"
oc config set tools.profile "coding"
oc security audit --deep
```

### Nu (Automatiserat via Environment Variables):
Sätt dessa direkt i Coolify → Environment Variables:
- `OPENCLAW_GATEWAY_TOKEN`: (Ditt UUID)
- `OPENCLAW_AGENTS_PROVIDER`: `anthropic`
- `OPENCLAW_AGENTS_MODEL`: `claude-3-5-sonnet-latest`
- `OPENAI_API_KEY`: (Hittas automatiskt av plugin-systemet)

## Rekommenderade Nästa Steg
1.  **Deploya**: Kör en ny deploy i Coolify från `sflorin-git/openclaw:main`.
2.  **Verifiera**: Kontrollera att loggarna visar "OpenAI plugin registered" och att gateway-tokenet accepteras.
3.  **Audit**: Kör `oc security audit --deep` en gång live för att bekräfta att trustedProxies (`10.0.2.0/24`) och andra säkerhetsinställningar är korrekta.
4.  **Tlon Extension**: Om Tlon-integrationen behövs senare måste filerna i `packages/api` ses över (TS-fel).
