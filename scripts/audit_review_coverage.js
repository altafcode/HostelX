const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const rootDir = path.resolve(__dirname, '..');
const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(rootDir, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(`Missing Firebase service account JSON at:\n${serviceAccountPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

async function main() {
  const [hostelsSnapshot, reviewsSnapshot] = await Promise.all([
    db.collection('hostels').get(),
    db.collection('reviews').get(),
  ]);

  const reviewCounts = new Map();
  reviewsSnapshot.docs.forEach((doc) => {
    const hostelId = doc.data().hostelId;
    if (!hostelId) return;
    reviewCounts.set(hostelId, (reviewCounts.get(hostelId) || 0) + 1);
  });

  const approvedHostels = hostelsSnapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((hostel) => hostel.approvalStatus === 'approved')
    .sort((a, b) => `${a.city}${a.name}`.localeCompare(`${b.city}${b.name}`));

  const missing = approvedHostels.filter(
    (hostel) => (reviewCounts.get(hostel.id) || 0) === 0
  );

  console.log(`Approved hostels: ${approvedHostels.length}`);
  console.log(`Review documents: ${reviewsSnapshot.size}`);
  console.log(`Approved hostels with zero matching reviews: ${missing.length}`);

  if (missing.length > 0) {
    console.log('\nMissing review coverage:');
    missing.forEach((hostel) => {
      console.log(`- ${hostel.city}: ${hostel.name} (${hostel.id})`);
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
