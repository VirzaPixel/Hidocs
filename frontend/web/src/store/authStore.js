import { create } from 'zustand';
import {
  TOKEN_KEY,
  REFRESH_TOKEN_KEY,
  USER_KEY,
  saveTokens,
  clearSession,
} from '../lib/apiClient';

function loadUser() {
  try {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export const useAuthStore = create((set) => ({
  user: loadUser(),
  token: localStorage.getItem(TOKEN_KEY) || null,
  refreshToken: localStorage.getItem(REFRESH_TOKEN_KEY) || null,

  // refreshToken diambil dari respons backend: { token, access_token, refresh_token }
  login: (token, user, refreshToken) => {
    const access = saveTokens({ token, refresh_token: refreshToken });
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    set({
      token: access,
      refreshToken: localStorage.getItem(REFRESH_TOKEN_KEY) || null,
      user,
    });
  },

  setUser: (user) => {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    set({ user });
  },

  logout: () => {
    clearSession();
    set({ token: null, refreshToken: null, user: null });
  },
}));
