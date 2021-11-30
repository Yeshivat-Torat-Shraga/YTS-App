const functions = require("firebase-functions");
const admin = require('firebase-admin');

admin.initializeApp({
	projectId: "yeshivat-torat-shraga",
	// credential: admin.credential.cert(require('/Users/benji/Downloads/yeshivat-torat-shraga-0f53fdbfdafa.json'))
});

exports.loadRebbeim = functions.https.onCall(async (callData, context) => {

	// === APP CHECK ===
	// if (context.app == undefined) {
	// 	throw new functions.https.HttpsError(
	// 		'failed-precondition',
	// 		'The function must be called from an App Check verified app.')
	// }

	// Get the last loaded document, if provided.
	// This is used for pagination.
	let documentOfLastPageID = callData.lastLoadedDocumentID;
	// Get the number of documents to load.
	// If not specified, load 10.
	let requestedCount = callData.count || 10;

	// Boolean value to indicate whether the function should
	// return the thumbnails associated with the documents.
	let includePictureURLs;
	if (callData.includePictureURLs == undefined) {
		// If not specified, default to true
		includePictureURLs = true;
	} else {
		// If specified, check if it is a Boolean true or a String "true".
		// If so, set includePictureURLs to true. Otherwise, set it to false.
		includePictureURLs = (callData.includePictureURLs == "true" || callData.includePictureURLs == true);
	}

	let rebbeim = [];

	// Create an object that represents the connection to the Firestore database.
	let db = admin.firestore();
	// Build a query to get the documents sorted by upload date.
	let query = db.collection('rebbeim').orderBy('name', 'asc');

	// If documentOfLastPageID is specified, check if it's a non empty String.
	if (typeof documentOfLastPageID == "string" && documentOfLastPageID != "") {
		// Fetch the document with the specified ID from Firestore.
		let snapshot = await db.collection("rebbeim").doc(documentOfLastPageID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query.
	let rebbeimSnapshot = await query.limit(requestedCount).get();
	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	let lastDocumentFromQueryID;
	// Get the documents returned from the query.
	let docs = rebbeimSnapshot.docs;

	// If docs is null, return.
	if (!docs)
		return {
			lastLoadedDocumentID: lastDocumentFromQueryID,
			includesLastElement: (requestedCount > rebbeim.length),
			rebbeim: null
		};

	// Assign the last document returned from the query to lastDocumentFromQueryID.
	lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	await Promise.all(docs.map(async (doc) => {
		// Get the document data.
		const data = doc.data();

		const pfpFilename = data.profile_picture_filename;

		let url;
		if (includePictureURLs) {
			url = await getRabbiProfilePictureURLFor(pfpFilename);
		}

		const documentData = {
			id: doc.id,
			name: data.name,
			profile_picture_filename: pfpFilename,
			profile_picture_url: url
		};

		rebbeim.push(documentData);
	}));

	// Once we are done looping through the documents, return the data.
	return {
		lastLoadedDocumentID: lastDocumentFromQueryID,
		includesLastElement: (requestedCount > rebbeim.length),
		rebbeim: rebbeim
	};
});

exports.loadContent = functions.https.onCall(async (callData, context) => {

	// === APP CHECK ===
	// if (context.app == undefined) {
	// 	throw new functions.https.HttpsError(
	// 		'failed-precondition',
	// 		'The function must be called from an App Check verified app.')
	// }

	// Get the last loaded document, if provided.
	// This is used for pagination.
	let documentOfLastPageID = callData.lastLoadedDocumentID;
	// Get the number of documents to load.
	// If not specified, load 10.
	let requestedCount = callData.count || 10;

	// Boolean value to indicate whether the function should
	// return the thumbnails associated with the documents.
	let includeThumbnailURLs;
	if (callData.includeThumbnailURLs == undefined) {
		// If not specified, default to true
		includeThumbnailURLs = false;
	} else {
		// If specified, check if it is a Boolean true or a String "true".
		// If so, set includeThumbnailURLs to true. Otherwise, set it to false.
		includeThumbnailURLs = (callData.includeThumbnailURLs == "true" || callData.includeThumbnailURLs == true);
	}

	// Boolean value to indicate whether the function should
	// return all data associated with the author.
	let includeAllAuthorData;
	if (callData.includeAllAuthorData == undefined) {
		// If not specified, default to true
		includeAllAuthorData = false;
	} else {
		// If specified, check if it is a Boolean true or a String "true".
		// If so, set includeAllAuthorData to true. Otherwise, set it to false.
		includeAllAuthorData = (callData.includeAllAuthorData == "true" || callData.includeAllAuthorData == true);
	}

	let content = [];

	// Create an object that represents the connection to the Firestore database.
	let db = admin.firestore();

	// If a rabbiAttributionID is specified, build a query to get
	// only the documents with the specified ID.
	let query = db.collection('content');
	if (callData.rabbiAttributionID)
		query = query.where("attributionID", "==", callData.rabbiAttributionID);
	// Sort the query by upload date.
	// query = query.orderBy('date', 'asc');


	// If documentOfLastPageID is specified, check if it's a non empty String.
	if (documentOfLastPageID) {
		// Fetch the document with the specified ID from Firestore.
		let snapshot = await db.collection("content").doc(documentOfLastPageID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query.
	let contentSnapshot = await query.limit(requestedCount).get();
	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	let lastLoadedDocumentID;
	// Get the documents returned from the query.
	let docs = contentSnapshot.docs;

	// If docs is null or empty, return.
	if (!docs || docs.length == 0)
		return {
			lastLoadedDocumentID: lastLoadedDocumentID,
			includesLastElement: (requestedCount > content.length),
			// If error, return null, else return an empty array.
			content: docs ? [] : null
		};

	// Assign the last document returned from the query to lastLoadedDocumentID.
	lastLoadedDocumentID = docs[docs.length - 1].id;

	// Keep track if an error occurred
	let errorOccurred = false;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the content array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()

	// Do we need await? We're not assigning the returned Promise to a variable,
	// so it seems inefficent to use await.

	return Promise.all(docs.map(async doc => {
		// Get the document data.
		const data = doc.data();

		try {
			let url = await getContentURLFor(data.filename);
			let author = await getRabbiFor(data.attributionID, includeAllAuthorData);

			const contentData = {
				id: doc.id,
				attributionID: data.attributionID,
				title: data.title,
				description: data.description,
				duration: data.duration,
				date: data.date,
				type: data.type,
				source_url: url,
				author: author
			};

			return contentData;
		} catch (promiseResolutionError) {
			errorOccurred = true;
			log("There was an error resolving the promises getRabbiFor() and getContentURLFor().");
			log(promiseResolutionError);
			content.push({
				error: promiseResolutionError
			});
		}
	}))
		.then((contentDataArray) => {
			log("All promises resolved.");
			// Once all of the promises have resolved, return the data.
			// this data will be the resolved data from Promise.all(),
			// which, in turn, will be returned by the function.
			return {
				lastLoadedDocumentID: lastLoadedDocumentID,
				includesLastElement: (requestedCount > contentDataArray.length),
				content: contentDataArray,
				errorOccurred,
				totalDocuments: contentDataArray.length
			};
		});
});

// === BEGIN THUMBNAIL FUNCTIONS ===

exports.generateHLSStream = functions.storage.bucket().object().onFinalize(async object => {
	const { Storage } = require('@google-cloud/storage');
	const storage = new Storage();
	const path = require('path');
	const contentType = object.contentType;
	const isVideo = contentType.startsWith('video/');
	const filename = path.basename(object.name);
	const bucket = storage.bucket(object.bucket);
	if (!isVideo) {
		log("Not creating a HLS stream for non video content at the moment.");
		return;
	}
	const hlsStreamCreator = require('hls-stream-creator');
	const settings = {
		renditions: [
			{
				resolution: {
					width: 1920,
					height: 1080,
				},
				bitrate: 8000,
				audioRate: 320,
			},
			{
				resolution: {
					width: 1280,
					height: 720,
				},
				bitrate: 4000,
				audioRate: 192,
			},
		],
		printLogs: true
	};

	try {
		// const os = require('os');
		// const tempLocalFilePath = path.join(os.tmpdir(), filename);
		// const newFilePath = path.normalize(`content/${filename}`);
		// const metadata = {
		// 	contentType: object.contentType,
		// };
		const file = bucket.file(object.name);

		const urlResult = await file.getSignedUrl({
		action: 'read',
		expires: Date.now() + 1000 * 60 * 60,
		});

		// const url = urlResult[0];

		const inputPath = new URL(urlResult[0]);
		const outputPath = `HLSStream/${filename}`;
		log(`${process.cwd()}`);
		log(`Input path: ${inputPath}`);
		log(`Output path: ${outputPath}`);
		await hlsStreamCreator(inputPath, `HLSStream/${filename}`, settings);
	} catch (err) {
		console.log(`Failed: ${err} (B01F)`);
	}
});

const adminConfig = JSON.parse(process.env.FIREBASE_CONFIG);
exports.generateThumbnail = functions.storage.bucket().object().onFinalize(async object => {
	// const mkdirp = require('mkdirp');
	const { Storage } = require('@google-cloud/storage');
	const path = require('path');
	const os = require('os');
	// const fs = require('fs');

	const THUMB_PREFIX = 'TTT';
	const THUMB_MAX_WIDTH = 512;

	// const SERVICE_ACCOUNT = '/Users/benji/Downloads/yeshivat-torat-shraga-0f53fdbfdafa.json';
	const PROJECT_ID = "yeshivat-torat-shraga";

	const storage = new Storage({
		// keyFilename: SERVICE_ACCOUNT,
		projectId: PROJECT_ID,
	});

	// MIME type
	const contentType = object.contentType;

	const isVideo = contentType.startsWith('video/');

	// File path
	const filePathInBucket = object.name;
	if (!isVideo) {
		log(`Can't create thumbnail for path '${filePathInBucket}' because it seems to not be a video. (A05)`);
		return Promise.reject();
	}

	// Storage bucket containing the file
	const fileBucket = object.bucket; // The Storage bucket that contains the file.

	const resourceState = object.resourceState; // The resourceState is 'exists' or 'not_exists' (for file/folder deletions).

	const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.

	log(`Attempting to create thumbnail for file with file path '${filePathInBucket}'...`);

	const isImage = contentType.startsWith('image/');
	// log(`Object: ${JSON.stringify(object)}`);
	log(`Creating thumbnail for file with path '${filePathInBucket}' in bucket '${fileBucket}'`);

	if (resourceState === 'not_exists') {
		log(`Error: Failed to create thumbnail for path '${filePathInBucket}'; resourceState=${resourceState}. (A01)`);
		return Promise.reject();
	} else if (resourceState === 'exists' && metageneration > 1) {
		log(`Error: Failed to create thumbnail for path '${filePathInBucket}'; metageneration=${metageneration}. (A02)`);
		return Promise.reject();
	} else if (filePathInBucket.indexOf('.thumbnail.') !== -1) {
		log(`Error: Failed to create thumbnail for path '${filePathInBucket}'. (A03)`);
		return Promise.reject();
	} else if (!(isImage || isVideo)) {
		log(`Error: Failed to create thumbnail for path '${filePathInBucket}'; contentType=${contentType}. (A04)`);
		return Promise.reject();
	}

	// Directory name
	const fileDir = path.dirname(filePathInBucket);
	// Filename
	const fileName = path.basename(filePathInBucket);

	// const fileInfo = parseName(fileName);

	const thumbFileExt = 'jpg';

	const indexOfLastDot = fileName.lastIndexOf('.');
	const newFilename = `${fileName.substring(0, indexOfLastDot).replace('FFF', THUMB_PREFIX)}.${thumbFileExt}`;
	let thumbFilePath = path.normalize(`thumbnails/${newFilename}`);

	log(`New thumbnail file path: '${thumbFilePath}'`);
	const tempLocalThumbFile = path.join(os.tmpdir(), newFilename);
	// log(`Temporary local thumbnail file: '${tempLocalThumbFile}'`);
	const tempLocalDir = fileDir;
	// log(`Temporary local directory: '${tempLocalDir}'`);

	const generateOperation = generateThumbnailFromVideo;

	const bucket = storage.bucket(fileBucket);
	// log(`Bucket: '${JSON.stringify(bucket)}'`);
	// const bucket = gcs({projectId: PROJECT_ID, keyFilename: SERVICE_ACCOUNT}).bucket(fileBucket);
	// const bucket = gcs({keyFilename: SERVICE_ACCOUNT}).bucket(fileBucket);
	// log(`Using bucket: '${JSON.stringify(bucket)}'`);
	const file = bucket.file(filePathInBucket);
	const metadata = {
		contentType: 'image/jpeg',
		// To enable Client-side caching you can set the Cache-Control headers here:
		'Cache-Control': 'public,max-age=3600'
	};

	return generateOperation(file, tempLocalThumbFile, fileName).then(async _ => {
		log(`Promise resolved, stored at: '${tempLocalThumbFile}'`);
		log(`Now uploading to bucket at: ${thumbFilePath}`);
		bucket.upload(tempLocalThumbFile, {
			destination: thumbFilePath,
			metadata: metadata
		}).then(_ => {
			return 'success';
		}).catch(error => {
			log(`Error: ${error} (A07)`);
			throw new functions.https.HttpsError(
				'error-uploading',
				error);
		});
	}).catch(error => {
		// log(`Error: ${error} (A06)`);
		return "The following error occured: \n" + error;
		throw new functions.https.HttpsError(
			'error-generating',
			error);
	});
});

function generateThumbnailFromVideo(file, tempLocalThumbnailFile) {
	log(`Entered generateThumbnailFromVideo function.`);
	const ffmpeg = require('@ffmpeg-installer/ffmpeg');
	return file.getSignedUrl({
		action: 'read',
		expires: Date.now() + 1000 * 60 * 60,
	}).then(signedUrl => {
		// log(`Signed URL: ${signedUrl}`);
		const fileUrl = signedUrl[0];
		// log(`File URL: ${fileUrl}`);
		const spawn = require('child-process-promise').spawn;
		const ffmpegPath = ffmpeg.path;
		const promise = spawn(ffmpegPath, ['-ss', '0', '-i', fileUrl, '-f', 'image2', '-vframes', '1', '-vf', /*`scale=512:-1`,*/ `-update`, `1`, tempLocalThumbnailFile]);
		return promise;
	}).catch(error => {
		log(`Failed to generate signed url (A08)`);
		return Promise.reject(error);
	});
}

// === END THUMBNAIL GENERATION ===

// async function getThumbnailURLFor(filename) {
// 	return new Promise(async (resolve, reject) => {
// 		let db = admin.firestore();
// 		const id = fileIDFromFilename(filename);
// 		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
// 		bucket.file(`thumbnails/TTT${id}.jpg`).getSignedUrl({
// 			action: "read",
// 			expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // One week
// 		}).then(url => {
// 			resolve(url[0]);
// 		}).catch(reason => {
// 			reject(reason);
// 			log(`Rejecting getThumbnailURLFor(). Reason: ${reason}`);
// 		});
// 	});
// }

async function getContentURLFor(filename) {
	return getURLFor(`content/${filename}`)
		.catch(_ => {
			return null;
		});
}

async function getRabbiProfilePictureURLFor(filename) {
	return getURLFor(`profile-pictures/${filename}`)
		.catch(_ => {
			return null;
		});
}

async function getURLFor(path) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
		bucket.file(path).getSignedUrl({
			action: "read",
			expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // One week
		}).then(url => {
			resolve(url[0]);
		}).catch(reason => {
			reject(reason);
			log(`Rejected getURLFor(). Reason: ${reason}`);
		});
	});
}

function getRabbiFor(id, includeProfilePictureURL) {
	return new Promise(async (resolve, reject) => {
		let db = admin.firestore();
		db.collection("rebbeim").doc(id).get().then(async personSnapshot => {
			const personData = personSnapshot.data();

			if (personData == undefined) {
				reject(`Rabbi doesn't exist`);
				return;
			}

			if (includeProfilePictureURL) {
				const bucket = admin.storage().bucket('kol-hatorah-kulah.appspot.com');
				const filename = appendToEndOfFilename(personData.profilepic, '_300x1000');
				bucket.file(`profile-pictures/resized/${filename}`).getSignedUrl({
					action: "read",
					expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // One week
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
