const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { token, title, body } = data;

  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'FCM token is required');
  }

  // Message payload
  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    // Additional options like data can be added here
    // data: {
    //   key1: "value1",
    //   key2: "value2",
    // },
  };

  try {
    // Send the message
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});
