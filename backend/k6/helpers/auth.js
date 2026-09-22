import http from 'k6/http';
import { check } from 'k6';
import { API_PREFIX, USER_EMAIL, USER_PASSWORD, ADMIN_EMAIL, ADMIN_PASSWORD, getHeaders, errorRate } from './config.js';

// In-memory token cache per Virtual User (VU) to avoid repeated login overhead
const tokenCache = {};

/**
 * Authenticates with the API and returns the JWT token.
 * Falls back to auto-registration if the account does not exist yet.
 */
export function login(email, password, role = 'user') {
  const loginPayload = JSON.stringify({
    email: email,
    password: password,
  });

  const res = http.post(`${API_PREFIX}/auth/login`, loginPayload, {
    headers: getHeaders(),
    tags: { name: 'POST /auth/login' },
  });

  let token = null;

  if (res.status === 200) {
    try {
      const body = JSON.parse(res.body);
      token = body.data && body.data.token ? body.data.token : null;
    } catch (e) {
      // ignore
    }
  } else if (res.status === 401 || res.status === 404) {
    // Attempt registration if user does not exist
    const regPayload = JSON.stringify({
      name: role === 'admin' ? 'Admin LoadTester' : 'Creator LoadTester',
      email: email,
      password: password,
    });

    const regRes = http.post(`${API_PREFIX}/auth/register`, regPayload, {
      headers: getHeaders(),
      tags: { name: 'POST /auth/register' },
    });

    if (regRes.status === 201 || regRes.status === 200) {
      try {
        const body = JSON.parse(regRes.body);
        token = body.data && body.data.token ? body.data.token : null;
      } catch (e) {
        // ignore
      }
    }
  }

  const success = check(res, {
    'Auth succeeded or token obtained': () => token !== null,
  });

  if (!success && token === null) {
    console.error(`[k6 Auth Failed] URL: ${API_PREFIX}/auth/login | Status: ${res.status} | Error: ${res.error || 'None'} | Body: ${res.body}`);
    errorRate.add(1);
  } else {
    errorRate.add(0);
  }

  return token;
}

/**
 * Retrieves a cached token for the current VU or logs in if not cached.
 */
export function getAuthToken(role = 'user') {
  const email = role === 'admin' ? ADMIN_EMAIL : USER_EMAIL;
  const password = role === 'admin' ? ADMIN_PASSWORD : USER_PASSWORD;

  if (!tokenCache[email]) {
    tokenCache[email] = login(email, password, role);
  }

  return tokenCache[email];
}
