import Foundation

public enum WebUIHTML {
    public static func getContent(hostName: String, authToken: String = "") -> String {
        return """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Android File Transfer</title>
<style>
  :root {
    --bg-main: #0a0d14;
    --bg-card: #141923;
    --bg-card-hover: #1c2333;
    --primary: #3b82f6;
    --primary-gradient: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
    --accent-emerald: #10b981;
    --accent-cyan: #06b6d4;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --text-muted: #64748b;
    --border: rgba(255, 255, 255, 0.08);
    --border-active: rgba(59, 130, 246, 0.5);
    --radius-lg: 18px;
    --radius-md: 12px;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-tap-highlight-color: transparent; }
  body { background: var(--bg-main); color: var(--text-primary); min-height: 100vh; padding: 16px; padding-bottom: 80px; }
  
  /* Top App Bar */
  .header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; padding: 12px 16px; background: var(--bg-card); border-radius: var(--radius-lg); border: 1px solid var(--border); }
  .header-left { display: flex; align-items: center; gap: 12px; }
  .logo-icon { width: 40px; height: 40px; border-radius: 10px; background: var(--primary-gradient); display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 4px 14px rgba(59,130,246,0.3); }
  .title-group h1 { font-size: 17px; font-weight: 700; }
  .title-group p { font-size: 12px; color: var(--text-secondary); }
  .badge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; background: rgba(16,185,129,0.15); color: #34d399; border: 1px solid rgba(16,185,129,0.3); }
  .badge-dot { width: 7px; height: 7px; border-radius: 50%; background: #34d399; box-shadow: 0 0 8px #34d399; }

  /* Navigation Tabs */
  .tabs { display: flex; background: var(--bg-card); border-radius: 14px; padding: 4px; margin-bottom: 20px; border: 1px solid var(--border); }
  .tab-btn { flex: 1; padding: 10px; border: none; background: transparent; color: var(--text-secondary); font-size: 13px; font-weight: 600; border-radius: 10px; cursor: pointer; transition: all 0.2s; display: flex; align-items: center; justify-content: center; gap: 6px; }
  .tab-btn.active { background: var(--primary-gradient); color: white; box-shadow: 0 4px 12px rgba(59,130,246,0.3); }

  /* Cards */
  .card { background: var(--bg-card); border-radius: var(--radius-lg); border: 1px solid var(--border); padding: 20px; margin-bottom: 16px; }
  .card-title { font-size: 15px; font-weight: 700; margin-bottom: 6px; display: flex; align-items: center; gap: 8px; }
  .card-subtitle { font-size: 12px; color: var(--text-secondary); margin-bottom: 16px; }

  /* Upload Area */
  .drop-zone { border: 2px dashed rgba(59,130,246,0.4); border-radius: var(--radius-md); padding: 32px 16px; text-align: center; background: rgba(59,130,246,0.03); cursor: pointer; transition: all 0.2s; }
  .drop-zone:active { background: rgba(59,130,246,0.1); border-color: var(--primary); }
  .drop-icon { font-size: 38px; margin-bottom: 10px; }
  .drop-zone h3 { font-size: 15px; font-weight: 600; margin-bottom: 4px; }
  .drop-zone p { font-size: 12px; color: var(--text-muted); }
  #fileInput { display: none; }

  /* Speed Gauge Widget */
  .gauge-box { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 16px 0; }
  .gauge-speed { font-size: 42px; font-weight: 800; background: linear-gradient(135deg, #60a5fa, #34d399); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
  .gauge-unit { font-size: 14px; font-weight: 600; color: var(--text-secondary); margin-top: -4px; margin-bottom: 12px; }
  
  /* Progress Bar */
  .progress-track { width: 100%; height: 10px; background: rgba(255,255,255,0.08); border-radius: 8px; overflow: hidden; margin-bottom: 12px; }
  .progress-fill { height: 100%; width: 0%; background: var(--primary-gradient); border-radius: 8px; transition: width 0.2s; }
  .stat-row { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-secondary); margin-bottom: 4px; }
  .stat-val { font-weight: 600; color: var(--text-primary); }

  /* Buttons */
  .btn { width: 100%; padding: 14px; border: none; border-radius: var(--radius-md); font-size: 14px; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; transition: all 0.2s; }
  .btn-primary { background: var(--primary-gradient); color: white; box-shadow: 0 4px 14px rgba(59,130,246,0.35); }
  .btn-primary:active { transform: scale(0.98); }
  .btn-emerald { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; box-shadow: 0 4px 14px rgba(16,185,129,0.35); }
  .btn-secondary { background: rgba(255,255,255,0.08); color: var(--text-primary); margin-top: 10px; }

  /* File Lists */
  .file-list { display: flex; flex-direction: column; gap: 8px; }
  .file-item { display: flex; align-items: center; justify-content: space-between; padding: 12px; background: rgba(255,255,255,0.03); border-radius: var(--radius-md); border: 1px solid var(--border); }
  .file-info { display: flex; align-items: center; gap: 10px; overflow: hidden; }
  .file-glyph { font-size: 22px; }
  .file-name { font-size: 13px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 170px; }
  .file-size { font-size: 11px; color: var(--text-muted); }
  .btn-download { padding: 6px 12px; font-size: 12px; font-weight: 600; border-radius: 8px; border: none; background: rgba(59,130,246,0.2); color: #60a5fa; cursor: pointer; }

  /* Selected Files Preview */
  .selected-files { margin-top: 12px; display: flex; flex-direction: column; gap: 6px; }
  .tag { font-size: 12px; background: rgba(255,255,255,0.06); padding: 6px 10px; border-radius: 6px; display: flex; justify-content: space-between; }
</style>
</head>
<body>

  <!-- Top App Bar -->
  <div class="header">
    <div class="header-left">
      <div class="logo-icon">📱</div>
      <div class="title-group">
        <h1>Android Transfer</h1>
        <p>Connected to \(hostName)</p>
      </div>
    </div>
    <div class="badge">
      <div class="badge-dot"></div>
      <span>Wi-Fi 7 / 6E</span>
    </div>
  </div>

  <!-- Navigation Tabs -->
  <div class="tabs">
    <button class="tab-btn active" onclick="switchTab('upload')">⬆️ Upload to Mac</button>
    <button class="tab-btn" onclick="switchTab('download')">⬇️ Download</button>
    <button class="tab-btn" onclick="switchTab('benchmark')">⚡ Speed Test</button>
  </div>

  <!-- Tab 1: Upload (Write to Mac) -->
  <div id="tab-upload">
    <div class="card">
      <div class="card-title"><span>📤</span> Write Files to Mac</div>
      <div class="card-subtitle">Fast direct transfer of Photos, 4K/8K Videos, and Documents</div>
      
      <div class="drop-zone" onclick="document.getElementById('fileInput').click()">
        <div class="drop-icon">📁</div>
        <h3>Select Files on Phone</h3>
        <p>Tap here to browse Gallery or Files</p>
        <input type="file" id="fileInput" multiple onchange="onFilesSelected(event)">
      </div>

      <div class="selected-files" id="selectedFilesList"></div>

      <div style="margin-top: 16px;">
        <button class="btn btn-primary" id="btnUpload" onclick="startUpload()" disabled>
          <span>🚀</span> Start Transfer to Mac
        </button>
      </div>
    </div>

    <!-- Live Upload Speed Card -->
    <div class="card" id="uploadProgressCard" style="display: none;">
      <div class="card-title"><span>⚡</span> Transferring to Mac...</div>
      
      <div class="gauge-box">
        <div class="gauge-speed" id="uploadSpeedNum">0.0</div>
        <div class="gauge-unit">MB/s (MegaBytes / sec)</div>
      </div>

      <div class="progress-track">
        <div class="progress-fill" id="uploadProgressBar"></div>
      </div>

      <div class="stat-row">
        <span>Transferred</span>
        <span class="stat-val" id="uploadBytesText">0 MB / 0 MB</span>
      </div>
      <div class="stat-row">
        <span>Progress</span>
        <span class="stat-val" id="uploadPercentText">0%</span>
      </div>
      <div class="stat-row">
        <span>Time Remaining</span>
        <span class="stat-val" id="uploadEtaText">Calculating...</span>
      </div>
    </div>
  </div>

  <!-- Tab 2: Download (Read from Mac) -->
  <div id="tab-download" style="display: none;">
    <div class="card">
      <div class="card-title" style="justify-content: space-between;">
        <div style="display:flex; align-items:center; gap:8px;"><span>📥</span> Shared Files on Mac</div>
        <button onclick="loadFileList()" style="background:none; border:none; color:#60a5fa; font-size:12px; font-weight:600; cursor:pointer;">🔄 Refresh</button>
      </div>
      <div class="card-subtitle">Tap Download to read files directly to your phone</div>

      <div class="file-list" id="macFilesList">
        <div style="text-align:center; padding:20px; color:var(--text-muted); font-size:13px;">Loading files...</div>
      </div>
    </div>
  </div>

  <!-- Tab 3: Speed Benchmark -->
  <div id="tab-benchmark" style="display: none;">
    <div class="card">
      <div class="card-title"><span>⚡</span> Read / Write Speed Benchmark</div>
      <div class="card-subtitle">Tests live Wi-Fi throughput between phone and Mac</div>

      <div class="gauge-box">
        <div class="gauge-speed" id="benchSpeedNum">0.0</div>
        <div class="gauge-unit" id="benchStatusText">Ready for test</div>
      </div>

      <div class="progress-track">
        <div class="progress-fill" id="benchProgressBar"></div>
      </div>

      <div class="stat-row" style="margin-top: 12px;">
        <span>Write Speed (Phone ➔ Mac)</span>
        <span class="stat-val" id="benchWriteResult">-- MB/s</span>
      </div>
      <div class="stat-row">
        <span>Read Speed (Mac ➔ Phone)</span>
        <span class="stat-val" id="benchReadResult">-- MB/s</span>
      </div>

      <button class="btn btn-emerald" id="btnBench" onclick="runBenchmark()" style="margin-top: 16px;">
        <span>🔥</span> Start 50MB Speed Test
      </button>
    </div>
  </div>

<script>
  const AUTH_TOKEN = "\(authToken)";
  let selectedFiles = [];

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function switchTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-upload').style.display = 'none';
    document.getElementById('tab-download').style.display = 'none';
    document.getElementById('tab-benchmark').style.display = 'none';

    if (tab === 'upload') {
      document.querySelectorAll('.tab-btn')[0].classList.add('active');
      document.getElementById('tab-upload').style.display = 'block';
    } else if (tab === 'download') {
      document.querySelectorAll('.tab-btn')[1].classList.add('active');
      document.getElementById('tab-download').style.display = 'block';
      loadFileList();
    } else if (tab === 'benchmark') {
      document.querySelectorAll('.tab-btn')[2].classList.add('active');
      document.getElementById('tab-benchmark').style.display = 'block';
    }
  }

  function formatBytes(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return (bytes / Math.pow(k, i)).toFixed(1) + ' ' + sizes[i];
  }

  function onFilesSelected(e) {
    selectedFiles = Array.from(e.target.files);
    const list = document.getElementById('selectedFilesList');
    list.innerHTML = '';
    
    if (selectedFiles.length > 0) {
      document.getElementById('btnUpload').removeAttribute('disabled');
      selectedFiles.forEach(f => {
        const div = document.createElement('div');
        div.className = 'tag';
        div.innerHTML = '<span>' + escapeHtml(f.name) + '</span><span style="color:#94a3b8">' + formatBytes(f.size) + '</span>';
        list.appendChild(div);
      });
    } else {
      document.getElementById('btnUpload').setAttribute('disabled', 'true');
    }
  }

  async function startUpload() {
    if (selectedFiles.length === 0) return;
    document.getElementById('uploadProgressCard').style.display = 'block';
    document.getElementById('btnUpload').setAttribute('disabled', 'true');

    for (let i = 0; i < selectedFiles.length; i++) {
      const file = selectedFiles[i];
      await uploadSingleFile(file);
    }

    document.getElementById('uploadSpeedNum').innerText = '0.0';
    document.getElementById('uploadEtaText').innerText = 'Complete!';
    alert('All files transferred to Mac successfully!');
    selectedFiles = [];
    document.getElementById('selectedFilesList').innerHTML = '';
    document.getElementById('btnUpload').removeAttribute('disabled');
  }

  function uploadSingleFile(file) {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      const startTime = Date.now();
      let lastTime = startTime;
      let lastLoaded = 0;

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const now = Date.now();
          const percent = ((e.loaded / e.total) * 100).toFixed(0);
          document.getElementById('uploadProgressBar').style.width = percent + '%';
          document.getElementById('uploadPercentText').innerText = percent + '%';
          document.getElementById('uploadBytesText').innerText = formatBytes(e.loaded) + ' / ' + formatBytes(e.total);

          const timeDiff = (now - lastTime) / 1000;
          if (timeDiff >= 0.3) {
            const bytesDiff = e.loaded - lastLoaded;
            const speedMBs = (bytesDiff / timeDiff) / (1024 * 1024);
            document.getElementById('uploadSpeedNum').innerText = speedMBs.toFixed(1);
            
            const remainingBytes = e.total - e.loaded;
            const etaSec = speedMBs > 0 ? (remainingBytes / (speedMBs * 1024 * 1024)).toFixed(0) : 0;
            document.getElementById('uploadEtaText').innerText = etaSec + 's remaining';

            lastTime = now;
            lastLoaded = e.loaded;
          }
        }
      };

      xhr.onload = () => {
        if (xhr.status === 200) resolve();
        else reject(new Error('Upload failed'));
      };
      xhr.onerror = () => reject(new Error('Network error'));

      xhr.open('POST', '/api/upload?token=' + encodeURIComponent(AUTH_TOKEN) + '&name=' + encodeURIComponent(file.name) + '&size=' + file.size, true);
      xhr.setRequestHeader('X-Auth-Token', AUTH_TOKEN);
      xhr.send(file);
    });
  }

  async function loadFileList() {
    const container = document.getElementById('macFilesList');
    try {
      const res = await fetch('/api/files?token=' + encodeURIComponent(AUTH_TOKEN), {
        headers: { 'X-Auth-Token': AUTH_TOKEN }
      });
      const files = await res.json();
      container.innerHTML = '';
      if (files.length === 0) {
        container.innerHTML = '<div style="text-align:center; padding:20px; color:var(--text-muted); font-size:13px;">No files shared yet on Mac.<br>Drop files into ~/Downloads/AndroidFileTransfer/SharedWithPhone</div>';
        return;
      }
      files.forEach(f => {
        const item = document.createElement('div');
        item.className = 'file-item';
        item.innerHTML = `
          <div class="file-info">
            <div class="file-glyph">📄</div>
            <div>
              <div class="file-name">${escapeHtml(f.name)}</div>
              <div class="file-size">${escapeHtml(f.formattedSize)}</div>
            </div>
          </div>
          <button class="btn-download" onclick="downloadFile('${encodeURIComponent(f.name)}')">⬇️ Read</button>
        `;
        container.appendChild(item);
      });
    } catch(err) {
      container.innerHTML = '<div style="color:#ef4444; padding:10px;">Failed to load file list</div>';
    }
  }

  function downloadFile(name) {
    window.location.href = '/api/download?token=' + encodeURIComponent(AUTH_TOKEN) + '&name=' + name;
  }

  async function runBenchmark() {
    const btn = document.getElementById('btnBench');
    btn.setAttribute('disabled', 'true');
    const speedEl = document.getElementById('benchSpeedNum');
    const statusEl = document.getElementById('benchStatusText');
    const bar = document.getElementById('benchProgressBar');

    // 1. Test Write Speed (Phone to Mac) - 25MB
    statusEl.innerText = 'Testing Write Speed (Phone ➔ Mac)...';
    const chunkSize = 25 * 1024 * 1024;
    const dummy = new Uint8Array(chunkSize);
    
    const startWrite = Date.now();
    await fetch('/api/benchmark/upload?token=' + encodeURIComponent(AUTH_TOKEN), {
      method: 'POST',
      body: dummy,
      headers: {
        'Content-Length': chunkSize.toString(),
        'X-Auth-Token': AUTH_TOKEN
      }
    });
    const writeSec = (Date.now() - startWrite) / 1000;
    const writeMBs = (25 / writeSec).toFixed(1);
    document.getElementById('benchWriteResult').innerText = writeMBs + ' MB/s';
    speedEl.innerText = writeMBs;
    bar.style.width = '50%';

    // 2. Test Read Speed (Mac to Phone) - 25MB
    statusEl.innerText = 'Testing Read Speed (Mac ➔ Phone)...';
    const startRead = Date.now();
    const res = await fetch('/api/benchmark/download?token=' + encodeURIComponent(AUTH_TOKEN) + '&size=25', {
      headers: { 'X-Auth-Token': AUTH_TOKEN }
    });
    await res.arrayBuffer();
    const readSec = (Date.now() - startRead) / 1000;
    const readMBs = (25 / readSec).toFixed(1);
    document.getElementById('benchReadResult').innerText = readMBs + ' MB/s';
    speedEl.innerText = readMBs;
    bar.style.width = '100%';

    statusEl.innerText = 'Benchmark Complete! (Wi-Fi 7 / 6E Active)';
    btn.removeAttribute('disabled');
  }
</script>
</body>
</html>
"""
    }
}

