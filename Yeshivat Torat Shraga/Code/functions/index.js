const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp({
	projectId: "yeshivat-torat-shraga"
});

exports.loadRebbeim = functions.https.onCall(async (callData, context) => {
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

	let rebbeim = [];

	let db = admin.firestore();
	let query = db.collection('rebbeim').orderBy('name', 'asc');

	if (typeof pastDocumentID == "string") {
		let snapshot = await db.collection("rebbeim").doc(pastDocumentID).get()
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	let rebbeimSnapshot = await query.limit(requestedCount).get();

  let lastLoadedDocumentID;
  let docs = rebbeimSnapshot.docs;
  if (Array.isArray(docs) && docs.length > 0) {
    lastLoadedDocumentID = docs[docs.length - 1].id;

		await Promise.all(rebbeimSnapshot.docs.map(async doc => {
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

	    rebbeim.push(r);
		}));

		return {
	    requestData: {
	      pastDocumentID: pastDocumentID,
	      requestedCount: requestedCount
	    },
	    lastLoadedDocumentID: lastLoadedDocumentID,
	    includesLastElement: (requestedCount > rebbeim.length),
	    rebbeim: rebbeim
	  };
  } else {
		return {
	    requestData: {
	      pastDocumentID: pastDocumentID,
	      requestedCount: requestedCount
	    },
	    lastLoadedDocumentID: lastLoadedDocumentID,
	    includesLastElement: (requestedCount > rebbeim.length),
	    rebbeim: []
	  };
	}
});

exports.loadContent = functions.https.onCall(async (callData, context) => {
  // if (context.app == undefined) {
  // 	throw new functions.https.HttpsError(
  // 		'failed-precondition',
  // 		'The function must be called from an App Check verified app.')
  // }

  let pastDocumentID = callData.lastLoadedDocumentID;
  let requestedCount = callData.count || 10;

  let includeThumbnailURLs;
  if (callData.includeThumbnailURLs == undefined) {
    includeThumbnailURLs = false;
  } else {
    includeThumbnailURLs = (callData.includeThumbnailURLs == "true" || callData.includeThumbnailURLs == true);
  }

  let includeAllAuthorData;
  if (callData.includeAllAuthorData == undefined) {
    includeAllAuthorData = false;
  } else {
    includeAllAuthorData = (callData.includeAllAuthorData == "true" || callData.includeAllAuthorData == true);
  }

  let content = [];

  let db = admin.firestore();
	let query = db.collection('content').orderBy('date', 'asc');

  if (typeof pastDocumentID == "string") {
    let snapshot = await db.collection("content").doc(pastDocumentID).get()
    query = query.startAfter(snapshot);
    log(`Starting after document '${snapshot}'`);
  }

  let contentSnapshot = await query.limit(requestedCount).get();

  let lastLoadedDocumentID;
  let docs = contentSnapshot.docs;
  if (Array.isArray(docs) && docs.length > 0) {
    lastLoadedDocumentID = docs[docs.length - 1].id;

		await Promise.all(docs.map(async doc => {
			const data = doc.data();
			let promises = [];

			promises.push(getContentURLFor(data.filename).catch(reason => { return null }));

			promises.push(getRabbiFor(data.attributionID, includeAllAuthorData).catch(reason => { return null }));

			return await Promise.all(promises).then(results => {
				const url = results[0];
				const author = results[1];

				const c = {
					id: doc.id,
					attributionID: data.attributionID,
					title: data.title,
					description: data.description,
					duration: data.duration,
					date: data.date,
					type: data.type,
					source_url: url,
					author: author,
                    date: data.date,
                    duration: data.duration
				};

				content.push(c);
			});
	  }));

	  return {
	    requestData: {
	      pastDocumentID: pastDocumentID,
	      requestedCount: requestedCount,
				includeAllAuthorData: includeAllAuthorData,
				includeThumbnailURLs: includeThumbnailURLs
	    },
	    lastLoadedDocumentID: lastLoadedDocumentID,
	    includesLastElement: (requestedCount > content.length),
	    content: content
	  };
  } else {
		return {
			requestData: {
				pastDocumentID: pastDocumentID,
				requestedCount: requestedCount,
				includeAllAuthorData: includeAllAuthorData,
				includeThumbnailURLs: includeThumbnailURLs
			},
			lastLoadedDocumentID: lastLoadedDocumentID,
			includesLastElement: (requestedCount > content.length),
			content: []
		};
	}


});

exports.reloadSearchIndices = functions.https.onCall((data, context) => {
	let collectionName = data.collectionName;
	var db = admin.firestore();
	db.collection(collectionName).get().then(async (snapshot) => {
		snapshot.forEach(async s => {
			var doc = db.collection(collectionName).doc(s.id);
			await doc.set({
				temp: `temp`
			}, {
				merge: true
			}).then(() => {
				setTimeout(function() {
					doc.set({
						temp: FieldValue.delete()
					}, {
						merge: true
					});
				}, 10000);
			});
		});
	});
});

exports.updatePeopleData = functions.firestore.document(`rebbeim/{rabbiID}`).onWrite(async ev => {
	if (ev.after.data != undefined) {
		let data = ev.after.data();
		let components = [];
		let nameComponents = data.name.replace(/[^a-z\d\s]+/gi, "").toLowerCase().split(' ');

		components = components.concat(nameComponents);

		const db = admin.firestore();
		let doc = db.collection('rebbeim').doc(ev.after.id);
		doc.set({
			search_index: components
		}, {
			merge: true
		});
	}
});

async function getThumbnailURLFor(filename) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		const id = fileIDFromFilename(filename);
		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
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
			log(`Rejected getURLFor(). Reason: ${reason}`);
		});
	});
}

async function getRabbiFor(id, includeProfilePictureURL) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		await db.collection("rebbeim").doc(id).get().then(async personSnapshot => {
			const personData = personSnapshot.data();

			if (personData == undefined) {
				reject(`Rabbi doesn't exist`);
				return
			}

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
					log(`Rejected getRabbiFor(). Reason: ${reason}`);
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
