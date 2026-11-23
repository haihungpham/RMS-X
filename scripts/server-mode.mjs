// Phase B, local: builds and starts RMS-X in server mode (NEXT_PUBLIC_RMSX_MODE=server) in .next-server, beside the
// browser-only build, on port 3004. The server keeps the records in .rmsx-server/state.json.
//   node scripts/server-mode.mjs build
//   node scripts/server-mode.mjs start
import { spawn } from 'node:child_process';

const cmd = process.argv[2] === 'start' ? ['start', '-p', '3004'] : ['build'];
const env = { ...process.env, NEXT_PUBLIC_RMSX_MODE: 'server', RMSX_DIST: '.next-server', RMSX_ALLOW_DEV_SECRET: process.env.RMSX_SESSION_SECRET ? '' : '1', RMSX_INSECURE_COOKIE: '1' };
const child = spawn(process.execPath, ['node_modules/next/dist/bin/next', ...cmd], { stdio: 'inherit', env });
child.on('exit', (code) => process.exit(code ?? 1));
