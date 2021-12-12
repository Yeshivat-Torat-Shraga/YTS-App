const fs = require('fs');
const os = require('os');
const path = require('path');
const admin = require('firebase-admin');
const spawn = require('child-process-promise');
const functions = require('firebase-functions');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');
const { Storage } = require('@google-cloud/storage');
const childProcessPromise = require('child-process-promise');


admin.initializeApp({
	projectId: "yeshivat-torat-shraga",
	// credential: admin.credential.cert(require('/Users/benjitusk/Downloads/yeshivat-torat-shraga-0f53fdbfdafa.json'))
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
	if (!docs || docs.length == 0) {
		return {
			lastLoadedDocumentID: lastDocumentFromQueryID,
			includesLastElement: (requestedCount > rebbeim.length),
			rebbeim: null
		};
	}
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
			console.log(url);
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
	if (callData.search)
		query = query.where(callData.search.field, "==", callData.search.value);
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
	let error_occured = false;

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
			let url = await getURLFor(data.source_path);
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
			error_occured = true;
			log(`There was an error resolving the promises getRabbiFor() and/or getURLFor(): ${promisepromiseResolutionError}`);

			// Keep this line in, need to be able to see if the final element was loaded
			content.push(null);
		}
	})).then(contentDataArray => {
		log("All promises resolved.");
		// Once all of the promises have resolved, return the data.
		// this data will be the resolved data from Promise.all(),
		// which, in turn, will be returned by the function.
		return {
			lastLoadedDocumentID: lastLoadedDocumentID,
			includesLastElement: (requestedCount > contentDataArray.length),
			content: contentDataArray,
			error_occured: error_occured
		};
	});
});


exports.generateHLSStream = functions.storage.bucket().object().onFinalize(async object => {
	const storage = new Storage();
	const bucket = storage.bucket(object.bucket);
	if (!object.name.includes('content')) {
		log(`Skipping ${object.name} because it is not a content file.`);
		return;
	}

	try {
		const filepath = object.name;
		const filename = path.basename(filepath);
		const tempFilePath = path.join(os.tmpdir(), filename);

		await bucket.file(filepath).download({
			destination: tempFilePath,
			validation: false
		});

		const foldername = `SSS${fileIDFromFilename(filename)}`;

		const inputPath = tempFilePath;
		const outputDir = path.join(os.tmpdir(), `HLSStreams`);
		log(`${process.cwd()}`);
		log(`Input path: ${inputPath}`);
		log(`Output path: ${outputDir}`);


		await childProcessPromise.spawn("mkdir", ["-p", outputDir]);

		try {
			await childProcessPromise.spawn(ffmpeg.path, [
				`-i`, `${inputPath}`,
				`-hls_list_size`, `0`,
				`-hls_time`, `10`,
				`-hls_segment_filename`, `${outputDir}/${filename}%03d.ts`,
				`${outputDir}/${filename}.m3u8`
			], { stdio: 'inherit' });
		} catch (error) {
			log(`Error: ${error}`);
			throw new Error("Error creating HLS stream.");
		}
		// } else {
		// 	return;
		// 	// throw new Error("This function only generates HLS streams for video and audio recordings");

		log(`Finished creating HLS stream, now uploading to bucket from ${outputDir}.`);

		const metadata = {
			// contentType: 'image/jpeg',
			// To enable Client-side caching you can set the Cache-Control headers here:
			'Cache-Control': 'public,max-age=3600'
		};

		const filenames = fs.readdirSync(outputDir);
		// fs.readdir(outputDir, async (error, filenames) => {
		log(filenames);
		await Promise.all(filenames.map((filename) => {
			const fp = path.join(outputDir, filename);
			log(`Uploading ${fp}...`);
			return bucket.upload(fp, {
				destination: `HLSStreams/${object.contentType.split("/")[0]}/${foldername}/${filename}`,
				metadata: metadata
			});
		}));
		console.log('Uploaded all files.');
		// filenames.forEach(async name => {
		// 	const fp = path.join(outputDir, name);
		// 	log(`Uploading file with path '${fp}'...`);
		// 	await bucket.upload(fp, {
		// 		destination: `HLSStreams/${object.contentType.split("/")[0]}/${foldername}/${filename}`,
		// 		metadata: metadata
		// 	});
		// 	// throw new error("Uploaded one file. Exiting immediately.");
		// });
		// });
	} catch (err) {
		log(`Failed: ${err} (B01F)`);
	}
});

/*
exports.createFirestoreEntry = functions.storage.object().onFinalize(async (object) => {
	/*
	AttributionID
	Author
	Date
	Description
	Duration
	Source Path
	Title
	Type
	*//*
const bucket = gcs.bucket(object.bucket);
const filePath = object.name;
const fileName = path.basename(filePath);
const fileID = fileIDFromFilename(fileName);
const fileType = object.contentType.split("/")[0];
const fileExtension = object.contentType.split("/")[1];
const fileSize = object.size;
const fileCreated = object.timeCreated;
const fileUpdated = object.updated;

const file = bucket.file(filePath);
const urlResult = await file.getSignedUrl({
action: 'read',
expires: '03-09-2491'
});

const url = new URL(urlResult[0]);
url.protocol = "file";

const db = admin.firestore();
const docRef = db.collection('files').doc(fileID);
const doc = await docRef.get();
if (doc.exists) {
log(`Document ${fileID} already exists.`);
return;
}

const newDoc = {
id: fileID,
type: fileType,
extension: fileExtension,
size: fileSize,
created: fileCreated,
updated: fileUpdated,
url: url.href
};

await docRef.set(newDoc);
});
*/


// === BEGIN THUMBNAIL FUNCTIONS ===
// const adminConfig = JSON.parse(process.env.FIREBASE_CONFIG);
exports.generateThumbnail = functions.storage.bucket().object().onFinalize(async object => {


	const THUMB_PREFIX = 'TTT';

	const SERVICE_ACCOUNT = 'yeshivat-torat-shraga-1358031cf751.json';
	const PROJECT_ID = "yeshivat-torat-shraga";

	const storage = new Storage({
		keyFilename: SERVICE_ACCOUNT,
		projectId: PROJECT_ID
	});

	// MIME type
	const contentType = object.contentType;

	const isVideo = contentType.startsWith('video/');

	// File path
	const filePathInBucket = object.name;

	if (!filePathInBucket.includes('content')) {
		// log("This function only generates thumbnails for files in the content folder.");
		return;
	}

	if (!isVideo) {
		log(`Can't create thumbnail for path '${filePathInBucket}' because it seems to not be a video. (A05)`);
		return Promise.reject();
	}

	// Storage bucket containing the file
	const fileBucket = object.bucket; // The Storage bucket that contains the file.

	const resourceState = object.resourceState; // The resourceState is 'exists' or 'not_exists' (for file/folder deletions).

	const metageneration = object.metageneration; // Number of times metadata has been generated. New objects have a value of 1.

	log(`Attempting to create thumbnail for file with path '${filePathInBucket}'...`);

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

	const fileName = path.basename(filePathInBucket);


	const thumbFileExt = 'jpg';

	const indexOfLastDot = fileName.lastIndexOf('.');
	const newFilename = `${fileName.substring(0, indexOfLastDot).replace('FFF', THUMB_PREFIX)}.${thumbFileExt}`;
	let thumbFilePath = path.normalize(`thumbnails/${newFilename}`);

	log(`New thumbnail file path: '${thumbFilePath}'`);
	const tempLocalThumbnailFilePath = path.join(os.tmpdir(), newFilename);

	const generateOperation = generateThumbnailFromVideo;

	const bucket = storage.bucket(fileBucket);
	const file = bucket.file(filePathInBucket);
	const metadata = {
		contentType: 'image/jpeg',
		// To enable Client-side caching you can set the Cache-Control headers here:
		'Cache-Control': 'public,max-age=3600'
	};

	return generateOperation(file, tempLocalThumbnailFilePath, fileName).then(async _ => {
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
		throw new functions.https.HttpsError(
			'error-generating',
			error);
	});
});

function generateThumbnailFromVideo(file, tempLocalThumbnailFilePath) {
	log(`Entered generateThumbnailFromVideo function.`);
	return file.getSignedUrl({
		action: 'read',
		expires: Date.now() + 1000 * 60 * 60,
	}).then(signedUrl => {
		const fileUrl = signedUrl[0];
		log(tempLocalThumbnailFilePath);
		const promise = spawn.spawn(ffmpeg.path, [
			'-ss', '0',
			'-i', fileUrl,
			'-f', 'image2',
			'-vframes', '1',
			'-vf',
			// `scale=512:-1`,
			`-update`, `1`,
			tempLocalThumbnailFilePath]);
		return promise;
	}).catch(error => {
		log(`Failed to generate thumbnail: ${error} (A08)`);
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

/*
async function getContentURLFor(filename) {
	return getURLFor(`content/${filename}`)
		.catch(_ => {
			return null;
		});
}
*/

async function getRabbiProfilePictureURLFor(filename) {
	return getURLFor(`profile-pictures/${filename}`)
		.catch(_ => {
			return null;
		});
}

async function getURLFor(path) {
	return new Promise(async (resolve, reject) => {
		// let db = admin.firestore();
		const bucket = admin.storage().bucket("yeshivat-torat-shraga.appspot.com");
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
				const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
				const filename = personData.profile_picture_filename;//appendToEndOfFilename(personData.profilepic, '_300x1000');
				// bucket.file(`profile-pictures/resized/${filename}`).getSignedUrl({
				bucket.file(`profile-pictures/${filename}`).getSignedUrl({
					action: "read",
					expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // One week
				}).then(url => {
					resolve({
						id: id,
						name: personData.name,
						profile_picture_filename: personData.profile_picture_filename,
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
					profile_picture_filename: personData.profile_picture_filename
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
	const fileparts = filename.split('/');
	if (fileparts.length == 1) return filename;
	const id = fileparts[fileparts.length - 1].substring(3).split('.');
	id.splice(-1);
	return id.join('.');
}

function log(data, structured = false) {
	functions.logger.info(data, {
		structuredData: structured
	});
}
