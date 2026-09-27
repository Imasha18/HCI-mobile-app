function getFirebaseConfig() {
  return { projectId: process.env.FIREBASE_PROJECT_ID || '' };
}

module.exports = { getFirebaseConfig };
