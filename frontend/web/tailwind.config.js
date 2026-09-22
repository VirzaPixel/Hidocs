/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        primary: 'var(--hp-pri)',
        'primary-hover': 'var(--hp-pri-hover)',
        bg: 'var(--app-bg)',
        'bg-secondary': 'var(--app-bg-secondary)',
        surface: 'var(--app-surface)',
        border: 'var(--app-border)',
        text: 'var(--app-text)',
        'text-secondary': 'var(--app-text-secondary)',
        danger: 'var(--app-danger)',
        success: 'var(--app-success)',
        warning: 'var(--app-warning)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
