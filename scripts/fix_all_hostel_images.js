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

const imagePool = [
  'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1554995207-c18c203602cb?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1616046229478-9901c5536a45?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1615873968403-89e068629265?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687644-aac4c3eac7f4?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600210492493-0946911123ea?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600566752355-35792bedcfea?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607688066-890987f18a86?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600210491369-e753d80a41f3?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560184897-ae75f418493e?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560185008-b033106af5c3?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560185127-1902ccdc5094?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560185009-5bf9f2849488?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560448075-bb485b067938?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600047509358-9dc75507daeb?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600573472592-401b489a3cdc?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80&sat=-20',
];

const renameById = {
  seed_isb_capital_boys: {
    name: 'Margalla Boys Residence',
    location: 'I-8 Markaz near metro bus station',
    lat: 33.6682,
    lng: 73.0754,
  },
  seed_isb_pearl_girls: {
    name: 'F-8 Pearl Girls Residence',
    location: 'F-8/1 near Fatima Jinnah Park',
    lat: 33.7051,
    lng: 73.0319,
  },
  seed_khi_ocean_boys: {
    name: 'Gulshan Boys Residence',
    location: 'Gulshan-e-Iqbal Block 7 near university road',
    lat: 24.9219,
    lng: 67.0911,
  },
  seed_khi_sunrise_girls: {
    name: 'DHA Sunrise Girls Hostel',
    location: 'DHA Phase 6 near Khayaban-e-Ittehad',
    lat: 24.7896,
    lng: 67.0667,
  },
};

function rotatedImages(startIndex) {
  const first = imagePool[startIndex % imagePool.length];
  const second = imagePool[(startIndex + 13) % imagePool.length];
  const third = imagePool[(startIndex + 27) % imagePool.length];
  return [first, second, third];
}

async function updateRelatedDocs(hostelId, data) {
  let updatedBookings = 0;
  let updatedComplaints = 0;

  const bookingSnap = await db.collection('bookings').where('hostelId', '==', hostelId).get();
  if (!bookingSnap.empty) {
    const batch = db.batch();
    bookingSnap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        hostelName: data.name,
        hostelImage: data.images[0],
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      updatedBookings += 1;
    });
    await batch.commit();
  }

  const complaintSnap = await db.collection('complaints').where('againstId', '==', hostelId).get();
  if (!complaintSnap.empty) {
    const batch = db.batch();
    complaintSnap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        againstName: data.name,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      updatedComplaints += 1;
    });
    await batch.commit();
  }

  return { updatedBookings, updatedComplaints };
}

async function main() {
  const snap = await db.collection('hostels').get();
  const hostels = snap.docs
    .map((doc) => ({ ref: doc.ref, id: doc.id, data: doc.data() }))
    .sort((a, b) =>
      `${a.data.city}|${a.data.name}|${a.id}`.localeCompare(
        `${b.data.city}|${b.data.name}|${b.id}`
      )
    );

  if (hostels.length > imagePool.length) {
    throw new Error(`Need ${hostels.length} images but only have ${imagePool.length}.`);
  }

  let updatedHostels = 0;
  let updatedBookings = 0;
  let updatedComplaints = 0;

  for (let index = 0; index < hostels.length; index += 1) {
    const hostel = hostels[index];
    const rename = renameById[hostel.id] || {};
    const images = rotatedImages(index);
    const update = {
      ...rename,
      images,
      updatedAt: new Date().toISOString(),
      uniqueImagesUpdatedAt: new Date().toISOString(),
    };

    await hostel.ref.set(update, { merge: true });
    const related = await updateRelatedDocs(hostel.id, {
      name: rename.name || hostel.data.name,
      images,
    });

    updatedHostels += 1;
    updatedBookings += related.updatedBookings;
    updatedComplaints += related.updatedComplaints;

    console.log(
      `${hostel.data.city} | ${rename.name || hostel.data.name} | ${hostel.id} | ${images[0]}`
    );
  }

  console.log(`Done. Updated ${updatedHostels} hostel image sets.`);
  console.log(`Updated ${updatedBookings} related booking documents.`);
  console.log(`Updated ${updatedComplaints} related complaint documents.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
