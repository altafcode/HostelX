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

async function main() {
  const targetName = 'Al-Imran Boys Hostel';
  const replacementName = 'Iqbal Town Campus Boys Residence';

  const exactSnap = await db
    .collection('hostels')
    .where('city', '==', 'Lahore')
    .where('name', '==', targetName)
    .get();

  let targetDoc = exactSnap.docs[0];

  if (!targetDoc) {
    const lahoreSnap = await db
      .collection('hostels')
      .where('city', '==', 'Lahore')
      .get();
    targetDoc = lahoreSnap.docs.find((doc) => {
      const name = (doc.data().name || '').toString().trim().toLowerCase();
      return name === targetName.toLowerCase();
    });
  }

  if (!targetDoc) {
    console.log(`No Lahore listing named "${targetName}" was found. No changes made.`);
    return;
  }

  const existing = targetDoc.data();
  const replacement = {
    name: replacementName,
    location: 'Iqbal Town near Punjab University New Campus',
    city: 'Lahore',
    lat: 31.5007,
    lng: 74.2906,
    price: 19500,
    rating: 4.7,
    reviewsCount: 42,
    images: [
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    ],
    facilities: [
      'WiFi',
      'AC',
      'Mess',
      'Security',
      'Laundry',
      'Generator',
      'CCTV',
      'Study Room',
      'Geyser',
      'Parking',
    ],
    type: 'boys',
    availability: 'open',
    description:
      'Iqbal Town Campus Boys Residence offers furnished rooms, daily mess, reliable WiFi, backup power, CCTV security, and a quiet study environment close to Punjab University and nearby transport routes.',
    approvalStatus: 'approved',
    isRecommended: true,
    isMostPopular: true,
    isRecentlyAdded: true,
    isBudgetFriendly: false,
    minContractMonths: 6,
    securityDeposit: 30000,
    totalRooms: 24,
    rentIncrementPercentage: 10,
    roomConfigurations: [
      { type: 'Single Room', count: 4, price: 24500 },
      { type: '2 Seater', count: 8, price: 19500 },
      { type: '3 Seater', count: 7, price: 16500 },
      { type: '4 Seater', count: 5, price: 14000 },
    ],
    ownerId: existing.ownerId || '',
    ownerName: existing.ownerName || 'Ali Raza',
    ownerPhone: existing.ownerPhone || '03001234567',
    ownerWhatsapp: existing.ownerWhatsapp || existing.ownerPhone || '03001234567',
    documentUrls: existing.documentUrls || {},
    replacedListingName: targetName,
    updatedAt: new Date().toISOString(),
    seeded: true,
  };

  await targetDoc.ref.set(replacement, { merge: true });

  console.log(`Replaced Lahore listing "${targetName}" with "${replacementName}".`);
  console.log(`Document ID: ${targetDoc.id}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
