const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp({
	projectId: "yeshivat-torat-shraga"
});

exports.loadRabbis = functions.https.onCall(async (callData, context) => {
	// if (context.app == undefined) {
	// 	throw new functions.https.HttpsError(
	// 		'failed-precondition',
	// 		'The function must be called from an App Check verified app.')
	// }

	let pastDocumentID = callData.lastLoadedDocumentID;
	let requestedCount = callData.count || 10;

	let rabbis = [];

	let db = admin.firestore();
	let query = db.collection('rabbis').orderBy('name', 'asc');

	if (typeof pastDocumentID == "string") {
		let snapshot = await db.collection("rabbis").doc(pastDocumentID).get()
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	let rabbisSnapshot = await query.limit(requestedCount).get();

	await Promise.all(rabbisSnapshot.docs.map(async doc => {
		const data = doc.data();
		const pfpID = data.profile_picture_id;

		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
    log(JSON.stringify(bucket));
	  const url = await bucket.file('adavid_lp-2.jpg').getSignedUrl({
			action: "read",
			expires: "11-20-2021",
		});

		const r = {
			id: doc.id,
			name: data.name,
			profile_picture_url: url
		};

    rabbis.push(r);
	}));

  return {
    rabbis: rabbis
  };
});

exports.loadContent = functions.https.onCall(async (callData, context) => {
  // if (context.app == undefined) {
	// 	throw new functions.https.HttpsError(
	// 		'failed-precondition',
	// 		'The function must be called from an App Check verified app.')
	// }

	let pastDocumentID = callData.lastLoadedDocumentID;
	let requestedCount = callData.count || 10;

  let content = [];

	let db = admin.firestore();
	let query = db.collection('content').orderBy('date', 'asc');

	if (typeof pastDocumentID == "string") {
		let snapshot = await db.collection("content").doc(pastDocumentID).get()
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	let rabbisSnapshot = await query.limit(requestedCount).get();
});

function log(data, structured = true) {
	functions.logger.info(data, {
		structuredData: structured
	});
}
