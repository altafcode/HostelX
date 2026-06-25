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
  const snap = await db.collection('hostels').where('city', '==', 'Lahore').get();
  const hostels = snap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => (a.name || '').localeCompare(b.name || ''));

  for (const hostel of hostels) {
    console.log(
      [
        `id=${hostel.id}`,
        `name=${hostel.name}`,
        `location=${hostel.location}`,
        `recommended=${hostel.isRecommended}`,
        `popular=${hostel.isMostPopular}`,
        `image=${(hostel.images || [])[0] || ''}`,
      ].join(' | ')
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
