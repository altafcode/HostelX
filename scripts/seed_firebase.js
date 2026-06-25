const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const rootDir = path.resolve(__dirname, '..');
const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(rootDir, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    `Missing Firebase service account JSON at:\n${serviceAccountPath}\n\n` +
      'Download it from Firebase Console > Project settings > Service accounts > Generate new private key, ' +
      'then save it as serviceAccountKey.json in the project root.'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const auth = admin.auth();
const db = admin.firestore();

const password = 'Test@123456';
const commissionRate = 0.10;
const seededAt = new Date().toISOString();
const demoToday = dateUtc(2026, 6, 1);
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

function pad2(value) {
  return String(value).padStart(2, '0');
}

function slug(value) {
  return value
    .toLowerCase()
    .replace(/&/g, 'and')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function dateUtc(year, month, day, hour = 9) {
  return new Date(Date.UTC(year, month - 1, day, hour, 0, 0));
}

function timestamp(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

function formatDate(date) {
  return `${monthNames[date.getUTCMonth()]} ${date.getUTCDate()}, ${date.getUTCFullYear()}`;
}

function monthKey(year, month) {
  return `${year}_${pad2(month)}`;
}

function roomCapacity(roomType) {
  if (roomType.includes('4')) return 4;
  if (roomType.includes('3')) return 3;
  if (roomType.includes('2')) return 2;
  return 1;
}

function addMonths(date, offset) {
  return dateUtc(
    date.getUTCFullYear(),
    date.getUTCMonth() + 1 + offset,
    Math.min(date.getUTCDate(), 28)
  );
}

function buildPaymentHistory(startDate, longHistory) {
  if (!longHistory) return [true];

  const startMonth = startDate.getUTCFullYear() * 12 + startDate.getUTCMonth();
  const paidThrough =
    demoToday.getUTCFullYear() * 12 + demoToday.getUTCMonth();
  const length = Math.max(1, Math.min(12, paidThrough - startMonth + 1));

  return Array.from({ length }, (_, index) => index <= paidThrough - startMonth);
}

async function commitInBatches(operations, label) {
  const chunkSize = 400;
  for (let i = 0; i < operations.length; i += chunkSize) {
    const batch = db.batch();
    operations.slice(i, i + chunkSize).forEach((operation) => {
      batch.set(operation.ref, operation.data, operation.options || { merge: true });
    });
    await batch.commit();
  }
  console.log(`Seeded ${operations.length} ${label}.`);
}

const cityProfiles = [
  {
    city: 'Lahore',
    ownerKey: 'owner_lahore',
    ownerName: 'Ali Raza',
    ownerEmail: 'owner.lahore@hostelx.test',
    phone: '03001234567',
    bankName: 'Meezan Bank',
    iban: 'PK36MEZN0000001122334455',
    lat: 31.5204,
    lng: 74.3587,
    basePrice: 18000,
    areas: ['Model Town', 'Johar Town', 'Garden Town', 'Liberty Market'],
    names: [
      'Scholars Boys Hostel',
      'Green View Girls Residence',
      'Model Town Student Inn',
      'Liberty Budget Hostel',
    ],
  },
  {
    city: 'Islamabad',
    ownerKey: 'owner_islamabad',
    ownerName: 'Sana Malik',
    ownerEmail: 'owner.islamabad@hostelx.test',
    phone: '03111234567',
    bankName: 'HBL',
    iban: 'PK16HABB0000006677889900',
    lat: 33.6844,
    lng: 73.0479,
    basePrice: 23000,
    areas: ['G-10 Markaz', 'F-8/2', 'G-11/3', 'Blue Area'],
    names: [
      'Capital Boys Hostel',
      'Pearl Girls Hostel',
      'G-11 Student Suites',
      'Blue Area Working Hostel',
    ],
  },
  {
    city: 'Karachi',
    ownerKey: 'owner_karachi',
    ownerName: 'Hamza Khan',
    ownerEmail: 'owner.karachi@hostelx.test',
    phone: '03211234567',
    bankName: 'UBL',
    iban: 'PK50UNIL0000009988776655',
    lat: 24.8607,
    lng: 67.0011,
    basePrice: 16000,
    areas: ['Gulshan-e-Iqbal', 'DHA Phase 5', 'North Nazimabad', 'Clifton'],
    names: [
      'Ocean View Boys Hostel',
      'Sunrise Girls Residence',
      'Gulshan Student House',
      'Clifton Executive Hostel',
    ],
  },
  {
    city: 'Rawalpindi',
    ownerKey: 'owner_rawalpindi',
    ownerName: 'Adeel Shah',
    ownerEmail: 'owner.rawalpindi@hostelx.test',
    phone: '03331234567',
    bankName: 'Bank Alfalah',
    iban: 'PK21ALFH0000001122446688',
    lat: 33.5651,
    lng: 73.0169,
    basePrice: 15500,
    areas: ['Saddar', 'Satellite Town', 'Bahria Town Phase 7', 'Commercial Market'],
    names: [
      'Saddar Boys Hostel',
      'Satellite Girls Residence',
      'Bahria Student Lodge',
      'Commercial Market Budget Hostel',
    ],
  },
  {
    city: 'Peshawar',
    ownerKey: 'owner_peshawar',
    ownerName: 'Mariam Afridi',
    ownerEmail: 'owner.peshawar@hostelx.test',
    phone: '03441234567',
    bankName: 'MCB',
    iban: 'PK73MUCB0000005566778899',
    lat: 34.0151,
    lng: 71.5249,
    basePrice: 14500,
    areas: ['University Town', 'Hayatabad Phase 3', 'Saddar Road', 'Tehkal'],
    names: [
      'University Town Boys Hostel',
      'Khyber Girls Residence',
      'Hayatabad Student Lodge',
      'Tehkal Budget Hostel',
    ],
  },
  {
    city: 'Faisalabad',
    ownerKey: 'owner_faisalabad',
    ownerName: 'Noman Javed',
    ownerEmail: 'owner.faisalabad@hostelx.test',
    phone: '03551234567',
    bankName: 'Allied Bank',
    iban: 'PK42ABPA0000009988112233',
    lat: 31.4504,
    lng: 73.1350,
    basePrice: 13500,
    areas: ['Canal Road', 'Madina Town', 'D-Ground', 'University Road'],
    names: [
      'Canal View Boys Hostel',
      'Madina Town Girls Residence',
      'D-Ground Student House',
      'University Road Budget Hostel',
    ],
  },
  {
    city: 'Multan',
    ownerKey: 'owner_multan',
    ownerName: 'Farah Saeed',
    ownerEmail: 'owner.multan@hostelx.test',
    phone: '03661234567',
    bankName: 'Faysal Bank',
    iban: 'PK59FAYS0000004455667788',
    lat: 30.1575,
    lng: 71.5249,
    basePrice: 12500,
    areas: ['Bosan Road', 'Garden Town', 'Multan Cantt', 'Gulgasht Colony'],
    names: [
      'Bosan Road Boys Hostel',
      'Garden Town Girls Residence',
      'Cantt Student Lodge',
      'Gulgasht Budget Hostel',
    ],
  },
];

const adminUser = {
  key: 'admin_main',
  name: 'HostelX Admin',
  email: 'admin@hostelx.test',
  phone: '03009990000',
  city: 'Lahore',
  occupation: 'other',
};

const owners = cityProfiles.map((profile, index) => ({
  key: profile.ownerKey,
  name: profile.ownerName,
  email: profile.ownerEmail,
  phone: profile.phone,
  city: profile.city,
  occupation: 'other',
  joinedDate: formatDate(dateUtc(2025, index + 1, 10)),
  bankDetails: {
    bankName: profile.bankName,
    accountTitle: profile.ownerName,
    iban: profile.iban,
    stripeAccountId: `acct_test_${profile.ownerKey}`,
  },
}));

const tenantNames = [
  'Ayesha Noor',
  'Bilal Ahmed',
  'Zara Sheikh',
  'Usman Tariq',
  'Hina Fatima',
  'Danish Iqbal',
  'Maryam Khan',
  'Farhan Ali',
  'Nimra Saleem',
  'Saad Hassan',
  'Iqra Raza',
  'Hamza Javed',
  'Laiba Malik',
  'Omer Siddiqui',
  'Amna Qureshi',
  'Talha Nadeem',
  'Saba Yousaf',
  'Huzaifa Aslam',
  'Maira Shah',
  'Rehan Butt',
  'Faria Imran',
  'Waleed Akram',
  'Sana Jamil',
  'Ahad Mir',
  'Mahnoor Tariq',
  'Rayyan Khalid',
  'Areeba Iftikhar',
  'Haris Sheikh',
  'Kinza Noman',
  'Salman Farooq',
  'Rida Batool',
  'Sameer Abbas',
  'Emaan Saeed',
  'Adeel Mahmood',
  'Noor Ul Ain',
  'Daniyal Bashir',
  'Komal Shafiq',
  'Fahad Munir',
  'Tehreem Arif',
  'Hassan Ali',
  'Alina Waqar',
  'Zain Ul Abideen',
  'Anum Khalid',
  'Kashif Raza',
  'Mehak Irfan',
  'Taha Iqbal',
  'Bisma Hanif',
  'Moiz Ahmed',
  'Rabia Siddiqui',
  'Shahzaib Khan',
  'Fiza Asghar',
  'Arham Malik',
  'Dua Fatima',
  'Mohsin Rauf',
  'Alishba Noor',
  'Junaid Qureshi',
];

const occupations = ['student', 'student', 'student', 'jobHolder', 'selfEmployed'];

const tenants = cityProfiles.flatMap((profile, cityIndex) => {
  return Array.from({ length: 8 }, (_, index) => {
    const globalIndex = cityIndex * 8 + index;
    const name = tenantNames[globalIndex % tenantNames.length];
    return {
      key: `tenant_${pad2(globalIndex + 1)}`,
      name,
      email: `tenant.${slug(name)}.${pad2(globalIndex + 1)}@hostelx.test`,
      phone: `03${String(20 + cityIndex)}${String(10000000 + globalIndex).slice(1)}`,
      city: profile.city,
      occupation: occupations[(globalIndex + cityIndex) % occupations.length],
      joinedDate: formatDate(dateUtc(2025, (globalIndex % 12) + 1, 12)),
    };
  });
});

const hostelImages = [
  'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
  'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80',
];

function buildRoomConfigurations(basePrice, index) {
  return [
    { type: 'Single Room', count: 3 + (index % 3), price: basePrice + 5500 },
    { type: '2 Seater', count: 7 + (index % 4), price: basePrice },
    { type: '3 Seater', count: 6 + (index % 3), price: Math.max(9000, basePrice - 3000) },
    { type: '4 Seater', count: 4 + (index % 2), price: Math.max(8000, basePrice - 5500) },
  ];
}

function buildHostels() {
  const hostels = [];

  cityProfiles.forEach((profile, cityIndex) => {
    profile.names.forEach((name, index) => {
      const adjustedBase = profile.basePrice + index * 1800 - (index === 3 ? 2500 : 0);
      const price = index === 3 ? Math.min(14500, adjustedBase) : adjustedBase;
      const roomConfigurations = buildRoomConfigurations(price, cityIndex + index);
      const totalRooms = roomConfigurations.reduce((sum, item) => sum + item.count, 0);
      const facilities = [
        'WiFi',
        'Mess',
        'Security',
        'Laundry',
        'Generator',
        index % 2 === 0 ? 'AC' : 'Geyser',
        index % 3 === 0 ? 'CCTV' : 'Study Room',
        index === 2 ? 'Shuttle' : 'Parking',
      ];

      hostels.push({
        id: `seed_${slug(profile.city)}_${index + 1}_${slug(name)}`,
        ownerKey: profile.ownerKey,
        name,
        location: `${profile.areas[index]} near main campus road`,
        city: profile.city,
        lat: Number((profile.lat + index * 0.018 + cityIndex * 0.002).toFixed(6)),
        lng: Number((profile.lng + index * 0.014 - cityIndex * 0.002).toFixed(6)),
        price,
        rating: Number((4.2 + ((cityIndex + index) % 7) * 0.1).toFixed(1)),
        reviewsCount: 24 + cityIndex * 5 + index * 7,
        images: [
          hostelImages[(cityIndex + index) % hostelImages.length],
          hostelImages[(cityIndex + index + 3) % hostelImages.length],
          hostelImages[(cityIndex + index + 5) % hostelImages.length],
        ],
        facilities,
        type: index % 2 === 0 ? 'boys' : 'girls',
        availability: 'open',
        description:
          `${name} provides furnished rooms, verified management, daily mess, study-friendly spaces, backup power, and monitored entry for students and young professionals in ${profile.city}.`,
        approvalStatus: 'approved',
        isRecommended: index === 0 || index === 1,
        isMostPopular: index === 0 || index === 2,
        isRecentlyAdded: index === 2,
        isBudgetFriendly: index === 3,
        minContractMonths: index === 3 ? 3 : 6,
        securityDeposit: Math.round(price * 1.5),
        totalRooms,
        rentIncrementPercentage: 10,
        roomConfigurations,
        createdAt: dateUtc(2025, Math.max(1, cityIndex + 1), 4 + index).toISOString(),
      });
    });
  });

  ['Lahore', 'Islamabad', 'Karachi'].forEach((city, index) => {
    const profile = cityProfiles.find((item) => item.city === city);
    const price = profile.basePrice + 1200;
    const roomConfigurations = buildRoomConfigurations(price, index + 2);
    hostels.push({
      id: `seed_pending_${slug(city)}_${index + 1}`,
      ownerKey: profile.ownerKey,
      name: `${city} Campus Residence Pending`,
      location: `${profile.areas[0]} service lane`,
      city,
      lat: Number((profile.lat + 0.075).toFixed(6)),
      lng: Number((profile.lng - 0.055).toFixed(6)),
      price,
      rating: 0,
      reviewsCount: 0,
      images: [
        hostelImages[(index + 2) % hostelImages.length],
        hostelImages[(index + 4) % hostelImages.length],
      ],
      facilities: ['WiFi', 'Mess', 'Security', 'Laundry', 'CCTV'],
      type: index % 2 === 0 ? 'boys' : 'girls',
      availability: 'open',
      description:
        'Newly submitted listing awaiting admin verification, document review, and final approval before it appears for students.',
      approvalStatus: 'pending',
      isRecommended: false,
      isMostPopular: false,
      isRecentlyAdded: true,
      isBudgetFriendly: false,
      minContractMonths: 6,
      securityDeposit: Math.round(price * 1.5),
      totalRooms: roomConfigurations.reduce((sum, item) => sum + item.count, 0),
      rentIncrementPercentage: 10,
      roomConfigurations,
      createdAt: dateUtc(2026, 5, 28 + index).toISOString(),
    });
  });

  return hostels;
}

const hostelTemplates = buildHostels();
const approvedHostels = hostelTemplates.filter(
  (hostel) => hostel.approvalStatus === 'approved'
);

async function upsertAuthUser(person, role) {
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(person.email);
    await auth.updateUser(userRecord.uid, {
      displayName: person.name,
      password,
      disabled: false,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    userRecord = await auth.createUser({
      email: person.email,
      password,
      displayName: person.name,
      disabled: false,
    });
  }

  await db.collection('users').doc(userRecord.uid).set(
    {
      name: person.name,
      email: person.email,
      role,
      status: 'active',
      occupation: person.occupation || 'other',
      phone: person.phone,
      city: person.city,
      avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(person.name)}&background=random`,
      joinedDate: person.joinedDate || formatDate(dateUtc(2025, 5, 14)),
      bankDetails: person.bankDetails || null,
      seeded: true,
      seededAt,
    },
    { merge: true }
  );

  return userRecord.uid;
}

async function seedUsers() {
  const ownerIds = {};
  const tenantIds = {};

  const adminId = await upsertAuthUser(adminUser, 'admin');

  for (const owner of owners) {
    ownerIds[owner.key] = await upsertAuthUser(owner, 'owner');
  }

  for (const tenant of tenants) {
    tenantIds[tenant.key] = await upsertAuthUser(tenant, 'tenant');
  }

  return { adminId, ownerIds, tenantIds };
}

async function seedSettings() {
  await db.collection('app_settings').doc('platform').set(
    {
      commissionRate,
      allowNewListings: true,
      maintenanceMode: false,
      supportEmail: 'support@hostelx.test',
      demoMode: true,
      seeded: true,
      seededAt,
    },
    { merge: true }
  );
}

async function seedHostels(ownerIds) {
  const operations = hostelTemplates.map((hostel) => {
    const owner = owners.find((item) => item.key === hostel.ownerKey);
    return {
      ref: db.collection('hostels').doc(hostel.id),
      data: {
        name: hostel.name,
        location: hostel.location,
        city: hostel.city,
        lat: hostel.lat,
        lng: hostel.lng,
        price: hostel.price,
        rating: hostel.rating,
        reviewsCount: hostel.reviewsCount,
        images: hostel.images,
        facilities: hostel.facilities,
        type: hostel.type,
        availability: hostel.availability,
        description: hostel.description,
        ownerId: ownerIds[hostel.ownerKey],
        ownerName: owner.name,
        ownerPhone: owner.phone,
        ownerWhatsapp: owner.phone,
        approvalStatus: hostel.approvalStatus,
        isRecommended: hostel.isRecommended,
        isMostPopular: hostel.isMostPopular,
        isRecentlyAdded: hostel.isRecentlyAdded,
        isBudgetFriendly: hostel.isBudgetFriendly,
        minContractMonths: hostel.minContractMonths,
        securityDeposit: hostel.securityDeposit,
        totalRooms: hostel.totalRooms,
        rentIncrementPercentage: hostel.rentIncrementPercentage,
        roomConfigurations: hostel.roomConfigurations,
        documentUrls: {
          cnic: `https://example.com/demo-docs/${hostel.id}/owner-cnic.pdf`,
          property: `https://example.com/demo-docs/${hostel.id}/property-verification.pdf`,
        },
        createdAt: hostel.createdAt,
        updatedAt: seededAt,
        seeded: true,
        seededAt,
      },
    };
  });

  await commitInBatches(operations, 'hostels');
}

function pickUniqueBookingPair(seed, usedPairs) {
  for (let attempt = 0; attempt < tenants.length * approvedHostels.length; attempt += 1) {
    const tenant = tenants[(seed + attempt * 7) % tenants.length];
    const hostel = approvedHostels[(seed * 3 + attempt * 5) % approvedHostels.length];
    const key = `${tenant.key}_${hostel.id}`;
    if (!usedPairs.has(key)) {
      usedPairs.add(key);
      return { tenant, hostel };
    }
  }

  const tenant = tenants[seed % tenants.length];
  const hostel = approvedHostels[seed % approvedHostels.length];
  return { tenant, hostel };
}

function roomForBooking(hostel, seed) {
  const config = hostel.roomConfigurations[seed % hostel.roomConfigurations.length];
  const capacity = roomCapacity(config.type);
  const roomOffset = seed % Math.max(1, hostel.totalRooms);
  return {
    roomNumber: String(101 + roomOffset),
    roomType: config.type,
    bedNumber: capacity > 1 ? String((seed % capacity) + 1) : '',
    price: config.price + ((seed % 3) * 500),
  };
}

function addOwnerMonthTotal(ownerMonthTotals, ownerKey, year, month, amount, hostel, bookingId) {
  const key = `${ownerKey}_${monthKey(year, month)}`;
  const current = ownerMonthTotals.get(key) || {
    ownerKey,
    year,
    month,
    grossAmount: 0,
    hostelIds: new Set(),
    hostelNames: new Set(),
    bookingIds: [],
  };

  current.grossAmount += amount;
  current.hostelIds.add(hostel.id);
  current.hostelNames.add(hostel.name);
  current.bookingIds.push(bookingId);
  ownerMonthTotals.set(key, current);
}

function bookingMap({
  id,
  tenant,
  tenantId,
  hostel,
  ownerId,
  status,
  bookingDate,
  paymentDate,
  room,
  payoutId,
  longHistory,
}) {
  const isPaid = status === 'confirmed';
  const commission = isPaid ? Math.round(room.price * commissionRate) : 0;
  const ownerPayout = isPaid ? room.price - commission : 0;

  return {
    hostelId: hostel.id,
    hostelName: hostel.name,
    hostelImage: hostel.images[0],
    ownerId,
    studentId: tenantId,
    studentName: tenant.name,
    userId: tenantId,
    userName: tenant.name,
    userEmail: tenant.email,
    userPhone: tenant.phone,
    userOccupation: tenant.occupation,
    roomNumber: room.roomNumber,
    roomType: room.roomType,
    bedNumber: room.bedNumber,
    status,
    date: formatDate(bookingDate),
    price: room.price,
    amount: room.price,
    commission,
    ownerPayout,
    paymentDate: paymentDate ? timestamp(paymentDate) : null,
    paymentMethod: isPaid ? ['JazzCash', 'Easypaisa', 'Stripe Card'][id.length % 3] : '',
    payoutStatus: isPaid ? 'paid' : 'pending',
    payoutId: isPaid ? payoutId : null,
    refundNeeded: false,
    paymentHistory: isPaid ? buildPaymentHistory(bookingDate, longHistory) : [],
    createdAt: timestamp(bookingDate),
    updatedAt: timestamp(paymentDate || bookingDate),
    seeded: true,
    seededAt,
  };
}

async function seedBookingsAndPayouts(ownerIds, tenantIds) {
  const operations = [];
  const usedPairs = new Set();
  const ownerMonthTotals = new Map();
  const monthlyCounts2025 = [6, 7, 8, 8, 9, 9, 10, 10, 9, 11, 12, 10];
  const monthlyCounts2026 = [11, 12, 13, 12, 14, 9];
  let sequence = 0;

  function addConfirmedMonth(year, month, count) {
    for (let i = 0; i < count; i += 1) {
      const { tenant, hostel } = pickUniqueBookingPair(sequence + year + month + i, usedPairs);
      const ownerId = ownerIds[hostel.ownerKey];
      const tenantId = tenantIds[tenant.key];
      const day = year === 2026 && month === 6 ? 1 : 3 + ((i * 2 + month) % 22);
      const bookingDate = dateUtc(year, month, day);
      const paymentDate = dateUtc(year, month, day);
      const room = roomForBooking(hostel, sequence + i);
      const payoutId = `seed_payout_${hostel.ownerKey}_${monthKey(year, month)}`;
      const id = `seed_booking_${year}_${pad2(month)}_${pad2(i + 1)}`;
      const longHistory = year === 2025 && month >= 7 && i % 4 === 0;

      operations.push({
        ref: db.collection('bookings').doc(id),
        data: bookingMap({
          id,
          tenant,
          tenantId,
          hostel,
          ownerId,
          status: 'confirmed',
          bookingDate,
          paymentDate,
          room,
          payoutId,
          longHistory,
        }),
      });

      addOwnerMonthTotal(
        ownerMonthTotals,
        hostel.ownerKey,
        year,
        month,
        room.price,
        hostel,
        id
      );
      sequence += 1;
    }
  }

  monthlyCounts2025.forEach((count, index) => addConfirmedMonth(2025, index + 1, count));
  monthlyCounts2026.forEach((count, index) => addConfirmedMonth(2026, index + 1, count));

  const openRequestStatuses = [
    'pending',
    'payment_pending',
    'pending',
    'pending',
    'payment_pending',
    'pending',
    'pending',
  ];

  openRequestStatuses.forEach((status, index) => {
    const { tenant, hostel } = pickUniqueBookingPair(sequence + index * 11, usedPairs);
    const tenantId = tenantIds[tenant.key];
    const room = roomForBooking(hostel, sequence + index);
    const bookingDate = dateUtc(2026, 6, 1, 10 + index);
    const id = `seed_booking_open_request_${pad2(index + 1)}`;

    operations.push({
      ref: db.collection('bookings').doc(id),
      data: bookingMap({
        id,
        tenant,
        tenantId,
        hostel,
        ownerId: ownerIds[hostel.ownerKey],
        status,
        bookingDate,
        paymentDate: null,
        room,
        payoutId: null,
        longHistory: false,
      }),
    });
  });

  await commitInBatches(operations, 'bookings');
  await seedPayouts(ownerIds, ownerMonthTotals);
}

async function seedPayouts(ownerIds, ownerMonthTotals) {
  const operations = [];

  for (const total of ownerMonthTotals.values()) {
    const owner = owners.find((item) => item.key === total.ownerKey);
    const payoutDate =
      total.year === 2026 && total.month === 6
        ? dateUtc(2026, 6, 1, 16)
        : dateUtc(total.year, total.month, 27, 16);
    const commissionAmount = Math.round(total.grossAmount * commissionRate);
    const netAmount = total.grossAmount - commissionAmount;
    const id = `seed_payout_${total.ownerKey}_${monthKey(total.year, total.month)}`;

    operations.push({
      ref: db.collection('payouts').doc(id),
      data: {
        ownerId: ownerIds[total.ownerKey],
        ownerName: owner.name,
        hostelIds: Array.from(total.hostelIds),
        hostelNames: Array.from(total.hostelNames),
        grossAmount: total.grossAmount,
        commissionAmount,
        netAmount,
        status: 'paid',
        payoutStatus: 'paid',
        method: 'stripe',
        transferId: `tr_seed_${total.year}${pad2(total.month)}_${slug(owner.name)}`,
        date: formatDate(payoutDate),
        year: total.year,
        month: total.month,
        bookingIds: total.bookingIds,
        createdAt: timestamp(payoutDate),
        seeded: true,
        seededAt,
      },
    });
  }

  await commitInBatches(operations, 'payouts');
}

async function seedReviews(tenantIds) {
  const comments = [
    'Clean rooms, stable WiFi, and management responds quickly.',
    'The mess timing is reliable and the study space stays quiet at night.',
    'Security and laundry are well managed, especially during exam season.',
    'Good location for university transport and daily essentials.',
    'Rooms are exactly as listed and the rent policy is transparent.',
  ];
  const operations = [];

  approvedHostels.forEach((hostel, hostelIndex) => {
    for (let i = 0; i < 3; i += 1) {
      const tenant = tenants[(hostelIndex * 3 + i) % tenants.length];
      const date = dateUtc(2026, ((hostelIndex + i) % 5) + 1, 8 + i);
      operations.push({
        ref: db.collection('reviews').doc(`seed_review_${hostel.id}_${i + 1}`),
        data: {
          hostelId: hostel.id,
          userId: tenantIds[tenant.key],
          userName: tenant.name,
          rating: Math.min(5, hostel.rating + (i === 0 ? 0 : -0.1)),
          comment: comments[(hostelIndex + i) % comments.length],
          date: formatDate(date),
          ownerReply:
            i === 1
              ? 'Thank you for the feedback. We keep improving our services for students.'
              : null,
          createdAt: timestamp(date),
          seeded: true,
          seededAt,
        },
      });
    }
  });

  await commitInBatches(operations, 'reviews');
}

async function seedComplaints(ownerIds, tenantIds) {
  const complaintTemplates = [
    ['Maintenance request', 'Water pressure was low in the evening study hours.', 'Open'],
    ['Laundry delay', 'Laundry pickup was delayed by one day this week.', 'Under Review'],
    ['Noise complaint', 'Room corridor was noisy after 11 PM.', 'Resolved'],
    ['Mess quality feedback', 'Dinner quality needs improvement on weekends.', 'Open'],
    ['WiFi instability', 'Internet speed dropped during online classes.', 'Resolved'],
    ['Room cleaning schedule', 'Shared room cleaning was missed twice.', 'Under Review'],
    ['Security desk follow-up', 'Visitor entry register was not updated properly.', 'Open'],
    ['Generator issue', 'Backup power took longer than usual during outage.', 'Resolved'],
  ];
  const operations = complaintTemplates.map(([title, description, status], index) => {
    const tenant = tenants[index * 3];
    const hostel = approvedHostels[index * 2];
    const createdAt = dateUtc(2026, 5, 19 + index);

    return {
      ref: db.collection('complaints').doc(`seed_complaint_${pad2(index + 1)}`),
      data: {
        type: index % 2 === 0 ? 'Received' : 'Filed',
        title,
        description,
        byUserId: tenantIds[tenant.key],
        byUserName: tenant.name,
        againstId: hostel.id,
        againstName: hostel.name,
        ownerId: ownerIds[hostel.ownerKey],
        status,
        adminResponse:
          status === 'Resolved' ? 'Issue verified with owner and marked resolved.' : '',
        createdAt: timestamp(createdAt),
        updatedAt: timestamp(createdAt),
        seeded: true,
        seededAt,
      },
    };
  });

  await commitInBatches(operations, 'complaints');
}

async function seedFavorites(tenantIds) {
  const operations = tenants.slice(0, 21).map((tenant, index) => {
    const cityHostels = approvedHostels.filter((hostel) => hostel.city === tenant.city);
    const hostelIds = [
      cityHostels[index % cityHostels.length].id,
      cityHostels[(index + 1) % cityHostels.length].id,
      cityHostels[(index + 2) % cityHostels.length].id,
    ];

    return {
      ref: db.collection('favorites').doc(tenantIds[tenant.key]),
      data: {
        hostelIds,
        updatedAt: timestamp(dateUtc(2026, 5, 30)),
        seeded: true,
        seededAt,
      },
    };
  });

  await commitInBatches(operations, 'favorites');
}

function notificationDoc({ id, userId, title, body, type, daysAgo, isRead = false }) {
  const createdAt = new Date(demoToday.getTime() - daysAgo * 24 * 60 * 60 * 1000);
  return {
    ref: db.collection('notifications').doc(id),
    data: {
      userId,
      title,
      body,
      type,
      isRead,
      createdAt: timestamp(createdAt),
      createdAtIso: createdAt.toISOString(),
      seeded: true,
      seededAt,
    },
  };
}

async function seedNotifications(adminId, ownerIds, tenantIds) {
  const operations = [
    notificationDoc({
      id: 'seed_notification_admin_listing',
      userId: adminId,
      title: 'New hostel needs verification',
      body: '3 owner listings are waiting for document review and approval.',
      type: 'hostel',
      daysAgo: 1,
    }),
    notificationDoc({
      id: 'seed_notification_admin_payouts',
      userId: adminId,
      title: 'Monthly payout cycle completed',
      body: 'Owner payouts for May 2026 have been released successfully.',
      type: 'payout',
      daysAgo: 2,
      isRead: true,
    }),
    notificationDoc({
      id: 'seed_notification_admin_complaint',
      userId: adminId,
      title: 'Open complaint requires review',
      body: 'A tenant reported a maintenance issue at Scholars Boys Hostel.',
      type: 'complaint',
      daysAgo: 0,
    }),
  ];

  owners.slice(0, 7).forEach((owner, index) => {
    operations.push(
      notificationDoc({
        id: `seed_notification_owner_booking_${index + 1}`,
        userId: ownerIds[owner.key],
        title: 'New booking request',
        body: 'A student has requested a room and is waiting for approval.',
        type: 'booking',
        daysAgo: index % 3,
      }),
      notificationDoc({
        id: `seed_notification_owner_payout_${index + 1}`,
        userId: ownerIds[owner.key],
        title: 'Payout received',
        body: 'Your latest monthly payout has been released by admin.',
        type: 'payout',
        daysAgo: index + 1,
        isRead: index % 2 === 0,
      })
    );
  });

  tenants.slice(0, 10).forEach((tenant, index) => {
    operations.push(
      notificationDoc({
        id: `seed_notification_tenant_booking_${index + 1}`,
        userId: tenantIds[tenant.key],
        title: 'Booking confirmed',
        body: 'Your hostel booking and rent payment have been confirmed.',
        type: 'booking',
        daysAgo: index % 4,
      }),
      notificationDoc({
        id: `seed_notification_tenant_payment_${index + 1}`,
        userId: tenantIds[tenant.key],
        title: 'Payment receipt generated',
        body: 'Your monthly rent receipt is available in payment history.',
        type: 'payment',
        daysAgo: index + 2,
        isRead: index % 3 === 0,
      })
    );
  });

  await commitInBatches(operations, 'notifications');
}

async function main() {
  console.log('Seeding HostelX exhibition data...');
  console.log('This updates deterministic demo records and keeps existing live data intact.');

  const { adminId, ownerIds, tenantIds } = await seedUsers();
  await seedSettings();
  await seedHostels(ownerIds);
  await seedBookingsAndPayouts(ownerIds, tenantIds);
  await seedReviews(tenantIds);
  await seedComplaints(ownerIds, tenantIds);
  await seedFavorites(tenantIds);
  await seedNotifications(adminId, ownerIds, tenantIds);

  console.log('\nDone. Test login password for all seeded accounts:');
  console.log(password);
  console.log('\nAdmin account:');
  console.log(`- ${adminUser.email}`);
  console.log('\nOwner accounts:');
  owners.forEach((owner) => console.log(`- ${owner.email} (${owner.city})`));
  console.log('\nSample tenant accounts:');
  tenants.slice(0, 14).forEach((tenant) =>
    console.log(`- ${tenant.email} (${tenant.city})`)
  );
  console.log('\nSeed summary:');
  console.log(`- ${hostelTemplates.length} hostels across ${cityProfiles.length} cities`);
  console.log(`- ${tenants.length} tenant accounts`);
  console.log('- Monthly booking, payment, payout, complaint, review, favorite, and notification data added');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
