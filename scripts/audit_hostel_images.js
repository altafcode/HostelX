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
  const snap = await db.collection('hostels').get();
  const hostels = snap.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .sort((a, b) => `${a.city}|${a.name}`.localeCompare(`${b.city}|${b.name}`));

  const byImage = new Map();
  for (const hostel of hostels) {
    const primary = (hostel.images || [])[0] || '';
    const list = byImage.get(primary) || [];
    list.push(hostel);
    byImage.set(primary, list);
  }

  console.log(`Hostels: ${hostels.length}`);
  console.log(`Unique primary images: ${byImage.size}`);

  for (const hostel of hostels) {
    console.log(`${hostel.city} | ${hostel.name} | ${hostel.id} | ${(hostel.images || [])[0] || ''}`);
  }

  const duplicates = [...byImage.entries()].filter(([, list]) => list.length > 1);
  if (duplicates.length === 0) {
    console.log('\nNo duplicate primary images found.');
    return;
  }

  console.log('\nDuplicate primary image groups:');
  for (const [image, list] of duplicates) {
    console.log(`\n${image}`);
    for (const hostel of list) {
      console.log(`- ${hostel.city} | ${hostel.name} | ${hostel.id}`);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
