import { defineConfig } from "vite";

export default defineConfig({
  envDir: false,
  server: {
    proxy: {
      "/api": {
        target: `http://127.0.0.1:${process.env.SCHOOL_ADMIN_API_PORT || "4174"}`,
        changeOrigin: true,
      },
    },
  },
});
