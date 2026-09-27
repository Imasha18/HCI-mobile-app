async function sendNotification(userId, title, body) {
  return { userId, title, body, sent: false };
}

module.exports = sendNotification;
