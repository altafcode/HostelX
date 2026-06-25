const admin = require("firebase-admin");

function initializeFirebase() {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error("Missing Firebase service account environment variables.");
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });
}

function setCors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

module.exports = async function handler(req, res) {
  setCors(res);

  if (req.method === "OPTIONS") {
    return res.status(204).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    initializeFirebase();

    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length)
      : null;

    if (!idToken) {
      return res.status(401).json({ error: "Missing Firebase auth token" });
    }

    await admin.auth().verifyIdToken(idToken);

    const { userId, role, title, body, type, notificationId } = req.body || {};
    if ((!userId && !role) || !title) {
      return res.status(400).json({ error: "Missing recipient (userId or role) or title" });
    }

    const db = admin.firestore();
    let tokens = [];
    let recipients = [];

    if (userId) {
      // Send to specific user
      recipients.push(userId);
      const userSnapshot = await db.collection("users").doc(userId).get();
      const user = userSnapshot.data() || {};
      tokens = Array.from(
        new Set([...(user.fcmTokens || []), user.fcmToken].filter(Boolean)),
      );
    } else if (role === "all") {
      // Broadcast to everyone
      const usersSnapshot = await db.collection("users").get();
      usersSnapshot.docs.forEach(doc => {
        recipients.push(doc.id);
        const user = doc.data();
        if (user.fcmToken) tokens.push(user.fcmToken);
        if (user.fcmTokens) tokens.push(...user.fcmTokens);
      });
    } else if (role) {
      // Send to specific role (robust case check)
      const roleLower = role.toLowerCase();
      const roleTitle = roleLower[0].toUpperCase() + roleLower.substring(1);

      const usersSnapshot = await db.collection("users")
        .where("role", "in", [roleLower, roleTitle])
        .get();

      usersSnapshot.docs.forEach(doc => {
        recipients.push(doc.id);
        const user = doc.data();
        if (user.fcmToken) tokens.push(user.fcmToken);
        if (user.fcmTokens) tokens.push(...user.fcmTokens);
      });
    }

    // Persist notification in Firestore for every recipient
    // This allows the "Notifications" screen to show them later.
    // We only do this if notificationId is 'new' or starts with 'role_' or 'broadcast_'
    // to avoid double entry if the client somehow still tries to write.
    const batch = db.batch();
    recipients.forEach(rid => {
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        userId: rid,
        title,
        body: body || "",
        type: type || "system",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAtIso: new Date().toISOString(),
      });
    });
    await batch.commit();

    tokens = Array.from(new Set(tokens.filter(Boolean)));

    if (tokens.length === 0) {
      return res.status(200).json({ sent: 0, message: "No FCM tokens found" });
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body: body || "",
      },
      data: {
        notificationId: notificationId || "",
        type: type || "system",
        route: "/notifications",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "hostelx_high_importance",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    const invalidTokens = [];
    response.responses.forEach((item, index) => {
      const code = item.error && item.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(tokens[index]);
      }
    });

    if (invalidTokens.length > 0) {
      await userSnapshot.ref.set(
        {
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        },
        { merge: true },
      );
    }

    return res.status(200).json({
      sent: response.successCount,
      failed: response.failureCount,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Unable to send notification" });
  }
};
