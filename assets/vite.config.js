import { defineConfig } from 'vite';

export default defineConfig(({ command }) => {
  maybeCloseStdin(command);
  return {
    build: {
      outDir: '../priv/static',
      rollupOptions: {
        input: ['src/main.js', 'src/style.css'],
        output: {
          entryFileNames: `assets/[name].js`,
          chunkFileNames: `assets/[name].js`,
          assetFileNames: `assets/[name].[ext]`,
        },
      },
    },
  };
});

function maybeCloseStdin(command) {
  if (command == 'build') return;
  process.stdin.on('close', () => {
    process.exit(0);
  });
  process.stdin.resume();
}
