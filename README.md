# ⚡ Espanso Utility - AI-Powered Text Expansion Toolkit

Type a shortcode anywhere on your computer and get instant grammar fixes, translations, GPT responses, email drafts, screenshots, passwords, and more — all powered by AI.

**40+ triggers** that work in any app — Chrome, Slack, VS Code, Notepad, everywhere.

---

## 🚀 Quick Setup

### Prerequisites
- **Windows 10/11**
- **[Espanso](https://espanso.org/install/)** installed
- **[OpenAI API Key](https://platform.openai.com/api-keys)** (required)

### Step 1: Clone both repos

```powershell
# Clone espanso-utility scripts into your user profile
cd $env:USERPROFILE
git clone https://github.com/questbibek/espanso-utility.git

# Stop espanso if it is running
espanso stop

# Remove old espanso files
Remove-Item -Recurse -Force "C:\Users\unrav\AppData\Roaming\espanso"

# Clone espanso config (base.yml) into Espanso's config folder
cd "$env:APPDATA"
git clone https://github.com/questbibek/espanso.git

# Starts espanso
espanso restart
```

This creates:
- `C:\Users\YOUR_USERNAME\espanso-utility\` — all scripts
- `C:\Users\YOUR_USERNAME\AppData\Roaming\espanso\` — Espanso config with `match\base.yml`

### Step 2: Setup API keys

```powershell
# Copy the example env file
Copy-Item "$env:USERPROFILE\espanso-utility\.env.example" "$env:USERPROFILE\espanso-utility\.env"

# Open and add your API keys
notepad "$env:USERPROFILE\espanso-utility\.env"
```

### Step 3: Load API keys into Windows environment

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
| [espanso-utility](https://github.com/questbibek/espanso-utility) | `C:\Users\YOU\espanso-utility\` | All `.ps1` and `.bat` scripts, `.env.example`, `load-env.ps1` |
| [espanso](https://github.com/questbibek/espanso) | `C:\Users\YOU\AppData\Roaming\espanso\` | Espanso `config\` and `match\base.yml` (trigger definitions) |

---

## 🔑 API Keys

Edit `%USERPROFILE%\espanso-utility\.env`:

```
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxx
OCR_SPACE_API_KEY=your_key_here
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
```

| Key | Required | What it powers | Get it |
|-----|----------|---------------|--------|
| `OPENAI_API_KEY` | **Yes** | Grammar, GPT, translate, reply, summarize, math, meaning, draft, sheets, content, caption, bug task, user story, schedule | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `OCR_SPACE_API_KEY` | No | `:ocr` — extract text from screenshot | [ocr.space/ocrapi/freekey](https://ocr.space/ocrapi/freekey) (free) |
| `CLOUDINARY_CLOUD_NAME` | No | `:fullss`, `:clipss` — screenshot upload | [cloudinary.com/console](https://cloudinary.com/console) |
| `CLOUDINARY_UPLOAD_PRESET` | No | `:fullss`, `:clipss` — screenshot upload | Cloudinary → Settings → Upload Presets |

### Google Calendar (Optional — for `:meeting` and `:schedule`)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project → Enable **Google Calendar API**
3. Credentials → Create **OAuth 2.0 Client ID** (Desktop app)
4. Download JSON → rename to `google-credentials.json`
5. Place in `%USERPROFILE%\espanso-utility\`
6. First time you use `:meeting`, browser opens to authorize

See `google-credentials.example.json` for the expected format.

---

## 🔄 Updating API Keys

```powershell
# 1. Edit your .env
notepad "$env:USERPROFILE\espanso-utility\.env"

# 2. Reload into environment
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\espanso-utility\load-env.ps1"

# 3. Restart Espanso
espanso restart
```

Verify keys are loaded:
```powershell
echo $env:OPENAI_API_KEY
echo $env:OCR_SPACE_API_KEY
echo $env:CLOUDINARY_CLOUD_NAME
echo $env:CLOUDINARY_UPLOAD_PRESET
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
4. Use `$env:OPENAI_API_KEY` — never hardcode keys
5. Submit a PR

---

## 📜 License

MIT — use it, modify it, share it.
