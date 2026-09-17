import { Coordinates, CalculationMethod, PrayerTimes, Madhab } from 'adhan';

// Force UTC timezone for this process to simulate Cloudflare Worker
process.env.TZ = 'UTC';

const now = new Date(); // Current UTC time

const coords = new Coordinates(31.5, 34.4667);
const params = CalculationMethod.MuslimWorldLeague();
params.madhab = Madhab.Shafi;

const prayerTimes = new PrayerTimes(coords, now, params);

console.log('Current time (UTC):', now.toISOString());
console.log('Fajr:', prayerTimes.fajr.toISOString());
console.log('Asr:', prayerTimes.asr.toISOString());
console.log('Maghrib:', prayerTimes.maghrib.toISOString());
