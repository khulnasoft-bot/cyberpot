import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000', // Backend API server
        changeOrigin: true,              // Needed for some APIs to avoid CORS issues
        secure: false,                   // Add this if backend uses self-signed certs (HTTPS)
        // Optionally add rewrite if backend doesn't expect /api prefix
        // rewrite: (path) => path.replace(/^\/api/, '')
      },
    },
  },
})
