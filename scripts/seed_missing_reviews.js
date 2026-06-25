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

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const comments = [
  'Rooms are clean, WiFi is stable, and the staff handles requests quickly.',
  'The location is convenient for classes and daily transport.',
  'Mess timing, laundry, and security are managed professionally.',
  'Good study environment with fair rent and clear booking terms.',
  'The listing matched the real room condition when I visited.',
];

function dateUtc(year, month, day, hour = 9) {
  return new Date(Date.UTC(year, month - 1, day, hour, 0, 0));
}

function formatDate(date) {
  return `${monthNames[date.getUTCMonth()]} ${date.getUTCDate()}, ${date.getUTCFullYear()}`;
}

function safeDocId(value) {
  return String(value).replace(/[^A-Za-z0-9_-]/g, '_');
}

function ratingFor(hostel, index) {
  const base = typeof hostel.rating === 'number' && hostel.rating > 0
    ? hostel.rating
    : 4.3;
  return Number(Math.max(3.8, Math.min(5, base - index * 0.1)).toFixed(1));
}

async function main() {
  const [hostelsSnapshot, reviewsSnapshot, usersSnapshot] = await Promise.all([
    db.collection('hostels').get(),
    db.collection('reviews').get(),
    db.collection('users').where('role', '==', 'tenant').get(),
  ]);

  const tenants = usersSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  if (tenants.length === 0) {
    throw new Error('No tenant users found for review seeding.');
  }

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

  const batch = db.batch();
  let created = 0;
  let updatedHostels = 0;

  approvedHostels.forEach((hostel, hostelIndex) => {
    const existingCount = reviewCounts.get(hostel.id) || 0;
    const missingCount = Math.max(0, 3 - existingCount);

    for (let i = 0; i < missingCount; i += 1) {
      const reviewIndex = existingCount + i;
      const tenant = tenants[(hostelIndex * 5 + reviewIndex) % tenants.length];
      const date = dateUtc(2026, ((hostelIndex + reviewIndex) % 5) + 1, 10 + reviewIndex);
      const ref = db
        .collection('reviews')
        .doc(`coverage_review_${safeDocId(hostel.id)}_${reviewIndex + 1}`);

      batch.set(
        ref,
        {
          hostelId: hostel.id,
          userId: tenant.id,
          userName: tenant.name || tenant.email || 'Verified Tenant',
          rating: ratingFor(hostel, reviewIndex),
          comment: comments[(hostelIndex + reviewIndex) % comments.length],
          date: formatDate(date),
          ownerReply:
            reviewIndex === 1
              ? 'Thank you for sharing your experience. We appreciate the feedback.'
              : null,
          createdAt: admin.firestore.Timestamp.fromDate(date),
          seeded: true,
          seededAt: new Date().toISOString(),
        },
        { merge: true }
      );
      created += 1;
    }

    if (missingCount > 0) {
      const rating = typeof hostel.rating === 'number' && hostel.rating > 0
        ? hostel.rating
        : 4.3;
      const reviewsCount = Math.max(hostel.reviewsCount || 0, existingCount + missingCount);
      batch.set(
        db.collection('hostels').doc(hostel.id),
        {
          rating: Number(rating.toFixed(1)),
          reviewsCount,
          updatedAt: new Date().toISOString(),
        },
        { merge: true }
      );
      updatedHostels += 1;
    }
  });

  if (created > 0 || updatedHostels > 0) {
    await batch.commit();
  }

  console.log(`Created review docs: ${created}`);
  console.log(`Updated hostel summaries: ${updatedHostels}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
