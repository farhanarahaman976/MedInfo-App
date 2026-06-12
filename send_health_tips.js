const admin = require('firebase-admin');
const cron = require('node-cron');

// Place your Firebase service account JSON in the same folder
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const healthTips = [
  '💧 বেশি পানি পান করুন। Hydration is essential for better health.',
  '😴 ভালো ঘুম = ভালো জীবন — আজ বিশ্রাম নিন। আপনার শরীরও আরামের যোগ্য।',
  '🥗 স্বাস্থ্যকর খাবার খান — ফল ও শাকসবজি দিনচর্যায় রাখুন।',
  '🚶‍♀️ প্রতিদিন ৩০ মিনিট হাঁটুন, এটি আপনার মুড এবং শরীর দুইটাই উজ্জীবিত করবে।',
  '🧼 হাত ধুয়ে নিন — সুস্থ থাকার ছোট কিন্তু শক্তিশালী অভ্যাস।',
  '💊 ওষুধ নিয়মিত নিন এবং ডাক্তারের পরামর্শ মেনে চলুন।',
  '🌞 সকালের সূর্যের আলো নিন, এটি ভিটামিন ডি এবং উন্নত মনোবল দেয়।',
  '🧘‍♂️ স্ট্রেস কমাতে ধ্যান বা শ্বাস-প্রশ্বাস অনুশীলন করুন।',
  '🍎 ভারসাম্যপূর্ণ খাবার খান, এটি স্বাস্থ্যকে দীর্ঘমেয়াদী করে।',
];

function getRandomHealthTip() {
  return healthTips[Math.floor(Math.random() * healthTips.length)];
}

async function sendDailyHealthTip() {
  const message = {
    notification: {
      title: '💊 MedInfo Health Tip',
      body: getRandomHealthTip(),
    },
    topic: 'health-tips',
    android: {
      priority: 'high',
      notification: {
        channelId: 'health_tips',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Health tip sent:', response);
  } catch (error) {
    console.error('Error sending health tip:', error);
  }
}

cron.schedule('0 9 * * *', () => {
  console.log('Sending daily health tip at 09:00 Asia/Dhaka');
  sendDailyHealthTip();
}, {
  timezone: 'Asia/Dhaka',
});

console.log('Health tip scheduler is running.');
