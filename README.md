# ⚡ Espanso Utility - AI-Powered Text Expansion Toolkit

Type a shortcode anywhere on your computer and get instant grammar fixes, translations, GPT responses, email drafts, screenshots, passwords, and more — all powered by AI.

**40+ triggers** that work in any app — Chrome, Slack, VS Code, Notepad, everywhere.

---

## 🚀 Quick Setup — one script does everything

### Prerequisites
- **Windows 10/11**
- That's it. The setup script installs **Git** and **Espanso** for you if they're missing.

### Step 1: Run the one-line installer

Open **PowerShell** and paste this single command — it downloads and runs the setup script for you (nothing to clone by hand):

```powershell
irm https://raw.githubusercontent.com/questbibek/espanso-utility/main/setup-espanso.ps1 | iex
```

**Unattended one-liner** (no prompts — accepts all defaults, skips any key not already set):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/questbibek/espanso-utility/main/setup-espanso.ps1))) -Yes
```

> Prefer to download first and inspect it? Grab the file, then run it:
> ```powershell
> curl.exe -L -o setup-espanso.ps1 https://raw.githubusercontent.com/questbibek/espanso-utility/main/setup-espanso.ps1
> Unblock-File .\setup-espanso.ps1; powershell -ExecutionPolicy Bypass -File .\setup-espanso.ps1
> ```

**That single command does the whole flow, from any folder:**
1. Installs **Git** + **Espanso** if they aren't already present
2. Clones each repo to its correct place:
   - `espanso-utility` (scripts) → `$env:USERPROFILE\espanso-utility\`
   - `espanso` (config + triggers) → `$env:APPDATA\espanso\`
   - If a folder already exists it's **updated** (`git pull`), not overwritten
3. Walks you through API keys (skip any you don't have — re-run later to add them)
4. Loads the keys into your Windows environment (no separate `load-env.ps1` step)
5. Unblocks all scripts, sets Espanso to auto-start on login, and starts it

> Re-running the installer anytime is **safe** — it keeps every key you already set and only asks about what's missing.

### Step 2: Test it!
Open a **new** window and type `:wttt` anywhere — you should see `Welcome to the team ❤️`
(or try `:gpt` / `:fixgrammar` once your AI key is set).

---

## 📂 Two Repos Explained

| Repo | Clone to | What's inside |
|------|----------|---------------|
| [espanso-utility](https://github.com/questbibek/espanso-utility) | `$env:USERPROFILE\espanso-utility\` | All `.ps1` and `.bat` scripts, `.env.example`, `load-env.ps1` |
| [espanso](https://github.com/questbibek/espanso) | `$env:APPDATA\espanso\` | Espanso `config\` and `match\base.yml` (trigger definitions) |

---

## 🔑 API Keys

The setup script writes these for you. To edit by hand: `$env:USERPROFILE\espanso-utility\.env`

```dotenv
# Gemini — https://aistudio.google.com/apikey
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.0-flash
# Groq — https://console.groq.com/keys
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=llama-3.3-70b-versatile
# Which provider to call first; the others auto-fallback. gpt | gemini | groq
AI_PRIMARY=gpt
# OpenAI — default provider, and powers web-grounded :ask / :factcheck
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4.1-mini
OPENAI_SEARCH_MODEL=gpt-4o-mini-search-preview
OPENAI_FACTCHECK_MODEL=gpt-5.1
OCR_SPACE_API_KEY=your_key_here
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_ACCOUNT_ID=your_r2_account_id
R2_BUCKET_NAME=your_bucket_name
R2_PUBLIC_BASE_URL=https://pub-xxxxxxxxxxxxxxxxxxxxxxxx.r2.dev
```

**AI providers:** the toolkit routes through one **primary** provider with the others as automatic fallbacks. Setting up **any one** of GPT / Gemini / Groq is enough to use the AI triggers; add more for redundancy. `:ask` and `:factcheck` (live web search) specifically need an **OpenAI** key.

| Key | Required | What it powers | Get it |
|-----|----------|---------------|--------|
| `OPENAI_API_KEY` | Recommended (default) | All AI triggers when `AI_PRIMARY=gpt`, plus web-grounded `:ask` / `:factcheck` | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `GEMINI_API_KEY` | Alt provider | All AI triggers when selected/fallback | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) |
| `GROQ_API_KEY` | Alt provider | All AI triggers when selected/fallback | [console.groq.com/keys](https://console.groq.com/keys) |
| `AI_PRIMARY` | No | Provider called first (`gpt` default); others auto-fallback. Switch live with `:switch-gpt` / `:switch-gemini` / `:switch-groq` | — |
| `OCR_SPACE_API_KEY` | No | `:ocr` — extract text from screenshot | [ocr.space/ocrapi/freekey](https://ocr.space/ocrapi/freekey) (free) |
| `CLOUDINARY_CLOUD_NAME` | No | All Cloudinary triggers | [cloudinary.com/console](https://cloudinary.com/console) |
| `CLOUDINARY_UPLOAD_PRESET` | No | `:fullss`, `:clipss`, `:cloudinaryupload` | Cloudinary → Settings → Upload Presets |
| `CLOUDINARY_API_KEY` | No | `:cloudinarydelete`, `:cloudinary-N-clear` | Cloudinary → Settings → API Keys |
| `CLOUDINARY_API_SECRET` | No | `:cloudinarydelete`, `:cloudinary-N-clear` | Cloudinary → Settings → API Keys |
| `R2_ACCESS_KEY_ID` | No | All R2 triggers | Cloudflare Dashboard → R2 → Manage API Tokens |
| `R2_SECRET_ACCESS_KEY` | No | All R2 triggers | Cloudflare Dashboard → R2 → Manage API Tokens |
| `R2_ACCOUNT_ID` | No | All R2 triggers | Cloudflare Dashboard → R2 → Manage API Tokens |
| `R2_BUCKET_NAME` | No | All R2 triggers | Your R2 bucket name |
| `R2_PUBLIC_BASE_URL` | No | Public links after R2 upload | Cloudflare R2 → Bucket → Settings → Public Development URL |

### Cloudinary Upload Preset Setup
In Cloudinary → Settings → Upload Presets → edit your preset:
- **Generated public ID** → select **"Use the filename of the uploaded file as the public ID"**
- This ensures `:cloudinarydelete` can find files by name

### Google Calendar (Optional — for `:meeting` and `:schedule`)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project → Enable **Google Calendar API**
3. Credentials → Create **OAuth 2.0 Client ID** (Desktop app)
4. Download JSON → rename to `google-credentials.json`
5. Place in `$env:USERPROFILE\espanso-utility\`
6. First time you use `:meeting`, browser opens to authorize

See `google-credentials.example.json` for the expected format.

---

## 🔄 Updating API Keys

The simplest way: just **re-run the installer** — it keeps everything you already set, lets you add or change any key, reloads them into Windows, and restarts Espanso:

```powershell
irm https://raw.githubusercontent.com/questbibek/espanso-utility/main/setup-espanso.ps1 | iex
```

Prefer to edit the file directly? Then reload manually:

```powershell
# 1. Edit your .env
notepad "$env:USERPROFILE\espanso-utility\.env"

# 2. Reload into environment (run in Windows PowerShell / PS5)
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\espanso-utility\load-env.ps1"

# 3. Open a new terminal, then restart Espanso
espanso restart
```

Verify keys are loaded:
```powershell
echo $env:OPENAI_API_KEY
echo $env:GEMINI_API_KEY
echo $env:GROQ_API_KEY
echo $env:CLOUDINARY_CLOUD_NAME
echo $env:R2_BUCKET_NAME
```

---

## 📋 All Triggers

### ✍️ Grammar & Text
| Trigger | What it does | Mode |
|---------|-------------|------|
| `:fg` / `:fixgrammar` | Fix grammar, spelling, punctuation | Manual (copy first) |
| `:afg` / `:allfixgrammar` | Fix grammar | Auto (selects all) |
| `:gpt` | Ask GPT anything | Manual |
| `:allgpt` | Ask GPT anything | Auto |
| `:meaning` | Quick one-line word definition | Manual |
| `:fullmeaning` | Full analysis with etymology, synonyms, examples | Manual |

### 🔢 Math
| Trigger | What it does | Mode |
|---------|-------------|------|
| `:math` | Calculate expression — just the answer | Manual |
| `:explainmath` | Solve with step-by-step explanation | Manual |

### 🌐 Translation
| Manual (copy first) | Auto (selects all) | Language |
|-----|-----|------|
| `:toenglish` | `:alltoenglish` | English |
| `:tonepali` | `:alltonepali` | Nepali |
| `:tohindi` | `:alltohindi` | Hindi |
| `:tospanish` | `:alltospanish` | Spanish |
| `:tofrench` | `:alltofrench` | French |
| `:tochinese` | `:alltochinese` | Chinese |
| `:tojapanese` | `:alltojapanese` | Japanese |
| `:togerman` | `:alltogerman` | German |

### 💬 Replies & Email
| Trigger | What it does | Mode |
|---------|-------------|------|
| `:replyasme` | Reply as Bibek (professional style) | Manual |
| `:allreplyasme` | Reply as Bibek | Auto |
| `:replythis` | Smart reply — adapts to email/chat/casual | Manual |
| `:replythisemail` | Professional email reply | Manual |
| `:replywithcontext` / `:rwc` | Context-aware reply using surrounding text | Manual |
| `:draft` | Draft professional email from rough notes | Manual |

### 📊 Productivity
| Trigger | What it does | Mode |
|---------|-------------|------|
| `:bugtask` / `:allbugtask` | Format structured bug report | Manual / Auto |
| `:userstory` / `:alluserstory` | Format user story with acceptance criteria | Manual / Auto |
| `:summarize` / `:allsummarize` | Summarize text | Manual / Auto |
| `:sheet` | Google Sheets formula from description | Manual |
| `:content` | Video content ideas with scoring | Manual |
| `:caption` | Social media captions (casual, pro, viral) | Manual |

### 🔧 Utilities
| Trigger | What it does |
|---------|-------------|
| `:whoami` | Shows your Windows username |
| `:date` | Current date (15th Aug 2026 format) |
| `:phone` | Random Nepal phone number |
| `:npphone` | Nepal phone with +977 prefix |
| `:name` | Random first name |
| `:lname` | Random last name |
| `:email` | Random email address |
| `:password` | Generate 16-character secure password |
| `:pass,32` | Generate N-character password (type then SPACE) |
| `:bibek@v` | bibek@vrittechnologies.com |
| `:maptovrit` | Vrit Technologies office location + Google Maps link |
| `:maptoskill` | Skill Shikshya office location + Google Maps link |

### 📸 Screenshot & Image
| Trigger | What it does |
|---------|-------------|
| `:fullss` | Screenshot active monitor → upload to Cloudinary → paste URL |
| `:clipss` | Clipboard image → upload to Cloudinary → paste URL |
| `:ocr` | Extract text from clipboard screenshot (OCR) |

### 🖼️ Cloudinary File Storage
| Trigger | What it does |
|---------|-------------|
| `:cloudinaryupload` | Ctrl+C any file(s) anywhere → upload to Cloudinary → paste link(s) |
| `:cloudinarydelete` | Ctrl+C any file(s) → delete from Cloudinary by filename |
| `:cloudinary-clear-all` | Delete ALL resources from Cloudinary |
| `:cloudinary-{N}-clear` | Delete resources older than N days (e.g. `:cloudinary-7-clear`, `:cloudinary-30-clear`) |

**Usage:**
- Select one or multiple files in Explorer → `Ctrl+C` → type trigger
- Supports images, videos, and raw files (pdf, zip, html, docx, csv, json, ps1, md, etc.)
- Images/videos use filename without extension as public_id; raw files keep full filename
- Links are pasted inline and also copied to clipboard
- Requires `CLOUDINARY_API_KEY` + `CLOUDINARY_API_SECRET` for delete/clear operations

### ☁️ Cloudflare R2 File Storage
| Trigger | What it does |
|---------|-------------|
| `:r2upload` | Ctrl+C any file(s) anywhere → upload to R2 → paste public link(s) |
| `:r2delete` | Ctrl+C any file(s) → delete matching object(s) from R2 bucket |
| `:r2-clear-all` | Delete ALL objects in the bucket |
| `:r2-{N}-clear` | Delete objects older than N days (e.g. `:r2-7-clear`, `:r2-30-clear`) |

**Usage:**
- Select one or multiple files in Explorer → `Ctrl+C` → type trigger
- Works from any location — Downloads, Desktop, D drive, anywhere
- Filenames are auto-sanitized (spaces and special characters replaced with hyphens)
- Links are pasted inline and also copied to clipboard

### 📅 Meetings
| Trigger | What it does |
|---------|-------------|
| `:meeting` | Create instant Google Meet link |
| `:schedule` | Smart meeting scheduler — paste natural language, get calendar event |

---

## 💡 How Manual vs Auto Triggers Work

- **Manual** (`:fg`, `:gpt`, etc.) — Copy text to clipboard first → delete it → type the trigger → result replaces the trigger
- **Auto** (`:afg`, `:allgpt`, etc.) — Just type the trigger → it auto-selects all text in the field, fixes it, and replaces

---

## ⚙️ One-Time Commands (For Developers)

```powershell
# Remove hardcoded API keys from scripts (replace with $env: references)
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\espanso-utility\remove-hardcoded-keys.ps1"

# Set UTF-8 system-wide (run as Administrator, restart PC after)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name 'ACP' -Value '65001'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name 'OEMCP' -Value '65001'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name 'MACCP' -Value '65001'

# Stop Espanso from auto-starting (not recommended)
espanso service unregister
```

---

## 🤝 Contributing

1. Fork the repo
2. Add your trigger to `match\base.yml` in the [espanso](https://github.com/questbibek/espanso) repo
3. Create the script in [espanso-utility](https://github.com/questbibek/espanso-utility)
4. Call AI through `ai-call.ps1` and read keys from `$env:` (e.g. `$env:OPENAI_API_KEY`) — never hardcode keys
5. Submit a PR

---

## 📜 License

MIT — use it, modify it, share it.