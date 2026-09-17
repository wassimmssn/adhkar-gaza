/**
 * Adhkar Gaza — Web Push Notification Worker
 * 
 * Routes:
 *   POST /api/subscribe    — Store a push subscription + user preferences
 *   POST /api/unsubscribe  — Remove a push subscription
 *   GET  /api/vapid-key    — Return the public VAPID key
 *   POST /api/test-push    — Send a test notification immediately
 * 
 * Cron (scheduled):
 *   Every 5 minutes — Check all subscriptions, calculate prayer times,
 *                      and send Web Push if it's time for adhkar.
 */

import { sendNotification } from 'web-push-neo';
import { Coordinates, CalculationMethod, PrayerTimes, Madhab } from 'adhan';

// ── CORS Helpers ────────────────────────────────────────────────────────────

function corsHeaders(origin, allowedOrigin) {
  // Allow the specific Pages origin and also localhost for dev
  const allowed = origin === allowedOrigin || origin === 'http://localhost:8080' || origin === 'http://localhost:5000';
  return {
    'Access-Control-Allow-Origin': allowed ? origin : allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function jsonResponse(data, status, origin, allowedOrigin) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders(origin, allowedOrigin),
    },
  });
}

// ── KV Key Helpers ──────────────────────────────────────────────────────────

function subscriptionKey(endpoint) {
  // Create a stable key from the push endpoint URL
  const hash = endpoint.replace(/[^a-zA-Z0-9]/g, '').slice(-64);
  return `sub:${hash}`;
}

function sentTodayKey(subKeyHash, category) {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  return `sent:${today}:${category}:${subKeyHash}`;
}

// ── Prayer Time Calculation ─────────────────────────────────────────────────

function getPrayerTimes(latitude, longitude, date) {
  const coordinates = new Coordinates(latitude, longitude);
  const params = CalculationMethod.MuslimWorldLeague();
  params.madhab = Madhab.Shafi;

  const prayerTimes = new PrayerTimes(coordinates, date, params);
  return {
    fajr: prayerTimes.fajr,
    asr: prayerTimes.asr,
    maghrib: prayerTimes.maghrib,
  };
}

function getReminderTime(prayerTimes, category, type, offset) {
  if (category === 'morning') {
    return new Date(prayerTimes.fajr.getTime() + offset * 60000);
  }
  // Evening
  switch (type) {
    case 'asr_0': return prayerTimes.asr;
    case 'asr_15': return new Date(prayerTimes.asr.getTime() + 15 * 60000);
    case 'asr_30': return new Date(prayerTimes.asr.getTime() + 30 * 60000);
    case 'maghrib_before_30': return new Date(prayerTimes.maghrib.getTime() - 30 * 60000);
    case 'maghrib_after_15': return new Date(prayerTimes.maghrib.getTime() + 15 * 60000);
    default: return new Date(prayerTimes.asr.getTime() + 15 * 60000);
  }
}

// ── Send Push Notification ──────────────────────────────────────────────────

async function sendPush(subscription, payload, env) {
  try {
    await sendNotification(
      {
        endpoint: subscription.endpoint,
        keys: subscription.keys,
      },
      JSON.stringify(payload),
      {
        TTL: 86400, // 24 hours queueing on FCM/push servers if device is offline
        urgency: 'high',
        vapidDetails: {
          subject: env.VAPID_SUBJECT,
          publicKey: env.VAPID_PUBLIC_KEY,
          privateKey: env.VAPID_PRIVATE_KEY,
        },
      }
    );
    return true;
  } catch (err) {
    console.error('Push send error:', err.message, 'Status:', err.statusCode);
    // If subscription is expired or invalid (410 Gone, 404 Not Found), return false to clean up
    if (err.statusCode === 410 || err.statusCode === 404) {
      return false; // Signal to delete this subscription
    }
    throw err; // Throw for transient/auth errors so caller knows it failed
  }
}

// ── Route Handlers ──────────────────────────────────────────────────────────

async function handleSubscribe(request, env, origin) {
  try {
    const body = await request.json();
    const { subscription, preferences } = body;

    if (!subscription || !subscription.endpoint || !subscription.keys) {
      return jsonResponse({ error: 'Invalid subscription' }, 400, origin, env.ALLOWED_ORIGIN);
    }

    const key = subscriptionKey(subscription.endpoint);
    const data = {
      endpoint: subscription.endpoint,
      keys: subscription.keys,
      preferences: preferences || {
        morningEnabled: false,
        morningOffset: 15,
        eveningEnabled: false,
        eveningType: 'asr_15',
        latitude: 31.5,
        longitude: 34.4667,
        city: 'غزة',
        timezone: 'Asia/Gaza',
      },
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await env.PUSH_SUBSCRIPTIONS.put(key, JSON.stringify(data));
    return jsonResponse({ success: true }, 200, origin, env.ALLOWED_ORIGIN);
  } catch (err) {
    console.error('Subscribe error:', err);
    return jsonResponse({ error: 'Server error' }, 500, origin, env.ALLOWED_ORIGIN);
  }
}

async function handleUnsubscribe(request, env, origin) {
  try {
    const body = await request.json();
    const { endpoint } = body;

    if (!endpoint) {
      return jsonResponse({ error: 'Missing endpoint' }, 400, origin, env.ALLOWED_ORIGIN);
    }

    const key = subscriptionKey(endpoint);
    await env.PUSH_SUBSCRIPTIONS.delete(key);
    return jsonResponse({ success: true }, 200, origin, env.ALLOWED_ORIGIN);
  } catch (err) {
    console.error('Unsubscribe error:', err);
    return jsonResponse({ error: 'Server error' }, 500, origin, env.ALLOWED_ORIGIN);
  }
}

async function handleVapidKey(env, origin) {
  return jsonResponse({ publicKey: env.VAPID_PUBLIC_KEY }, 200, origin, env.ALLOWED_ORIGIN);
}

async function handleTestPush(request, env, origin) {
  try {
    const body = await request.json();
    const { subscription } = body;

    if (!subscription || !subscription.endpoint || !subscription.keys) {
      return jsonResponse({ error: 'Invalid subscription' }, 400, origin, env.ALLOWED_ORIGIN);
    }

    const success = await sendPush(subscription, {
      title: 'تنبيه تجريبي 🕌',
      body: 'هذا تنبيه تجريبي من تطبيق أذكار غزة. التنبيهات تعمل بنجاح! ✅',
      category: 'test',
    }, env);

    if (success) {
      return jsonResponse({ success: true }, 200, origin, env.ALLOWED_ORIGIN);
    } else {
      return jsonResponse({ error: 'Push failed - subscription may be expired' }, 410, origin, env.ALLOWED_ORIGIN);
    }
  } catch (err) {
    console.error('Test push error:', err);
    return jsonResponse({ error: err.message || 'Server error' }, 500, origin, env.ALLOWED_ORIGIN);
  }
}

// ── Cron Handler ────────────────────────────────────────────────────────────

async function handleScheduled(env, simulatedNow = null) {
  const now = simulatedNow || new Date();
  console.log(`[Cron] Running at ${now.toISOString()}`);

  // List all subscriptions from KV
  const listResult = await env.PUSH_SUBSCRIPTIONS.list({ prefix: 'sub:' });

  if (!listResult.keys || listResult.keys.length === 0) {
    console.log('[Cron] No subscriptions found.');
    return;
  }

  console.log(`[Cron] Found ${listResult.keys.length} subscription(s).`);

  for (const kvKey of listResult.keys) {
    try {
      const raw = await env.PUSH_SUBSCRIPTIONS.get(kvKey.name);
      if (!raw) continue;

      const sub = JSON.parse(raw);
      const prefs = sub.preferences;

      if (!prefs) continue;

      const prayerTimes = getPrayerTimes(prefs.latitude, prefs.longitude, now);
      const subHash = kvKey.name.replace('sub:', '');

      // ── Morning Check ──
      if (prefs.morningEnabled) {
        const reminderTime = getReminderTime(prayerTimes, 'morning', null, prefs.morningOffset || 15);
        const diffMinutes = (now - reminderTime) / 60000;
        console.log(`[Cron] Morning Check [${subHash.slice(0,8)}]: now=${now.toISOString()}, reminder=${reminderTime.toISOString()}, diff=${diffMinutes.toFixed(2)}m`);

        // Send if we're within 0-60 minutes after the reminder time and haven't sent today
        if (diffMinutes >= 0 && diffMinutes < 60) {
          const sentKey = sentTodayKey(subHash, 'morning');
          const alreadySent = await env.PUSH_SUBSCRIPTIONS.get(sentKey);

          if (!alreadySent) {
            const success = await sendPush(sub, {
              title: 'أذكار الصباح ☀️',
              body: 'حان الآن وقت قراءة أذكار الصباح. حافظ على وردك اليومي.',
              category: 'morning',
            }, env);

            if (success) {
              // Mark as sent for today (expires at midnight + 2h buffer = 26h TTL)
              await env.PUSH_SUBSCRIPTIONS.put(sentKey, '1', { expirationTtl: 93600 });
              console.log(`[Cron] Morning push sent to ${subHash.slice(0, 8)}...`);
            } else {
              // Subscription is dead, clean up
              await env.PUSH_SUBSCRIPTIONS.delete(kvKey.name);
              console.log(`[Cron] Removed dead subscription ${subHash.slice(0, 8)}...`);
            }
          } else {
            console.log(`[Cron] Morning already sent to ${subHash.slice(0, 8)} today.`);
          }
        }
      }

      // ── Evening Check ──
      if (prefs.eveningEnabled) {
        const reminderTime = getReminderTime(prayerTimes, 'evening', prefs.eveningType || 'asr_15', 0);
        const diffMinutes = (now - reminderTime) / 60000;
        console.log(`[Cron] Evening Check [${subHash.slice(0,8)}]: now=${now.toISOString()}, reminder=${reminderTime.toISOString()}, diff=${diffMinutes.toFixed(2)}m`);

        if (diffMinutes >= 0 && diffMinutes < 60) {
          const sentKey = sentTodayKey(subHash, 'evening');
          const alreadySent = await env.PUSH_SUBSCRIPTIONS.get(sentKey);

          if (!alreadySent) {
            const success = await sendPush(sub, {
              title: 'أذكار المساء 🌙',
              body: 'حان الآن وقت قراءة أذكار المساء. حصّن نفسك بذكر الله.',
              category: 'evening',
            }, env);

            if (success) {
              await env.PUSH_SUBSCRIPTIONS.put(sentKey, '1', { expirationTtl: 93600 });
              console.log(`[Cron] Evening push sent to ${subHash.slice(0, 8)}...`);
            } else {
              await env.PUSH_SUBSCRIPTIONS.delete(kvKey.name);
              console.log(`[Cron] Removed dead subscription ${subHash.slice(0, 8)}...`);
            }
          } else {
            console.log(`[Cron] Evening already sent to ${subHash.slice(0, 8)} today.`);
          }
        }
      }
    } catch (err) {
      console.error(`[Cron] Error processing ${kvKey.name}:`, err);
    }
  }
}

// ── Main Export ──────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin') || '';

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(origin, env.ALLOWED_ORIGIN),
      });
    }

    // Route
    const path = url.pathname;

    if (path === '/api/vapid-key' && request.method === 'GET') {
      return handleVapidKey(env, origin);
    }
    if (path === '/api/subscribe' && request.method === 'POST') {
      return handleSubscribe(request, env, origin);
    }
    if (path === '/api/unsubscribe' && request.method === 'POST') {
      return handleUnsubscribe(request, env, origin);
    }
    if (path === '/api/test-push' && request.method === 'POST') {
      return handleTestPush(request, env, origin);
    }
    if (path === '/api/dump-subs' && request.method === 'GET') {
      try {
        const listResult = await env.PUSH_SUBSCRIPTIONS.list({ prefix: 'sub:' });
        const subs = [];
        for (const kvKey of listResult.keys) {
          const raw = await env.PUSH_SUBSCRIPTIONS.get(kvKey.name);
          subs.push({ name: kvKey.name, data: JSON.parse(raw) });
        }
        return jsonResponse({ subs }, 200, origin, env.ALLOWED_ORIGIN);
      } catch (err) {
        return jsonResponse({ error: err.message }, 500, origin, env.ALLOWED_ORIGIN);
      }
    }
    if (path === '/api/test-cron' && request.method === 'GET') {
      try {
        const urlObj = new URL(request.url);
        const timeParam = urlObj.searchParams.get('time');
        const simulatedNow = timeParam ? new Date(timeParam) : null;
        
        const logs = [];
        const originalLog = console.log;
        const originalError = console.error;
        console.log = (...args) => { logs.push('[LOG] ' + args.join(' ')); originalLog(...args); };
        console.error = (...args) => { logs.push('[ERR] ' + args.join(' ')); originalError(...args); };
        
        await handleScheduled(env, simulatedNow);
        
        console.log = originalLog;
        console.error = originalError;
        return jsonResponse({ success: true, logs }, 200, origin, env.ALLOWED_ORIGIN);
      } catch (err) {
        return jsonResponse({ error: err.toString(), stack: err.stack }, 500, origin, env.ALLOWED_ORIGIN);
      }
    }

    return jsonResponse({ error: 'Not found' }, 404, origin, env.ALLOWED_ORIGIN);
  },

  async scheduled(event, env, ctx) {
    ctx.waitUntil(handleScheduled(env));
  },
};
