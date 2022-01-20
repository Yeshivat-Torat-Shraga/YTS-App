import admin from 'firebase-admin';
import functions from 'firebase-functions';
import {
	LoadData,
	NewsDocument,
	NewsFirebaseDocument,
	SlideshowImageDocument,
	SlideshowImageFirebaseDocument,
} from './types';
import { log, getURLFor } from './helpers';
const Storage = require('@google-cloud/storage').Storage;

admin.initializeApp({
	projectId: 'yeshivat-torat-shraga',
	// credential: admin.credential.cert(require('/Users/benjitusk/Downloads/yeshivat-torat-shraga-0f53fdbfdafa.json'))
});

exports.loadNews = functions.https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	// if (context.app == undefined) {
	//   throw new functions.https.HttpsError(
	//     'failed-precondition',
	//     'The function must be called from an App Check verified app.'
	//   )
	// }

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		includePictures: data.includePictures as Boolean,
		previousDocID: data.lastLoadedDocID as string | undefined,
	};

	let db = admin.firestore();
	const COLLECTION = 'news';

	let query = db.collection(COLLECTION).orderBy('date', 'desc');
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		let snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	let newsSnapshot = await query.limit(queryOptions.limit).get();

	// Get the documents returned from the query
	let docs = newsSnapshot.docs;
	// if null, return with an error
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: queryOptions.previousDocID ?? '',
				includesLastElement: false,
			},
			content: null,
		};
	}

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	let lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.
	let newsDocs = await Promise.all(
		docs.map(async (doc) => {
			// get the document data
			const data = doc.data() as NewsFirebaseDocument;
			let imageURLs: string[] = [];
			// load the images
			if (queryOptions.includePictures) {
				for (const path of data.imageURLs || []) {
					try {
						imageURLs.push(await getURLFor(`newsImages/${path}`));
					} catch (err) {
						log(`Error getting image for '${path}': ${err}`, true);
					}
				}
			}

			// return the document data
			const document: NewsDocument = {
				id: doc.id,
				title: data.title,
				author: data.author,
				body: data.body,
				uploaded: data.date,
				imageURLs: imageURLs,
			};
			return document;
		})
	);

	// Return the data
	const returnData: LoadData = {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			// This may not work, because the query may return
			// fewer documents than the limit if there are few documents left.
			includesLastElement: newsDocs.length == queryOptions.limit,
		},
		content: newsDocs,
	};

	return returnData;
});

exports.loadSlideshow = functions.https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	// if (context.app == undefined) {
	//   throw new functions.https.HttpsError(
	//     'failed-precondition',
	//     'The function must be called from an App Check verified app.'
	//   )
	// }

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		previousDocID: data.lastLoadedDocID as string | undefined,
	};

	let db = admin.firestore();
	const COLLECTION = 'slideshowImages';

	let query = db.collection(COLLECTION).orderBy('date', 'desc');
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		let snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	let imageSnapshot = await query.limit(queryOptions.limit).get();

	// Get the documents returned from the query
	let docs = imageSnapshot.docs;
	// if null, return with an error
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: queryOptions.previousDocID ?? '',
				includesLastElement: false,
			},
			content: null,
		};
	}

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	let lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.
	let imageDocs: (SlideshowImageDocument | null)[] = await Promise.all(
		docs.map(async (doc) => {
			// Get the document data
			const data = doc.data() as SlideshowImageFirebaseDocument;
			// Get the image path
			const path = data.image_name;
			// Get the image URL
			try {
				const url = await getURLFor(`slideshow/${path}`);
				// return the document data
				const document: SlideshowImageDocument = {
					title: data.title || null,
					id: doc.id,
					url: url,
					uploaded: data.uploaded,
				};
				return document;
			} catch (err) {
				log(`Error getting image for '${path}': ${err}`, true);
				return null;
			}
		})
	);
	const returnData: LoadData = {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			includesLastElement: false,
		},
		content: imageDocs.filter((doc) => doc != null),
	};
	return returnData;
});
