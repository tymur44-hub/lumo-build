const { app, BrowserWindow, session, shell, Menu, protocol, net, Tray } = require('electron');
const path = require('path');
const { pathToFileURL } = require('url');
const SHARE = 'https://volshebny-mir.ru/page322172009.html';
protocol.registerSchemesAsPrivileged([{ scheme: 'lumo', privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true, stream: true } }]);
if (!app.requestSingleInstanceLock()) app.quit();
let win;
function create() {
  Menu.setApplicationMenu(null);
  const fs = require('fs');
  protocol.handle('lumo', (req) => {
    const u = new URL(req.url);
    if (u.pathname !== '/' && u.pathname !== '/index.html') return new Response('not found', { status: 404 });
    // ссылки на профиль должны вести на сайт, а не на внутренний адрес приложения
    const html = fs.readFileSync(path.join(__dirname, 'app', 'index.html'), 'utf8').split('location.origin+location.pathname').join(JSON.stringify(SHARE));
    return new Response(html, { headers: { 'content-type': 'text/html; charset=utf-8' } });
  });
  win = new BrowserWindow({ width: 1100, height: 760, minWidth: 380, minHeight: 520, title: 'Lumo', icon: path.join(__dirname, 'icon.png'),
    backgroundColor: '#0c0d1a', autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, backgroundThrottling: false } });
  const ok = ['media', 'notifications', 'fullscreen', 'clipboard-read', 'clipboard-sanitized-write', 'display-capture'];
  session.defaultSession.setPermissionRequestHandler((wc, p, cb) => cb(ok.includes(p)));
  session.defaultSession.setPermissionCheckHandler((wc, p) => ok.includes(p));
  win.loadURL('lumo://app/index.html');
  if (process.env.LUMO_SMOKE) {
    win.webContents.on('did-finish-load', async () => {
      const n = await win.webContents.executeJavaScript("document.querySelectorAll('*').length + ' ' + document.title + ' ' + location.href");
      console.log('SMOKE-OK ' + n); app.exit(0);
    });
    win.webContents.on('did-fail-load', (_e, c, d) => { console.log('SMOKE-FAIL ' + c + ' ' + d); app.exit(1); });
    setTimeout(() => { console.log('SMOKE-TIMEOUT'); app.exit(2); }, 60000);
  }
  win.webContents.setWindowOpenHandler(({ url }) => { if (/^https?:/.test(url)) shell.openExternal(url); return { action: 'deny' }; });
  win.webContents.on('will-navigate', (e, url) => { if (!url.startsWith('lumo://')) { e.preventDefault(); if (/^https?:/.test(url)) shell.openExternal(url); } });
}
app.on('second-instance', () => { if (win) { if (win.isMinimized()) win.restore(); win.focus(); } });
app.whenReady().then(create);
app.on('window-all-closed', () => app.quit());
