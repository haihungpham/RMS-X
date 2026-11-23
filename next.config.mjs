/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // `next build` and `next start` run with NODE_ENV=production; keep their output apart
  // from `next dev` so a production preview can run beside the dev server.
  distDir: process.env.RMSX_DIST ?? (process.env.NODE_ENV === "production" ? ".next-prod" : ".next"),
};

export default nextConfig;
