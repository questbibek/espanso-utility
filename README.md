# ⚡ Espanso Utility — Mac & Linux

AI-powered text expansion toolkit. Type a shortcode anywhere and get instant grammar fixes, translations, GPT responses, email drafts, screenshots, and more.

40+ triggers that work in any app — Chrome, Slack, VS Code, Terminal, everywhere.

---

## 🚀 One-Line Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/questbibek/espanso-utility/unix/espanso.sh)
```

This single command will:
- Detect your OS (Mac or Linux) and display server (X11/Wayland)
- Install Espanso
- Install all dependencies (`jq`, `xclip`, `xdotool`, `scrot` etc.)
- Clone this repo to `~/espanso-utility`
- Clone espanso config to the correct config directory
- Create your `.env` file
- Make all scripts executable
- Add `load-env.sh` to your shell rc file
- Restart Espanso

---

## 🔑 Setup API Keys

After install, open your `.env` file:
```bash
code ~/espanso-utility/.env
# or
nano ~/espanso-utility/.env
```

Fill in your keys:
```env
# Required
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxx

# Optional: OCR
OCR_SPACE_API_KEY=your_key_here

# Optional: Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Optional: Cloudflare R2
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_ACCOUNT_ID=your_r2_account_id
R2_BUCKET_NAME=your_bucket_name
R2_PUBLIC_BASE_URL=https://pub-xxxxxxxxxxxxxxxxxxxxxxxx.r2.dev
```

Then load them:
```bash
source ~/espanso-utility/load-env.sh
espanso restart
```

---

## 🔄 Updating API Keys
```bash
# 1. Edit your .env
code ~/espanso-utility/.env

# 2. Reload into environment
source ~/espanso-utility/load-env.sh

# 3. Restart Espanso
espanso restart

# 4. Verify
echo $OPENAI_API_KEY
```

---

## 📂 Repo Structure
```
espanso-utility/
├── espanso.sh                  # One-shot installer
├── load-env.sh                 # Load API keys into shell
├── shared.sh                   # Shared clipboard + env helpers
├── .env                        # Your API keys (gitignored)
├── env.example                 # Template for .env
├── google-credentials.json     # Google OAuth (for :meeting)
├── espanso-fixgrammar.sh
├── espanso-gpt.sh
├── espanso-paraphrase.sh
├── ... (all trigger scripts)
```

---

## 📋 All Triggers

### ✍️ Grammar & Text
| Trigger | What it does | Mode |
|---|---|---|
| `:fg` / `:fixgrammar` | Fix grammar, spelling, punctuation | Manual (copy first) |
| `:afg` / `:allfixgrammar` | Fix grammar | Auto (selects all) |
| `:gpt` | Ask GPT anything | Manual |
| `:allgpt` | Ask GPT anything | Auto |
| `:paraphrase` / `:pp` | Paraphrase professionally | Manual |
| `:meaning` | Quick one-line word definition | Manual |
| `:fullmeaning` | Full analysis with etymology, synonyms, examples | Manual |

### 🔢 Math
| Trigger | What it does |
|---|---|
| `:math` | Calculate expression — just the answer |
| `:explainmath` | Solve with step-by-step explanation |

### 🌐 Translation
| Manual | Auto | Language |
|---|---|---|
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
|---|---|---|
| `:replyasme` | Reply as Bibek (professional style) | Manual |
| `:allreplyasme` | Reply as Bibek | Auto |
| `:replythis` | Smart reply — adapts to email/chat/casual | Manual |
| `:replythisemail` | Professional email reply | Manual |
| `:replywithcontext` / `:rwc` | Context-aware reply | Manual |
| `:draft` | Draft professional email from rough notes | Manual |

### 📊 Productivity
| Trigger | What it does | Mode |
|---|---|---|
| `:bugtask` / `:allbugtask` | Format structured bug report | Manual / Auto |
| `:userstory` / `:alluserstory` | Format user story with acceptance criteria | Manual / Auto |
| `:summarize` / `:allsummarize` | Summarize text | Manual / Auto |
| `:sheet` | Google Sheets formula from description | Manual |
| `:content` | Video content ideas with scoring | Manual |
| `:caption` | Social media captions | Manual |

### 🔧 Utilities
| Trigger | What it does |
|---|---|
| `:whoami` | Shows your username |
| `:date` | Current date (15th Mar 2026 format) |
| `:phone` | Random Nepal phone number |
| `:npphone` | Nepal phone with 977 prefix |
| `:name` | Random first name |
| `:lname` | Random last name |
| `:email` | Random email address |
| `:password` | Generate 16-character secure password |
| `:pass,32` | Generate N-character password |
| `:bibek@v` | bibek@vrittechnologies.com |
| `:maptovrit` | Vrit Technologies office location |
| `:maptoskill` | Skill Shikshya office location |
| `:fill` | Auto-fill form fields with fake data |

### 💻 Dev Tools
| Trigger | What it does |
|---|---|
| `:commit` | Generate git commit message + push command |
| `:git` | Generate git command from description |
| `:bash` | Generate bash command from description |
| `:ubuntu` | Generate Ubuntu command from description |
| `:regex` | Generate regex pattern from description |

### 📸 Screenshot & Image
| Trigger | What it does |
|---|---|
| `:fullss` | Screenshot active monitor → upload to Cloudinary → paste URL |
| `:clipss` | Clipboard image → upload to Cloudinary → paste URL |
| `:ocr` | Extract text from clipboard screenshot (OCR) |

### 🖼️ Cloudinary File Storage
| Trigger | What it does |
|---|---|
| `:cloudinaryupload` | Copy any file(s) → upload to Cloudinary → paste link(s) |
| `:cloudinarydelete` | Copy any file(s) → delete from Cloudinary by filename |
| `:cloudinary-clear-all` | Delete ALL resources from Cloudinary |
| `:cloudinary-{N}-clear` | Delete resources older than N days |

### ☁️ Cloudflare R2 Storage
| Trigger | What it does |
|---|---|
| `:r2upload` | Copy any file(s) → upload to R2 → paste public link(s) |
| `:r2delete` | Copy any file(s) → delete from R2 bucket |
| `:r2-clear-all` | Delete ALL objects in the bucket |
| `:r2-{N}-clear` | Delete objects older than N days |

### 📅 Meetings
| Trigger | What it does |
|---|---|
| `:meeting` | Create instant Google Meet link |
| `:schedule` | Smart meeting scheduler from natural language |

---

## 💡 Manual vs Auto Triggers

**Manual** (`:fg`, `:gpt`, etc.)
1. Copy text to clipboard
2. Type the trigger
3. Result replaces the trigger

**Auto** (`:afg`, `:allgpt`, etc.)
1. Type your text in any field
2. Type the trigger at the end
3. Script selects all, processes, and replaces everything

---

## 🔑 API Keys Reference

| Key | Required | Powers | Get it |
|---|---|---|---|
| `OPENAI_API_KEY` | ✅ Yes | Grammar, GPT, translate, reply, summarize, math, meaning, draft, sheets, content, caption, bug task, user story, schedule | [platform.openai.com](https://platform.openai.com/api-keys) |
| `OCR_SPACE_API_KEY` | No | `:ocr` | [ocr.space](https://ocr.space/ocrapi/freekey) |
| `CLOUDINARY_*` | No | All Cloudinary triggers | [cloudinary.com](https://cloudinary.com/console) |
| `R2_*` | No | All R2 triggers | [Cloudflare Dashboard](https://dash.cloudflare.com) |

---

## 📅 Google Calendar Setup (for :meeting and :schedule)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project → Enable Google Calendar API
3. Credentials → Create OAuth 2.0 Client ID (Desktop app)
4. Download JSON → rename to `google-credentials.json`
5. Place in `~/espanso-utility/`
6. First time you use `:meeting`, browser opens to authorize

---

## 🔄 Keeping Up to Date
```bash
cd ~/espanso-utility
git pull origin unix
espanso restart
```

---

## 🛠️ Dependencies

| Tool | Mac | Linux X11 | Linux Wayland |
|---|---|---|---|
| Clipboard | `pbcopy/pbpaste` (built-in) | `xclip` | `wl-clipboard` |
| Select All | `osascript` (built-in) | `xdotool` | `xdotool` |
| Screenshot | `screencapture` (built-in) | `scrot` | `grimshot` |
| Clipboard image | `pngpaste` | `xclip` | `wl-paste` |
| JSON | `jq` | `jq` | `jq` |
| HTTP | `curl` | `curl` | `curl` |

All installed automatically by `espanso.sh`.

---

## 🤝 Contributing

1. Fork the repo
2. Add your trigger to `~/.config/espanso/match/base.yml`
3. Create the script in `~/espanso-utility/`
4. Source `shared.sh` for clipboard and env handling
5. Never hardcode API keys — always use `$OPENAI_API_KEY` etc.
6. Submit a PR to the `unix` branch

---

## 📜 License

MIT — use it, modify it, share it.

