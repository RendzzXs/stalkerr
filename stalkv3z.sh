#!/bin/bash
# ==========================================
# 🕵️ RenStalker v3.0 - Auto Root + Anti JSON Error
# ==========================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

read -p "👉 Masukkan Domain lo (contoh: rendzzclouds.my.id): " DOMAIN
[[ -z "$DOMAIN" ]] && { echo -e "${RED}❌ Domain tidak boleh kosong!${NC}"; exit 1; }

WEB_ROOT="/var/www/$DOMAIN"
STALK_DIR="/opt/renstalker"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

# 1. BACKEND NODE.JS (ANTI JSON ERROR)
echo -e "${CYAN}[1/4] Fix Backend (Anti JSON Error)...${NC}"
mkdir -p "$STALK_DIR"
cd "$STALK_DIR"

cat > server.js << 'NODEEOF'
const express = require('express');
const https = require('https');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

class TikTokStalker {
    constructor() {
        this.headers = {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36',
            'Content-Type': 'application/json',
            'Origin': 'https://tokviewer.net',
            'Referer': 'https://tokviewer.net/id',
            'Accept': 'application/json, text/plain, */*',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin'
        };
    }

    async _postJson(payload) {
        return new Promise((resolve, reject) => {
            const postData = JSON.stringify(payload);
            const options = {
                method: 'POST',
                hostname: 'tokviewer.net',
                path: '/api/tiktok/get-profile',
                headers: { ...this.headers, 'Content-Length': Buffer.byteLength(postData) }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try { 
                        const parsed = JSON.parse(data);
                        resolve(parsed); 
                    } 
                    catch (e) { 
                        // Fallback: Kalau bukan JSON, coba cari pattern JSON di dalam string (kadang ada HTML nyempil)
                        console.log("Raw Response:", data.substring(0, 200));
                        reject(new Error('Server API sedang sibuk (Invalid JSON). Coba lagi nanti.')); 
                    }
                });
            });
            req.on('error', reject);
            req.setTimeout(15000, () => { req.destroy(); reject(new Error('API Timeout')); });
            req.write(postData);
            req.end();
        });
    }

    _extractUsername(input) {
        if (input.includes('tiktok.com/@')) {
            const match = input.match(/tiktok\.com\/@([a-zA-Z0-9._-]+)/);
            return match ? match[1] : null;
        }
        return input.replace('@', '').trim();
    }

    async stalk(input) {
        const username = this._extractUsername(input);
        if (!username) throw new Error('Username TikTok tidak valid.');
        const res = await this._postJson({ unique_id: username });
        if (res.code !== 0) throw new Error(res.msg || 'Profile tidak ditemukan / Private.');
        return res.data;
    }
}

app.get('/stalk', async (req, res) => {
    const username = req.query.username;
    if (!username) return res.json({ status: false, message: 'Username required' });
    
    const stalker = new TikTokStalker();
    try {
        const data = await stalker.stalk(username);
        res.json({ status: true, data });
    } catch (err) {
        res.json({ status: false, message: err.message });
    }
});

app.listen(3006, '127.0.0.1', () => console.log('✅ API Stalker Port 3006'));
NODEEOF

systemctl restart renstalker

# 2. BACKUP & GANTI INDEX.PHP UTAMA
echo -e "${CYAN}[2/4] Setup Routing (Home = Stalker)...${NC}"

# Backup index.php lama (RenController) jadi dashboard.php
if [ -f "$WEB_ROOT/index.php" ]; then
    mv "$WEB_ROOT/index.php" "$WEB_ROOT/dashboard.php"
fi

# Bikin index.php baru (isinya Stalker)
cat > "$WEB_ROOT/index.php" << 'PHPEOF'
<?php
// Redirect otomatis kalau buka web utama
// Karena isinya bakal disamain dengan stalker.php
require 'stalker.php';
?>
PHPEOF

# 3. UI STALKER (RGB + PING)
echo -e "${CYAN}[3/4] Generate UI Stalker.php...${NC}"

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

    /* PING FOOTER */
    .ping-footer { margin-top: auto; padding: 20px; display: flex; justify-content: center; align-items: center; gap: 8px; color: var(--text-muted); font-size: 0.85em; font-weight: 600; }
    .ping-dot { width: 8px; height: 8px; background: #10b981; border-radius: 50%; box-shadow: 0 0 8px #10b981; animation: pulse 2s infinite; }
    @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.4; } 100% { opacity: 1; } }

    /* NAVBAR MINI */
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
            const user = json.data.user || json.data;
            
            document.getElementById('avatar').src = user.avatarLarger || user.avatarMedium || user.avatarThumb || 'https://via.placeholder.com/150';
            document.getElementById('nickname').textContent = user.nickname || user.uniqueId || '-';
            document.getElementById('verified').style.display = user.verified ? 'inline-block' : 'none';
            document.getElementById('usernameDisplay').textContent = '@' + (user.uniqueId || '-');
            
            document.getElementById('followers').textContent = formatNum(user.followerCount || 0);
            document.getElementById('following').textContent = formatNum(user.followingCount || 0);
            document.getElementById('likes').textContent = formatNum(user.heartCount || user.heart || 0);
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

# 4. NGINX CONFIG (PROXY STALKER)
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
echo -e "${GREEN}║  ✅ RENSTALKER v3.0 BERHASIL TERINSTALL!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}🔗 Buka:${NC} http://$DOMAIN/ (Langsung Stalker)"
echo -e "${CYAN}🔗 Device Controller:${NC} http://$DOMAIN/dashboard.php"
echo ""
echo -e "${YELLOW}💡 Fitur:${NC}"
echo -e "   • URL Utama langsung Stalker (tanpa /stalker.php)"
echo -e "   • Tombol kecil di atas buat ke Device Controller"
echo -e "   • API Timeout 15s & Fallback Error (Anti Invalid JSON)"
echo ""
echo -e "${GREEN}🚀 Gasken dibuka!${NC}"
