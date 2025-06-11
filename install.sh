#!/usr/bin/env bash
# =========================================================
# BUILD Realtime Talking-Avatar (LiveKit + D-ID + ElevenLabs)
# =========================================================
# This script scaffolds the entire project in the current
# working directory under ./talking-avatar.
# ---------------------------------------------------------

set -euo pipefail

PROJECT_ROOT="$PWD/talking-avatar"
CLIENT_DIR="$PROJECT_ROOT/client"
SERVER_DIR="$PROJECT_ROOT/server"

echo "▶ Creating folder skeleton…"
mkdir -p "$CLIENT_DIR/ui" "$CLIENT_DIR/assets/flags" \
         "$SERVER_DIR/routes"

# ---------------------------------------------------------
# 1. Package / toolchain
# ---------------------------------------------------------
echo "▶ Initialising PNPM workspace + Vite template…"
pnpm create vite "$PROJECT_ROOT" --template vanilla-ts --no-git

cd "$PROJECT_ROOT"
pnpm add -D tailwindcss postcss autoprefixer
pnpm add fastify @fastify/cors cross-env axios dotenv ws \
         @livekit/server-sdk @livekit/client

# Tailwind config
npx tailwindcss init -p -s

# ---------------------------------------------------------
# 2. Base project files
# ---------------------------------------------------------
cat > .env.example <<'EOF'
# ====== ElevenLabs ======
ELEVENLABS_API_KEY=
ELEVENLABS_VOICE_ID=EXAVITQu4vr4xnSDxMaL

# ======  D-ID  ======
DID_API_KEY=

# ====== LiveKit ======
LIVEKIT_URL=wss://livekit.example.com
LIVEKIT_API_KEY=
LIVEKIT_API_SECRET=
EOF

cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite';
export default defineConfig({ build: { outDir: 'dist' } });
EOF

# ---------------------------------------------------------
# 3. Client placeholders
# ---------------------------------------------------------
# index.html
cat > "$CLIENT_DIR/index.html" <<'EOF'
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Realtime Talking Avatar</title>
<script type="module" src="/main.ts"></script>
<link href="/src/style.css" rel="stylesheet"/>
</head><body class="bg-[#0D1B2A] text-[#E0E5EC] overflow-hidden">
<div id="app"></div>
</body></html>
EOF

# main.ts
cat > "$CLIENT_DIR/main.ts" <<'EOF'
import './style.css'

// UI components
import { AvatarSelector } from './ui/AvatarSelector'
import { LanguageSelector } from './ui/LanguageSelector'
import { MicButton } from './ui/MicButton'

// Mount UI
document.querySelector('#app')!.innerHTML = `
  <div class="flex h-screen">
    <!-- Left Panel -->
    <div class="w-60 p-4 space-y-6">
      <h2 class="text-xl font-bold">CHOOSE AVATAR</h2>
      <div id="avatar-container"></div>
      
      <h2 class="text-xl font-bold mt-8">CHOOSE LANGUAGE</h2>
      <div id="language-container"></div>
    </div>
    
    <!-- Main Panel -->
    <div class="flex-1 bg-[#1B2A41] flex items-center justify-center">
      <video id="video-output" class="w-full max-w-2xl" autoplay playsinline></video>
    </div>
    
    <!-- Right Panel -->
    <div class="w-60 p-4">
      <h2 class="text-xl font-bold">Features</h2>
      <ul class="mt-4 space-y-2">
        <li class="flex items-center">
          <span class="w-3 h-3 bg-[#5F63F2] rounded-full mr-2"></span>
          Face Enhance
        </li>
        <li class="flex items-center">
          <span class="w-3 h-3 bg-[#5F63F2] rounded-full mr-2"></span>
          Lip Sync
        </li>
        <li class="flex items-center text-[#5F63F2] font-bold">
          <span class="w-3 h-3 bg-[#5F63F2] rounded-full mr-2"></span>
          Talking Avatar
        </li>
      </ul>
    </div>
  </div>
  
  <div id="mic-container" class="fixed bottom-8 left-1/2 transform -translate-x-1/2"></div>
`

// Initialize components
AvatarSelector(document.getElementById('avatar-container')!)
LanguageSelector(document.getElementById('language-container')!)
MicButton(document.getElementById('mic-container')!)

console.log('🚀 Talking-Avatar UI loaded')
EOF

# AvatarSelector.ts
cat > "$CLIENT_DIR/ui/AvatarSelector.ts" <<'EOF'
export function AvatarSelector(container: HTMLElement) {
  const avatars = [
    { id: 'ava1', name: 'Anime Girl', thumb: '/avatars/1.png' },
    { id: 'ava2', name: 'Business Man', thumb: '/avatars/2.png' },
    { id: 'ava3', name: 'Cartoon Boy', thumb: '/avatars/3.png' },
  ]
  
  let html = '<div class="space-y-4">'
  avatars.forEach(avatar => {
    html += `
      <div class="bg-[#1B2A41] rounded-xl p-4 cursor-pointer transition hover:border-[#5F63F2] border-2 border-transparent">
        <img src="${avatar.thumb}" alt="${avatar.name}" class="w-full rounded-lg mb-2">
        <p class="text-center">${avatar.name}</p>
      </div>
    `
  })
  html += '</div>'
  
  container.innerHTML = html
}
EOF

# LanguageSelector.ts
cat > "$CLIENT_DIR/ui/LanguageSelector.ts" <<'EOF'
export function LanguageSelector(container: HTMLElement) {
  const languages = [
    { code: 'en', name: 'English', flag: '/flags/us.svg' },
    { code: 'es', name: 'Spanish', flag: '/flags/es.svg' },
    { code: 'fr', name: 'French', flag: '/flags/fr.svg' },
    { code: 'ja', name: 'Japanese', flag: '/flags/jp.svg' },
  ]
  
  let html = '<div class="grid grid-cols-2 gap-3">'
  languages.forEach(lang => {
    html += `
      <button class="flex items-center justify-center p-3 bg-[#1B2A41] rounded-lg hover:bg-[#2a3a54] transition">
        <img src="${lang.flag}" alt="${lang.name}" class="w-6 h-6 mr-2">
        ${lang.name}
      </button>
    `
  })
  html += '</div>'
  
  container.innerHTML = html
}
EOF

# MicButton.ts
cat > "$CLIENT_DIR/ui/MicButton.ts" <<'EOF'
export function MicButton(container: HTMLElement) {
  container.innerHTML = `
    <button id="mic-btn" class="w-16 h-16 rounded-full bg-[#5F63F2] flex items-center justify-center shadow-lg hover:bg-[#4a4fcc] transition">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
      </svg>
    </button>
  `
  
  const micBtn = document.getElementById('mic-btn')!
  let mediaRecorder: MediaRecorder | null = null
  let audioChunks: Blob[] = []
  
  micBtn.addEventListener('mousedown', startRecording)
  micBtn.addEventListener('touchstart', startRecording)
  
  micBtn.addEventListener('mouseup', stopRecording)
  micBtn.addEventListener('touchend', stopRecording)
  
  async function startRecording() {
    micBtn.classList.add('ring-4', 'ring-[#5F63F2]', 'ring-opacity-50')
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    mediaRecorder = new MediaRecorder(stream)
    audioChunks = []
    
    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) audioChunks.push(e.data)
    }
    
    mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(audioChunks, { type: 'audio/webm' })
      await processAudio(audioBlob)
      stream.getTracks().forEach(track => track.stop())
    }
    
    mediaRecorder.start()
  }
  
  function stopRecording() {
    micBtn.classList.remove('ring-4', 'ring-[#5F63F2]', 'ring-opacity-50')
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      mediaRecorder.stop()
    }
  }
  
  async function processAudio(audioBlob: Blob) {
    try {
      // Convert to base64 for API
      const reader = new FileReader()
      reader.readAsDataURL(audioBlob)
      reader.onloadend = async () => {
        const base64Audio = (reader.result as string).split(',')[1]
        
        // 1. Get TTS audio
        const ttsRes = await fetch('http://localhost:8080/tts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ audio: base64Audio })
        })
        const ttsData = await ttsRes.json()
        
        // 2. Create D-ID stream
        const didRes = await fetch('http://localhost:8080/did', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 
            audio: ttsData.audio,
            avatar: 'https://example.com/avatar.png' // Replace with actual
          })
        })
        const didData = await didRes.json()
        
        // 3. Connect to LiveKit
        const tokenRes = await fetch(`http://localhost:8080/token?identity=${Date.now()}`)
        const { token } = await tokenRes.json()
        
        const room = new Livekit.Room()
        await room.connect('wss://livekit.example.com', token)
        
        // 4. Play stream
        const videoEl = document.getElementById('video-output') as HTMLVideoElement
        room.on('trackSubscribed', (track, publication, participant) => {
          if (track.kind === 'video') {
            const mediaStream = new MediaStream([track.mediaStreamTrack])
            videoEl.srcObject = mediaStream
          }
        })
        
        // Subscribe to avatar track
        room.getRemoteParticipants()[0].tracks.forEach((publication) => {
          if (publication.kind === 'video') {
            room.subscribe(publication)
          }
        })
      }
    } catch (err) {
      console.error('Processing error:', err)
    }
  }
}
EOF

# ---------------------------------------------------------
# 4. Server files (Fastify)
# ---------------------------------------------------------
cat > "$SERVER_DIR/index.js" <<'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import dotenv from 'dotenv';
dotenv.config();

const app = Fastify({ logger: true });
await app.register(cors, { 
  origin: ['http://localhost:5173'] 
});

app.register(import('./routes/tts.js'));
app.register(import('./routes/did.js'));
app.register(import('./routes/livekit.js'));

app.listen({ port: 8080, host: '0.0.0.0' }, (err) => {
  if (err) {
    app.log.error(err);
    process.exit(1);
  }
  console.log('API listening on :8080');
});
EOF

# tts.js
cat > "$SERVER_DIR/routes/tts.js" <<'EOF'
import axios from 'axios';
export default async function (f) {
  f.post('/tts', async (req, res) => {
    try {
      const { audio } = req.body;
      const { ELEVENLABS_VOICE_ID, ELEVENLABS_API_KEY } = process.env;
      
      // STT would go here (using audio input)
      // For now we'll use placeholder text
      const text = "Hello! This is a demo of real-time avatar synthesis";
      
      const { data } = await axios.post(
        `https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID}`,
        { text, model_id: 'eleven_multilingual_v2' },
        { 
          headers: { 
            'xi-api-key': ELEVENLABS_API_KEY,
            'Content-Type': 'application/json'
          },
          responseType: 'arraybuffer' 
        }
      );
      
      res.send({ 
        audio: Buffer.from(data).toString('base64') 
      });
    } catch (err) {
      res.status(500).send({ error: 'TTS processing failed' });
    }
  });
}
EOF

# did.js
cat > "$SERVER_DIR/routes/did.js" <<'EOF'
import WebSocket from 'ws';
import axios from 'axios';
export default async function (f) {
  f.post('/did', async (req, res) => {
    try {
      const { audio, avatar } = req.body;
      
      // Create stream
      const streamRes = await axios.post(
        'https://api.d-id.com/talks/streams',
        { source_url: avatar },
        {
          headers: {
            Authorization: `Basic ${process.env.DID_API_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );
      
      const { id: streamId } = streamRes.data;
      const wsUrl = `wss://api.d-id.com/talks/streams/${streamId}`;
      
      // Connect to stream
      const ws = new WebSocket(wsUrl, {
        headers: { Authorization: `Basic ${process.env.DID_API_KEY}` }
      });
      
      ws.on('open', () => {
        ws.send(JSON.stringify({
          type: 'audio',
          audio: `data:audio/mpeg;base64,${audio}`,
          timing: 'word'
        }));
        
        // End stream after sending audio
        setTimeout(() => {
          ws.send(JSON.stringify({ type: 'stop' }));
        }, 500);
      });
      
      ws.on('message', (data) => {
        const msg = JSON.parse(data);
        if (msg.type === 'stream_ended') {
          res.send({ streamUrl: `https://api.d-id.com/talks/streams/${streamId}/sdp` });
          ws.close();
        }
      });
      
      ws.on('error', (err) => {
        res.status(500).send({ error: 'D-ID stream error' });
      });
    } catch (err) {
      res.status(500).send({ error: 'D-ID processing failed' });
    }
  });
}
EOF

# livekit.js
cat > "$SERVER_DIR/routes/livekit.js" <<'EOF'
import { AccessToken } from '@livekit/server-sdk';
export default async function (f) {
  f.get('/token', async (req, res) => {
    try {
      const { identity = 'user' } = req.query;
      const at = new AccessToken(
        process.env.LIVEKIT_API_KEY, 
        process.env.LIVEKIT_API_SECRET, 
        { identity, ttl: '1h' }
      );
      
      at.addGrant({ 
        room: 'default', 
        roomJoin: true,
        canPublish: true,
        canSubscribe: true
      });
      
      res.send({ token: await at.toJwt() });
    } catch (err) {
      res.status(500).send({ error: 'Token generation failed' });
    }
  });
}
EOF

# livekitClient.js
cat > "$SERVER_DIR/livekitClient.js" <<'EOF'
import { LiveKitClient } from '@livekit/client';
import ffmpeg from 'fluent-ffmpeg';
import { PassThrough } from 'stream';

export async function streamDIDToLiveKit(streamUrl) {
  const client = new LiveKitClient(process.env.LIVEKIT_URL);
  await client.connect(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET
  );
  
  const room = client.joinRoom('default');
  const outputStream = new PassThrough();
  
  ffmpeg(streamUrl)
    .inputFormat('sdp')
    .outputFormat('rtp')
    .outputOptions([
      '-payload_type 96',
      '-ssrc 1',
      '-f rtp',
      '-srtp_out_suite AES_CM_128_HMAC_SHA1_80',
      '-srtp_out_params zA+8XQaBq3VdrdFql3Y3kz0jK0Xa9M0vN0jSZoXa'
    ])
    .output('rtp://127.0.0.1:5000?pkt_size=1200')
    .on('end', () => console.log('Stream ended'))
    .on('error', (err) => console.error('Stream error:', err))
    .run();
  
  // Convert RTP to WebRTC (simplified)
  room.publishTrack(outputStream, {
    name: 'avatar-video',
    kind: 'video',
    simulcast: false
  });
}
EOF

# ---------------------------------------------------------
# 5. Tailwind starter CSS
# ---------------------------------------------------------
cat > "$PROJECT_ROOT/src/style.css" <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --brand-primary: #5F63F2;
  --bg-main: #0D1B2A;
  --text-primary: #E0E5EC;
}

body {
  background-color: var(--bg-main);
  color: var(--text-primary);
  font-family: Inter, system-ui, sans-serif;
}

#app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}
EOF

# ---------------------------------------------------------
# 6. Package.json tweaks
# ---------------------------------------------------------
jq '.scripts += {
  "dev": "concurrently -k \"vite --host\" \"node server/index.js\"",
  "build": "vite build",
  "serve": "vite preview"
}' package.json > package.tmp && mv package.tmp package.json

pnpm add -D concurrently jq

echo "✔ Project scaffolded at $PROJECT_ROOT"
echo "📝 Next steps:
1) cp .env.example .env  &&  edit your keys
2) pnpm run dev
3) Open http://localhost:5173 (UI) + http://localhost:8080 (API)"
