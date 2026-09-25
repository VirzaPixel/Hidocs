import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

// Apply saved theme immediately to prevent flashing / reverting to light mode on refresh
const savedTheme = localStorage.getItem('hidocs_theme');
if (
  savedTheme === 'dark' ||
  (!savedTheme && window.matchMedia?.('(prefers-color-scheme: dark)').matches)
) {
  document.documentElement.classList.add('dark');
} else {
  document.documentElement.classList.remove('dark');
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
