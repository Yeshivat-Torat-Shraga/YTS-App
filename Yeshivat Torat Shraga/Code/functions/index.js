const fs = require('fs');
const os = require('os');
const path = require('path');
const admin = require('firebase-admin');
const functions = require('firebase-functions');
const ffmpeg = require('@ffmpeg-installer/ffmpeg');
const Storage = require('@google-cloud/storage').Storage;
const childProcessPromise = require('child-process-promise');


admin.initializeApp({
	projectId: "yeshivat-torat-shraga",
	// credential: admin.credential.cert(require('/Users/benjitusk/Downloads/yeshivat-torat-shraga-0f53fdbfdafa.json'))
});

exports.loadSlideshow = functions.https.onCall(async (callData, context) => {

	// === APP CHECK ===
	// if (context.app == undefined) {
	// 	throw new functions.https.HttpsError(
	// 		'failed-precondition',
	// 		'The function must be called from an App Check verified app.')
	// }

	// Get the last loaded document, if provided.
	// This is used for pagination.
	let documentIdOfLastPage = callData.lastLoadedDocumentID;
	// Get the number of documents to load.
	// If not specified, load 10.
	let requestedCount = callData.count || 10;


	let imageURLs = [];

	// Create an object that represents the connection to the Firestore database.
	let db = admin.firestore();
	// Build a query to get the documents sorted by upload date.
	let query = db.collection('slideshowImages').orderBy('uploaded', 'desc');

	// If documentOfLastPageID is specified, check if it's a non empty String.
	if (typeof documentIdOfLastPage == "string" && documentIdOfLastPage != "") {
		// Fetch the document with the specified ID from Firestore.
		let snapshot = await db.collection("slideshowImages").doc(documentIdOfLastPage).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query.
	let imagesSnapshot = await query.limit(requestedCount).get();
	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	let lastDocumentFromQueryID;
	// Get the documents returned from the query.
	let docs = imagesSnapshot.docs;

	// If docs is null, return.
	if (!docs || docs.length == 0) {
		return {
			lastLoadedDocumentID: lastDocumentFromQueryID,
			includesLastElement: (requestedCount > imageURLs.length),
			imageURLs: null
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

		const imagePath = data.image_name;

		let url;
		try {
			url = await getURLFor(`slideshow/${imagePath}`);
			console.log(url);
		} catch (error) {
			console.error(error);
		}

		const documentData = {
			id: doc.id,
			name: data.image_name,
			url: url
		};

		imageURLs.push(documentData);
	}));

	// Once we are done looping through the documents, return the data.
	return {
		lastLoadedDocumentID: lastDocumentFromQueryID,
		includesLastElement: (requestedCount > imageURLs.length),
		imageURLs: imageURLs
	};
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
	if (callData.search) {
		if (callData.search.field == "tag") {
			query = query.where("tags", "array-contains", callData.search.value);
			log(`Only getting content where [tags] contains ${callData.search.value}`);
		} else {
			query = query.where(callData.search.field, "==", callData.search.value);
			log(`Only getting content where ${callData.search.field} == ${callData.search.value}`);
		}
	} else {
		log(`Not filtering by search. callData.search: ${callData.search}`);
	}
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
	if (!object.name.includes('content'))
		return log(`Skipping ${object.name} because it is not a content file.`);
	const storage = new Storage();
	const bucket = storage.bucket(object.bucket);

	try {
		const filepath = object.name;
		const filename = strippedFilename(filepath);
		const tempFilePath = path.join(os.tmpdir(), filename);

		await bucket.file(filepath).download({
			destination: tempFilePath,
			validation: false
		});

		const foldername = `${filename}`;

		const inputPath = tempFilePath;
		const outputDir = path.join(os.tmpdir(), `HLSStreams`);
		log(`${process.cwd()}`);
		log(`Input path: ${inputPath}`);
		log(`Output path: ${outputDir}`);

		// Create the output directory if it doesn't exist
		await childProcessPromise.spawn("mkdir", ["-p", outputDir]);

		// delete everything in the output directory
		await childProcessPromise.spawn("rm", ["-rf", `${outputDir}/*`]);

		try {
			await childProcessPromise.spawn(ffmpeg.path, [
				`-y`,
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

		bucket.file(filepath).delete();

	} catch (err) {
		log(`Failed: ${err} (B01F)`);
	}
});

// === BEGIN THUMBNAIL FUNCTIONS ===
// const adminConfig = JSON.parse(process.env.FIREBASE_CONFIG);
exports.generateThumbnail = functions.storage.bucket().object().onFinalize(async object => {
	// Step 1: Preliminary filetype
	if (!object.contentType.startsWith('video/'))
		return log(`Skipping ${object.name} because it is not in the video folder.`);
	// Step 2: Download the file from the bucket to a temporary folder
	const filepath = object.name;
	const filename = strippedFilename(filepath);
	const storage = new Storage();
	const bucket = storage.bucket(object.bucket);
	const tempFilePath = path.join(os.tmpdir(), filename);
	await bucket.file(filepath).download({
		destination: tempFilePath,
		validation: false
	});
	const inputPath = tempFilePath;
	const outputDir = path.join(os.tmpdir(), `thumbnails`);
	// Step 3: Create the output folder
	await childProcessPromise.spawn("mkdir", ["-p", outputDir]);
	// delete everything in the output directory
	await childProcessPromise.spawn("rm", ["-rf", `${outputDir}/*`]);

	// Step 4: Generate the thumbnail using ffmpeg
	try {
		await childProcessPromise.spawn(ffmpeg.path, [
			'-ss', '0',
			'-i', inputPath,
			'-y',
			'-vframes', '1',
			'-vf', `scale=512:-1`,
			`-update`, `1`,
			`${outputDir}/${filename}.jpg`
		], { stdio: 'inherit' });
	} catch (error) {
		functions.logger.error(`Error: ${error}`);
	}
	// Step 5: Upload the thumbnail to the bucket
	const metadata = {
		contentType: 'image/jpeg',
		// To enable Client-side caching you can set the Cache-Control headers here:
		'Cache-Control': 'public,max-age=3600'
	};
	await bucket.upload(`${outputDir}/${filename}.jpg`, {
		destination: `thumbnails/${filename}.jpg`,
		metadata: metadata
	});
	// Step 6: Delete the temporary file
	fs.unlinkSync(tempFilePath);

});

/** === SEARCH FUNCTIONS ===
 *
 * This function is triggered via HTTP.
 * It looks through the specified collection
 * and returns all documents that have any word
 * in the query string saved in the search_index
 * field belonging to every document.
 *
 * The collections we are searching are currently:
 * ["content", "rebbeim"]
 */
exports.searchFirestore = functions.https.onCall(async (callData, context) => {
	const db = admin.firestore();
	const searchQuery = callData.searchQuery.toLowerCase();
	let errors = [];
	if (!searchQuery) return {
		error: "No search query provided."
	};
	const searchArray = searchQuery.split(" ");
	let documentsThatMeetSearchCriteria = [];
	const defaultSearchOptions = {
		content: {
			limit: 5,
			includeThumbnailURLs: false,
			includeDetailedAuthorInfo: false,
			startFromDocumentID: null
		},
		rebbeim: {
			limit: 10,
			includePictureURLs: false,
			startFromDocumentID: null
		}
	};

	// Ensure that all options are set
	let searchOptions = supplyDefaultParameters(defaultSearchOptions, callData.searchOptions);


	// For each collection, run the following async function:
	return Promise.all(["content", "rebbeim"].map(async (collectionName) => {
		if (!Number.isInteger(searchOptions[collectionName].limit)) {
			errors.push(`Limit for ${collectionName} is not an integer.`);
			return [];
		}
		if (searchOptions[collectionName].limit == 0) return [];
		if (searchOptions[collectionName].limit < 0) {
			errors.push(`Limit for ${collectionName} is less than 0.`);
			return [];
		}
		if (searchOptions[collectionName].limit > 30) {
			searchOptions[collectionName].limit = 30;
			errors.push(`Limit for ${collectionName} is greater than 30. Setting limit to 30.`);
		}
		// Get the collection
		query = db.collection(collectionName);
		query = query.where("search_index", "array-contains-any", searchArray);
		switch (collectionName) {
			case "content":
				query = query.orderBy("date", "desc");
				break;
			case "rebbeim":
				query = query.orderBy("name", "asc");
				break;
		}

		// query = query.orderBy(searchOptions.orderBy[collectionName].field, searchOptions.orderBy[collectionName].order);
		if (searchOptions[collectionName].startFromDocumentID)
			query = query.startAt(searchOptions[collectionName].startFromDocumentID);

		query = query.limit(searchOptions[collectionName].limit);
		if (searchOptions[collectionName].includeThumbnailURLs);
		if (searchOptions[collectionName].includeDetailedAuthorInfo);

		let contentSnapshot = await query.get();
		let docs = contentSnapshot.docs;
		for (const doc of docs) documentsThatMeetSearchCriteria.push(doc);
		return docs;
	}))
		.then(async docs => {
			let rawContent = docs[0];
			let rawRebbeim = docs[1];
			let content = [];
			let rebbeim = [];

			await Promise.all(rawContent.map(async (doc) => {
				const data = doc.data();
				let url, author;
				try {
					url = await getURLFor(data.source_path);
					author = await getRabbiFor(data.attributionID, searchOptions.content.includeDetailedAuthorInfo);
					const documentData = {
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

					content.push(documentData);
				} catch (err) {
					content.push(null);
					errors.push(err);
				}
			}));

			await Promise.all(rawRebbeim.map(async (doc) => {
				// Get the document data.
				const data = doc.data();

				const pfpFilename = data.profile_picture_filename;

				try {
					let url;
					if (searchOptions.rebbeim.includePictureURLs)
						url = await getRabbiProfilePictureURLFor(pfpFilename);

					const documentData = {
						id: doc.id,
						name: data.name,
						// profile_picture_filename: pfpFilename,
						profile_picture_url: url
					};

					rebbeim.push(documentData);
				} catch (err) {
					rebbeim.push(null);
					errors.push(err);
				}
			}));
			// rebbeim.push(await getRabbiDataFromDoc(doc, searchOptions.rebbeim.includePictureURLs));
			return {
				content,
				rebbeim,
				searchOptions,
				errors
			};
		});
});





async function getRabbiProfilePictureURLFor(filename) {
	return getURLFor(`profile-pictures/${filename}`)
		.catch(_ => {
			return null;
		});
}

function getURLFor(path) {
	return new Promise((resolve, reject) => {
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


function strippedFilename(filename) {
	// Remove directory path
	const components = filename.split('/');
	// Remove file extension
	return components[components.length - 1].split('.')[0];
}


function log(data, structured = false) {
	functions.logger.info(data, {
		structuredData: structured
	});
}



/**
 * Merge two objects together, supplying default values for any missing keys.
 * @param {Object} def 
 * @param {Object} prov 
 * @returns {Object} copy of def with prov's properties overriding def's
 */
function supplyDefaultParameters(def, prov) {
	// def = default parameters
	// prov = provided parameters
	if (!prov) return def;
	for (const key in def) {
		if (!Object.prototype.hasOwnProperty.call(prov, key) || prov[key] === undefined) {
			prov[key] = def[key];
		} else if (prov[key] === Object(prov[key])) {
			prov[key] = supplyDefaultParameters(def[key], prov[key]);
		}
	}
	return prov;
}
