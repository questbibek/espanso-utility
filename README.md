# ⚡ Espanso Utility - AI-Powered Text Expansion Toolkit

Type a shortcode anywhere on your computer and get instant grammar fixes, translations, GPT responses, email drafts, screenshots, passwords, and more — all powered by AI.

**40+ triggers** that work in any app — Chrome, Slack, VS Code, Notepad, everywhere.

---

## 🚀 Quick Setup

### Prerequisites
- **Windows 10/11**
- **[Espanso](https://espanso.org/install/)** installed
- **[OpenRouter API Key](https://openrouter.ai/keys)** (required)

### Step 1: Clone both repos

```powershell
# Clone espanso-utility scripts into your user profile
cd $env:USERPROFILE
git clone https://github.com/questbibek/espanso-utility.git

# Stop espanso if it is running
espanso stop

# Clone espanso config (base.yml) into Espanso's config folder
cd "$env:APPDATA"
git clone https://github.com/questbibek/espanso.git

# Starts espanso
espanso restart
```

This creates:
- `$env:USERPROFILE\espanso-utility\` — all scripts
- `$env:APPDATA\espanso\` — Espanso config with `match\base.yml`

### Step 2: Setup API keys

```powershell
# Copy the example env file
Copy-Item "$env:USERPROFILE\espanso-utility\.env.example" "$env:USERPROFILE\espanso-utility\.env"

# Open and add your API keys
notepad "$env:USERPROFILE\espanso-utility\.env"
```

### Step 3: Load API keys into Windows environment

> ⚠️ **Important:** Run this in **Windows PowerShell (PS5)**, not PowerShell 7. Then open a new terminal for changes to take effect.

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\espanso-utility\load-env.ps1"
```

### Step 4: Start Espanso

```powershell
# Restart Espanso to pick up new config
espanso restart

# Auto-start Espanso on Windows boot
espanso service register
```

### Step 5: Test it!
Type `:wttt` anywhere — you should see `Welcome to the team ❤️`

---

## 📂 Two Repos Explained

| Repo | Clone to | What's inside |
|------|----------|---------------|
| [espanso-utility](https://github.com/questbibek/espanso-utility) | `$env:USERPROFILE\espanso-utility\` | All `.ps1` and `.bat` scripts, `.env.example`, `load-env.ps1` |
| [espanso](https://github.com/questbibek/espanso) | `$env:APPDATA\espanso\` | Espanso `config\` and `match\base.yml` (trigger definitions) |

---

## 🔑 API Keys

Edit `$env:USERPROFILE\espanso-utility\.env`:

```dotenv
# Get your API key at https://openrouter.ai/keys
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx
# Browse models at https://openrouter.ai/models — change these if a model is deprecated.
OPENROUTER_MODEL_FAST=openai/gpt-4o-mini
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

| Key | Required | What it powers | Get it |
|-----|----------|---------------|--------|
| `OPENROUTER_API_KEY` | **Yes** | Grammar, GPT, translate, reply, summarize, math, meaning, draft, sheets, content, caption, bug task, user story, schedule | [openrouter.ai/keys](https://openrouter.ai/keys) |
| `OPENROUTER_MODEL_FAST` | No | Model used by all AI triggers (default: `openai/gpt-4o-mini`) — change once here to swap all scripts without editing them | [openrouter.ai/models](https://openrouter.ai/models) |
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
echo $env:OPENROUTER_API_KEY
echo $env:CLOUDINARY_CLOUD_NAME
echo $env:CLOUDINARY_API_KEY
echo $env:R2_BUCKET_NAME
echo $env:R2_ACCESS_KEY_ID
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
4. Use `$env:OPENROUTER_API_KEY` — never hardcode keys
5. Submit a PR

---

## 📜 License

MIT — use it, modify it, share it.