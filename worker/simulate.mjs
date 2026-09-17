import { Coordinates, CalculationMethod, PrayerTimes, Madhab } from 'adhan';

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

// Simulate for yesterday evening (July 19)
const lat = 36.6381616;
const lng = 2.7669757;

console.log("Simulating July 19 evening:");
for (let h = 18; h <= 19; h++) {
  for (let m = 0; m < 60; m += 5) {
    // 18:00 UTC to 19:55 UTC (which is 19:00 to 20:55 local)
    const workerNow = new Date(Date.UTC(2026, 6, 19, h, m, 0)); // month is 0-indexed, 6=July
    
    // Worker does:
    const prayerTimes = getPrayerTimes(lat, lng, workerNow);
    const reminderTime = getReminderTime(prayerTimes, 'evening', 'maghrib_before_30', 0);
    
    const diffMinutes = (workerNow - reminderTime) / 60000;
    
    if (diffMinutes >= 0 && diffMinutes < 60) {
       console.log(`[TRIGGERED] At worker time ${workerNow.toISOString()} (diff: ${diffMinutes.toFixed(2)}m) -> Reminder is at ${reminderTime.toISOString()}`);
    } else if (h === 18 && m === 35) {
       console.log(`[DEBUG] At worker time ${workerNow.toISOString()} -> Reminder is at ${reminderTime.toISOString()} (diff: ${diffMinutes.toFixed(2)}m)`);
    }
  }
}

console.log("\nSimulating July 20 morning (Fajr + 15 min):");
for (let h = 2; h <= 4; h++) {
  for (let m = 0; m < 60; m += 5) {
    const workerNow = new Date(Date.UTC(2026, 6, 20, h, m, 0)); 
    
    const prayerTimes = getPrayerTimes(lat, lng, workerNow);
    const reminderTime = getReminderTime(prayerTimes, 'morning', null, 15);
    
    const diffMinutes = (workerNow - reminderTime) / 60000;
    
    if (diffMinutes >= 0 && diffMinutes < 60) {
       console.log(`[TRIGGERED] At worker time ${workerNow.toISOString()} (diff: ${diffMinutes.toFixed(2)}m) -> Reminder is at ${reminderTime.toISOString()}`);
    } else if (h === 3 && m === 15) {
       console.log(`[DEBUG] At worker time ${workerNow.toISOString()} -> Reminder is at ${reminderTime.toISOString()} (diff: ${diffMinutes.toFixed(2)}m)`);
    }
  }
}
