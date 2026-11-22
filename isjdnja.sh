#!/bin/bash
# ==========================================
# 🕵️ RenStalker v4.0 - Full Auto (Fix API)
# ==========================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

read -p "👉 Masukkan Domain lo (contoh: rendzzclouds.my.id): " DOMAIN
[[ -z "$DOMAIN" ]] && { echo -e "${RED}❌ Domain tidak boleh kosong!${NC}"; exit 1; }

WEB_ROOT="/var/www/$DOMAIN"
STALK_DIR="/opt/renstalker"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

# ==========================================
# 1. SETUP NODE.JS BACKEND (DOUBLE ENGINE)
# ==========================================
echo -e "${CYAN}[1/5] Setup Backend Node.js (Anti Error)...${NC}"
mkdir -p "$STALK_DIR"
cd "$STALK_DIR"

# Install dependencies
cat > package.json << 'EOF'
{
  "name": "renstalker-backend",
  "version": "4.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "cors": "^2.8.5",
    "axios": "^1.7.2"
  }
}
EOF
npm install --silent >/dev/null 2>&1

# Bikin server.js pake 2 API (Siputzx + TikWM)
cat > server.js << 'NODEEOF'
const express = require('express');
const axios = require('axios');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/stalk', async (req, res) => {
    const username = req.query.username;
    if (!username) return res.json({ status: false, message: 'Username required' });

    // Bersihin input
    let cleanUsername = username;
    if (username.includes('tiktok.com/')) {
        const match = username.match(/@([a-zA-Z0-9._-]+)/);
        if (match) cleanUsername = match[1];
    } else {
        cleanUsername = username.replace('@', '').trim();
    }

    // === ENGINE 1: SIPUTZX API ===
    try {
        const apiUrl = `https://api.siputzx.my.id/api/stalk/tiktok?username=${cleanUsername}`;
        const response = await axios.get(apiUrl, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
            timeout: 10000
        });

        const data = response.data;
        if (data && data.status === true && data.data) {
            const user = data.data;
            return res.json({ 
                status: true, 
                data: {
                    user: {
                        uniqueId: user.username,
                        nickname: user.nickname,
                        avatarLarger: user.profile,
                        signature: user.bio || 'Tidak ada bio.',
                        verified: user.verified || false,
                        followerCount: user.followers,
                        followingCount: user.following,
                        heartCount: user.likes
                    }
                }
            });
        }
    } catch (err) {
        console.log("Engine 1 (Siputzx) Gagal, pindah ke Engine 2...");
    }

    // === ENGINE 2: TIKWM API (FALLBACK) ===
    try {
        const fallbackUrl = `https://api.tikwm.com/api/user/info?unique_id=${cleanUsername}`;
        const fallbackRes = await axios.get(fallbackUrl, { timeout: 10000 });
        
        if (fallbackRes.data.code === 0 && fallbackRes.data.data) {
            const user = fallbackRes.data.data.user;
            const stats = fallbackRes.data.data.stats;
            
            return res.json({ 
                status: true, 
                data: {
                    user: {
                        uniqueId: user.uniqueId,
                        nickname: user.nickname,
                        avatarLarger: user.avatarLarger,
                        signature: user.signature || 'Tidak ada bio.',
                        verified: user.verified || false,
                        followerCount: stats.followerCount,
                        followingCount: stats.followingCount,
                        heartCount: stats.heartCount
                    }
                }
            });
        }
    } catch (fallbackErr) {
        console.log("Engine 2 (TikWM) Gagal:", fallbackErr.message);
    }

    // Kalau dua-duanya gagal
    res.json({ status: false, message: 'Akun tidak ditemukan, private, atau API sedang down.' });
});

app.listen(3006, '127.0.0.1', () => console.log('✅ RenStalker API running on port 3006'));
NODEEOF

# Setup Systemd Service
cat > /etc/systemd/system/renstalker.service << 'SVCEOF'
[Unit]
Description=RenStalker API Backend
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/renstalker/server.js
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable --now renstalker >/dev/null 2>&1
systemctl restart renstalker

# ==========================================
# 2. GENERATE FRONTEND UI (RGB + PING)
# ==========================================
echo -e "${CYAN}[2/5] Setup Frontend UI...${NC}"
mkdir -p "$WEB_ROOT"

cat > "$WEB_ROOT/index.php" << 'PHPEOF'
<?php
// Redirect ke stalker.php
require 'stalker.php';
?>
PHPEOF

cat > "$WEB_ROOT/stalker.php" << 'PHPEOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RenStalker - TikTok Viewer</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
    :root { --bg: #070b14; --card: #0f1a2e; --primary: #6366f1; --text: #f8fafc; --text-muted: #94a3b8; --border: #1e2a45; --tiktok: #fe2c55; --cyan: #25f4ee; }
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
    body { background: var(--bg); color: var(--text); min-height: 100vh; display: flex; flex-direction: column; align-items: center; padding: 20px; background-image: radial-gradient(circle at 10% 20%, rgba(99,102,241,0.15), transparent 40%), radial-gradient(circle at 90% 80%, rgba(254,44,85,0.1), transparent 40%); }
    .container { width: 100%; max-width: 500px; }
    
    @keyframes rgbGlow { 0% { color: #fe2c55; text-shadow: 0 0 10px rgba(254,44,85,0.5); } 50% { color: #25f4ee; text-shadow: 0 0 10px rgba(37,244,238,0.5); } 100% { color: #fe2c55; text-shadow: 0 0 10px rgba(254,44,85,0.5); } }
    .header { text-align: center; margin-bottom: 30px; margin-top: 20px; }
    .header h1 { font-size: 2.2em; font-weight: 800; display: flex; align-items: center; justify-content: center; gap: 10px; }
    .header h1 span { animation: rgbGlow 3s infinite alternate ease-in-out; }
    .header p { color: var(--text-muted); font-size: 0.9em; margin-top: 8px; letter-spacing: 1px; }

    .card { background: var(--card); border: 1px solid var(--border); border-radius: 20px; padding: 25px; margin-bottom: 20px; box-shadow: 0 10px 40px rgba(0,0,0,0.5); }
    
    .input-group { display: flex; align-items: center; background: rgba(0,0,0,0.4); border: 1px solid var(--border); border-radius: 12px; padding: 5px 15px; gap: 10px; margin-bottom: 15px; transition: 0.3s; }
    .input-group:focus-within { border-color: var(--tiktok); box-shadow: 0 0 0 3px rgba(254,44,85,0.2); }
    .input-group i { color: var(--tiktok); font-size: 1.2em; }
    .input-group input { flex: 1; background: transparent; border: none; color: var(--text); padding: 15px 0; font-size: 1em; font-weight: 600; outline: none; font-family: inherit; }
    
    .btn { width: 100%; padding: 15px; border-radius: 12px; border: none; font-weight: 700; font-size: 1em; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 10px; transition: 0.3s; color: white; }
    .btn-tiktok { background: linear-gradient(135deg, var(--tiktok), #ff0050); box-shadow: 0 4px 15px rgba(254,44,85,0.4); }
    .btn-tiktok:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(254,44,85,0.6); }
    .btn-tiktok:disabled { opacity: 0.7; cursor: not-allowed; transform: none; }

    #result { display: none; }
    .profile-header { display: flex; align-items: center; gap: 20px; margin-bottom: 20px; }
    .profile-avatar { width: 85px; height: 85px; border-radius: 50%; border: 3px solid var(--tiktok); object-fit: cover; box-shadow: 0 0 20px rgba(254,44,85,0.3); }
    .profile-info h2 { font-size: 1.3em; font-weight: 800; display: flex; align-items: center; gap: 8px; margin-bottom: 5px; }
    .verified-badge { color: var(--cyan); font-size: 0.8em; }
    .profile-info p { color: var(--text-muted); font-size: 0.9em; }
    
    .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 20px; }
    .stat-box { background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: 12px; padding: 12px; text-align: center; }
    .stat-box h3 { font-size: 1.2em; font-weight: 800; color: var(--text); }
    .stat-box p { font-size: 0.7em; color: var(--text-muted); text-transform: uppercase; margin-top: 3px; }
    
    .bio-box { background: rgba(0,0,0,0.3); border: 1px solid var(--border); border-radius: 12px; padding: 15px; font-size: 0.85em; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
    .bio-box strong { color: var(--tiktok); display: block; margin-bottom: 8px; font-size: 0.8em; text-transform: uppercase; }
    
    .loader { display: inline-block; width: 18px; height: 18px; border: 3px solid rgba(255,255,255,0.3); border-top-color: white; border-radius: 50%; animation: spin 0.8s linear infinite; }
    @keyframes spin { 100% { transform: rotate(360deg); } }
    
    .error-msg { background: rgba(239,68,68,0.15); border: 1px solid rgba(239,68,68,0.4); color: #ef4444; padding: 12px; border-radius: 12px; text-align: center; font-size: 0.9em; font-weight: 600; display: none; margin-bottom: 20px; }

    .ping-footer { margin-top: auto; padding: 20px; display: flex; justify-content: center; align-items: center; gap: 8px; color: var(--text-muted); font-size: 0.85em; font-weight: 600; }
    .ping-dot { width: 8px; height: 8px; background: #10b981; border-radius: 50%; box-shadow: 0 0 8px #10b981; animation: pulse 2s infinite; }
    @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }

    .top-nav { width: 100%; max-width: 500px; display: flex; justify-content: flex-end; margin-bottom: 10px; }
    .top-nav a { color: var(--text-muted); font-size: 0.8em; text-decoration: none; background: rgba(255,255,255,0.1); padding: 5px 12px; border-radius: 20px; transition: 0.3s; }
    .top-nav a:hover { background: var(--primary); color: white; }
</style>
</head>
<body>
    <div class="top-nav">
        <a href="dashboard.php"><i class="fas fa-mobile-alt"></i> Device Controller</a>
    </div>

    <div class="container">
        <div class="header">
            <h1><i class="fab fa-tiktok" style="color: var(--tiktok);"></i> <span>RenClouds</span></h1>
            <p>TIKTOK PROFILE VIEWER</p>
        </div>

        <div class="card">
            <div class="input-group">
                <i class="fas fa-at"></i>
                <input type="text" id="username" placeholder="Username / Link TikTok" onkeypress="if(event.key==='Enter') stalk()">
            </div>
            <button class="btn btn-tiktok" onclick="stalk()" id="btnStalk">
                <i class="fas fa-search"></i> Stalk Now
            </button>
            <div class="error-msg" id="errorMsg"></div>
        </div>

        <div class="card" id="result">
            <div class="profile-header">
                <img id="avatar" class="profile-avatar" src="" alt="Avatar">
                <div class="profile-info">
                    <h2><span id="nickname"></span> <i class="fas fa-check-circle verified-badge" id="verified" style="display:none;"></i></h2>
                    <p id="usernameDisplay"></p>
                </div>
            </div>
            
            <div class="stats-grid">
                <div class="stat-box"><h3 id="followers">0</h3><p>Followers</p></div>
                <div class="stat-box"><h3 id="following">0</h3><p>Following</p></div>
                <div class="stat-box"><h3 id="likes">0</h3><p>Likes</p></div>
            </div>

            <div class="bio-box">
                <strong><i class="fas fa-quote-left"></i> Bio</strong>
                <span id="bio">-</span>
            </div>
        </div>
    </div>

    <div class="ping-footer">
        <div class="ping-dot" id="pingDot"></div>
        <span>Server Ping: <span id="pingValue" style="color:var(--text);">--</span> ms</span>
    </div>

<script>
const API_URL = '/api-stalker';

async function checkPing() {
    const start = Date.now();
    try {
        await fetch(API_URL + '/stalk?username=test', { method: 'HEAD' });
        const ping = Date.now() - start;
        document.getElementById('pingValue').textContent = ping;
        const dot = document.getElementById('pingDot');
        if(ping < 100) dot.style.background = '#10b981';
        else if(ping < 300) dot.style.background = '#f59e0b';
        else dot.style.background = '#ef4444';
    } catch (e) {
        document.getElementById('pingValue').textContent = 'Offline';
        document.getElementById('pingDot').style.background = '#ef4444';
    }
}
setInterval(checkPing, 5000);
checkPing();

async function stalk() {
    const input = document.getElementById('username').value.trim();
    if (!input) return;
    
    const btn = document.getElementById('btnStalk');
    const errBox = document.getElementById('errorMsg');
    const resultBox = document.getElementById('result');
    
    btn.innerHTML = '<div class="loader"></div> Loading...';
    btn.disabled = true;
    errBox.style.display = 'none';
    resultBox.style.display = 'none';

    try {
        const res = await fetch(`${API_URL}/stalk?username=${encodeURIComponent(input)}`);
        const json = await res.json();
        
        if (json.status && json.data) {
            const user = json.data.user;
            
            document.getElementById('avatar').src = user.avatarLarger || user.avatarMedium || user.avatarThumb || 'https://via.placeholder.com/150';
            document.getElementById('nickname').textContent = user.nickname || user.uniqueId || '-';
            document.getElementById('verified').style.display = user.verified ? 'inline-block' : 'none';
            document.getElementById('usernameDisplay').textContent = '@' + (user.uniqueId || '-');
            
            document.getElementById('followers').textContent = formatNum(user.followerCount || 0);
            document.getElementById('following').textContent = formatNum(user.followingCount || 0);
            document.getElementById('likes').textContent = formatNum(user.heartCount || 0);
            document.getElementById('bio').textContent = user.signature || 'Tidak ada bio.';
            
            resultBox.style.display = 'block';
        } else {
            throw new Error(json.message || 'Gagal stalk profile.');
        }
    } catch (e) {
        errBox.innerHTML = '<i class="fas fa-exclamation-triangle"></i> ' + e.message;
        errBox.style.display = 'block';
    }
    
    btn.innerHTML = '<i class="fas fa-search"></i> Stalk Now';
    btn.disabled = false;
}

function formatNum(n) {
    n = parseInt(n) || 0;
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M';
    if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
    return n.toString();
}
</script>
</body>
</html>
PHPEOF

# ==========================================
# 3. SETUP NGINX (AUTO CONFIG)
# ==========================================
echo -e "${CYAN}[3/5] Setup Nginx...${NC}"
cat > "$NGINX_CONF" << NGINXEOF
server {
    listen 80; listen [::]:80;
    server_name $DOMAIN;
    root $WEB_ROOT; index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /api-stalker/ {
        proxy_pass http://127.0.0.1:3006/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
NGINXEOF

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
nginx -t >/dev/null 2>&1 && systemctl reload nginx
chown -R www-data:www-data "$WEB_ROOT"

clear
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ RENSTALKER v4.0 BERHASIL DI-UPGRADE!       ║${NC}"
echo -e "${GREEN}║  🚀 Double Engine (Siputzx + TikWM)            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}🔗 Buka:${NC} http://$DOMAIN/ (Langsung Stalker)"
echo -e "${CYAN}🔗 Device Controller:${NC} http://$DOMAIN/dashboard.php"
echo ""
echo -e "${YELLOW}💡 Penjelasan:${NC}"
echo -e "   • API tokviewer.net udah mati/kena block."
echo -e "   • Sekarang pake API Siputzx & TikWM (Bebas Cloudflare)."
echo -e "   • Kalau satu API error, otomatis pindah ke API kedua."
echo -e "   • Status Ping di bawah jalan normal."
echo ""
echo -e "${GREEN}🚀 Gasken dibuka & tes stalk!${NC}"
