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

  let includePictureURLs;
	if (callData.includePictureURLs == undefined) {
		includePictureURLs = true;
	} else {
		includePictureURLs = (callData.includePictureURLs == "true" || callData.includePictureURLs == true);
	}

	let rabbis = [];

	let db = admin.firestore();
	let query = db.collection('rabbis').orderBy('name', 'asc');

	if (typeof pastDocumentID == "string") {
		let snapshot = await db.collection("rabbis").doc(pastDocumentID).get()
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	let rabbisSnapshot = await query.limit(requestedCount).get();

  let lastLoadedDocumentID;
  let docs = rabbisSnapshot.docs;
  if (Array.isArray(docs) && docs.length > 0) {
    lastLoadedDocumentID = docs[docs.length - 1].id;
  }

	await Promise.all(rabbisSnapshot.docs.map(async doc => {
		const data = doc.data();
		const pfpFilename = data.profile_picture_filename;

    let url;
    if (includePictureURLs) {
      url = await getRabbiProfilePictureURLFor(pfpFilename);
    }

		const r = {
			id: doc.id,
			name: data.name,
      profile_picture_filename: pfpFilename,
			profile_picture_url: url
		};

    rabbis.push(r);
	}));

  return {
    requestData: {
      pastDocumentID: pastDocumentID,
      requestedCount: requestedCount
    },
    lastLoadedDocumentID: lastLoadedDocumentID,
    includesLastElement: (requestedCount > rabbis.length),
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

async function getThumbnailURLFor(filename) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		const id = fileIDFromFilename(filename);
		const bucket = admin.storage().bucket('kol-hatorah-kulah.appspot.com');
		await bucket.file(`thumbnails/TTT${id}.jpg`).getSignedUrl({
			action: "read",
			expires: Date.now() + 60 * 60 * 1000,
		}).then(url => {
			resolve(url[0])
		}).catch(reason => {
			reject(reason)
			log(`Rejecting getThumbnailURLFor(). Reason: ${reason}`);
		});
	});
}

async function getContentURLFor(filename) {
	return getURLFor(`content/${filename}`);
}

async function getRabbiProfilePictureURLFor(filename) {
	return getURLFor(`profile-pictures/${filename}`);
}

async function getURLFor(path) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
		await bucket.file(path).getSignedUrl({
			action: "read",
			expires: Date.now() + 60 * 60 * 1000,
		}).then(url => {
			resolve(url[0])
		}).catch(reason => {
			reject(reason)
			log(`Rejecting getURLFor(). Reason: ${reason}`);
		});
	});
}

async function getRabbiFor(id, includeProfilePictureURL) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		await db.collection("rabbis").doc(id).get().then(async personSnapshot => {
			const personData = personSnapshot.data();

			if (includeProfilePictureURL) {
				const bucket = admin.storage().bucket('kol-hatorah-kulah.appspot.com');
				const filename = appendToEndOfFilename(personData.profilepic, '_300x1000');
				await bucket.file(`profile-pictures/resized/${filename}`).getSignedUrl({
					action: "read",
					expires: Date.now() + 60 * 60 * 1000,
				}).then(url => {
					resolve({
						id: id,
						name: personData.name,
						profile_picture_filename: personData.profilepic,
						profile_picture_url: url[0]
					});
				}).catch(reason => {
					reject(reason);
					log(`Rejecting getRabbiFor(). Reason: ${reason}`);
				});
			} else {
				resolve({
					id: id,
					name: personData.name,
					profile_picture_filename: personData.profilepic
				});
			}
		});
	});
}

function appendToEndOfFilename(filename, text) {
	const components = filename.split('.');
	components[components.length - 2] = components[components.length - 2].concat(text);
	return components.join('.');
}

function fileIDFromFilename(filename) {
	const id = filename.substring(3).split('.');
	id.splice(-1);
	return id.join('.');
}

function log(data, structured = true) {
	functions.logger.info(data, {
		structuredData: structured
	});
}
