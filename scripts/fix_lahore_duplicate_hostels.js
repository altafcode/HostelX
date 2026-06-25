const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const rootDir = path.resolve(__dirname, '..');
const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(rootDir, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Missing Firebase service account JSON at: ${serviceAccountPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

const updates = {
  seed_lahore_1_scholars_boys_hostel: {
    name: 'Scholars Boys Hostel',
    location: 'Model Town near main campus road',
    images: [
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  CrSwm0iRdi0q9h6QrSwh: {
    name: 'Iqbal Town Campus Boys Residence',
    location: 'Iqbal Town near Punjab University New Campus',
    images: [
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  seed_lahore_2_green_view_girls_residence: {
    name: 'Green View Girls Residence',
    location: 'Johar Town near main campus road',
    images: [
      'https://images.unsplash.com/photo-1616046229478-9901c5536a45?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  seed_lahore_3_model_town_student_inn: {
    name: 'Model Town Student Inn',
    location: 'Garden Town near main campus road',
    images: [
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  seed_lahore_4_liberty_budget_hostel: {
    name: 'Liberty Budget Hostel',
    location: 'Liberty Market near main campus road',
    images: [
      'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  seed_pending_lahore_1: {
    name: 'Lahore Campus Residence Pending',
    location: 'Model Town service lane',
    images: [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1616046229478-9901c5536a45?auto=format&fit=crop&w=1200&q=80',
    ],
  },
  seed_lhr_green_girls: {
    name: 'Canal View Girls Hostel',
    location: 'Wapda Town Main Boulevard near UCP',
    lat: 31.4328,
    lng: 74.2681,
    price: 20500,
    rating: 4.5,
    reviewsCount: 28,
    images: [
      'https://images.unsplash.com/photo-1615873968403-89e068629265?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
    ],
    isRecommended: true,
    isMostPopular: false,
    isRecentlyAdded: true,
  },
  seed_lhr_scholars_boys: {
    name: 'Township Boys Student Lodge',
    location: 'Township Sector C1 near UMT',
    lat: 31.4518,
    lng: 74.3091,
    price: 17000,
    rating: 4.4,
    reviewsCount: 31,
    images: [
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
    ],
    isRecommended: false,
    isMostPopular: true,
    isRecentlyAdded: false,
  },
};

async function updateBookingsForHostel(hostelId, data) {
  const snap = await db.collection('bookings').where('hostelId', '==', hostelId).get();
  if (snap.empty) return 0;

  let count = 0;
  const batch = db.batch();
  snap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      hostelName: data.name,
      hostelImage: data.images[0],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    count += 1;
  });
  await batch.commit();
  return count;
}

async function main() {
  let hostelUpdates = 0;
  let bookingUpdates = 0;

  for (const [hostelId, data] of Object.entries(updates)) {
    const ref = db.collection('hostels').doc(hostelId);
    const doc = await ref.get();
    if (!doc.exists) {
      console.log(`Skipped missing hostel: ${hostelId}`);
      continue;
    }

    await ref.set(
      {
        ...data,
        city: 'Lahore',
        approvalStatus: 'approved',
        updatedAt: new Date().toISOString(),
        duplicateCleanedAt: new Date().toISOString(),
      },
      { merge: true }
    );
    hostelUpdates += 1;
    bookingUpdates += await updateBookingsForHostel(hostelId, data);
    console.log(`Updated ${hostelId}: ${data.name}`);
  }

  console.log(`Done. Updated ${hostelUpdates} Lahore hostel documents.`);
  console.log(`Updated ${bookingUpdates} related booking documents.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
