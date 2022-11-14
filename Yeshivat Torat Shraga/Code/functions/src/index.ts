import admin from 'firebase-admin';
import { https, storage, logger } from 'firebase-functions';
import ffmpeg from '@ffmpeg-installer/ffmpeg';
import childProcessPromise from 'child-process-promise';
// import * as functions from 'firebase-functions';

import os from 'os';
import {
	AlertDocument,
	AlertFirebaseDocument,
	Author,
	ContentDocument,
	ContentFirebaseDocument,
	LoadData,
	NewsDocument,
	NewsFirebaseDocument,
	ProspectiveContentDocument,
	RebbeimDocument,
	RebbeimFirebaseDocument,
	SlideshowImageDocument,
	SlideshowImageFirebaseDocument,
	SubmittedContentDocument,
	TagDocument,
	TagFirebaseDocument,
} from './types';
import {
	log,
	getURLFor,
	getRabbiFor,
	strippedFilename,
	supplyDefaultParameters,
	verifyAppCheck,
	getTagFor,
	// ENABLEAPPCHECK,
} from './helpers';
import path from 'path';
import { readdirSync, unlinkSync } from 'fs';
import { QueryDocumentSnapshot } from 'firebase-functions/v1/firestore';
// import { bucket } from 'firebase-functions/v1/storage';
const Storage = require('@google-cloud/storage').Storage;
const functions = require('firebase-functions');
const FieldValue = admin.firestore.FieldValue;

const crypto = require('crypto');
const fs = require('fs');

admin.initializeApp({
	projectId: 'yeshivat-torat-shraga',
	// credential: admin.credential.cert(
	// 	require('/Users/benjitusk/Downloads/yeshivat-torat-shraga-bed10d9b83ed.json')
	// ),
});

exports.createAlert = https.onCall(async (data, context) => {
	// === APP CHECK ===
	verifyAppCheck(context);

	if (!data.title || typeof data.title !== 'string') return 'Title is required';
	if (!data.body || typeof data.body !== 'string') return 'Body is required';
	if (!data.dateIssued || typeof data.dateIssued !== 'string') return 'Invalid dateIssued';
	if (!data.dateExpired || typeof data.dateExpired !== 'string') return 'Invalid dateExpired';

	const db = admin.firestore();
	const COLLECTION = 'alerts';

	const doc = await db.collection(COLLECTION).add({
		title: data.title,
		body: data.body,
		dateIssued: new Date(data.dateIssued),
		dateExpired: new Date(data.dateExpired),
	});

	return 'Created an alert with ID: ' + doc.id;
});

exports.createNotification = https.onCall(async (data, context): Promise<string> => {
	// App check is not needed, as this function requires authentication.

	const payload = {
		title: data.title,
		body: data.body,
	};

	// Make sure title and body are non-empty strings
	if (
		typeof payload.title !== 'string' ||
		payload.title.length === 0 ||
		typeof payload.body !== 'string' ||
		payload.body.length === 0
	) {
		logger.error('Invalid notification payload');
		return 'Invalid notification payload';
	}

	try {
		let res = await admin.messaging().send({
			notification: payload,
			topic: 'all',
		});

		log('Successfully sent notification: ' + JSON.stringify(res));
		return `Successfully sent message: ${res}`;
	} catch (err) {
		log('Error sending notification: ' + err);
		return 'Error sending notification: ' + err;
	}
});

exports.loadNews = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		includePictures: data.includePictures as Boolean,
		previousDocID: data.lastLoadedDocID as string | undefined,
	};

	const db = admin.firestore();
	const COLLECTION = 'news';

	let query = db.collection(COLLECTION).orderBy('date', 'desc');
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		const snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot.id}'`);
	}

	// Execute the query
	const newsSnapshot = await query.get();
	const totalDocs = newsSnapshot.size;
	// apply the limit
	const docs = newsSnapshot.docs.slice(0, queryOptions.limit);
	// Get the documents returned from the query
	// const docs = newsSnapshot.docs;
	// if null, return with an error
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: queryOptions.previousDocID || null,
				finalCall: docs ? true : false,
			},
			results: docs ? [] : null,
		};
	}

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	const lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.
	const newsDocs = await Promise.all(
		docs.map(async (doc) => {
			// get the document data
			try {
				var data = new NewsFirebaseDocument(doc.data());
			} catch {
				return null;
			}

			const imageURLs: string[] = [];
			/*
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
			*/
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
	return {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			finalCall: queryOptions.limit > totalDocs,
		},
		results: newsDocs.filter((doc) => doc != null),
	};
});

exports.loadSlideshow = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		previousDocID: data.lastLoadedDocID as string | undefined,
	};

	const COLLECTION = 'slideshowImages';
	const db = admin.firestore();

	let query = db.collection(COLLECTION).orderBy('uploaded', 'desc');
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		const snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	const imageSnapshot = await query.limit(queryOptions.limit).get();

	// Get the documents returned from the query
	const docs = imageSnapshot.docs;
	// if null, return with an error
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: docs ? true : false,
			},
			results: docs ? [] : null,
		};
	}

	log(`Loaded ${docs.length} image docs.`);

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	const lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.

	const imageDocs: (SlideshowImageDocument | null)[] = await Promise.all(
		docs.map(async (doc) => {
			// Get the document data
			try {
				var data = new SlideshowImageFirebaseDocument(doc.data());
				log(`Succeded creating SlideShowImageFirebaseDocument from ${doc.id}`);
			} catch (err) {
				log(`Failed creating SlideShowImageFirebaseDocument from ${doc.id}: ${err}`);
				return null;
			}

			// log(`Loading image: '${JSON.stringify(data)}'`);

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
				// log(`Returning data: '${JSON.stringify(document)}'`);

				return document;
			} catch (err) {
				log(`Error getting image for '${path}': ${err}`, true);
				return null;
			}
		})
	);
	return {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			finalCall: queryOptions.limit > docs.length,
		},
		results: imageDocs.filter((doc) => {
			return doc != null;
		}),
	};
});

exports.loadRabbisByIDs = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);
	// check if data.documentIDs is an array
	if (!Array.isArray(data.documentIDs ?? false))
		throw new Error('data.documentIDs must be an array of strings');

	// check if data.documentIDs is not empty
	// if (data.documentIDs.length == 0) throw new Error('data.documentIDs must not be empty');
	// check if data.documentIDs only contains strings
	for (const id of data.documentIDs)
		if (typeof id !== 'string') throw new Error('data.documentIDs must only contain strings');

	let documentIDs: string[] = data.documentIDs;
	const COLLECTION = 'rebbeim';
	const db = admin.firestore();

	// Get the document data
	let unfilteredContentDocs: (Author | null)[] = await Promise.all(
		documentIDs.map(async (docID) => {
			// Fetch the document with the specified ID from Firestore.
			const snapshot = await db.collection(COLLECTION).doc(docID).get();
			// If the document does not exist, return null
			if (!snapshot.exists) return null;
			// Get the document data
			try {
				return await getRabbiFor(docID, true);
			} catch (err) {
				log(`Error getting data for docID: '${docID}': ${err}`, true);
				return null;
			}
		})
	);

	let contentDocs = unfilteredContentDocs.filter((doc) => {
		return doc != null;
	}) as Author[];

	return {
		metadata: {
			lastLoadedDocID: contentDocs.length > 0 ? contentDocs[contentDocs.length - 1].id : null,
			finalCall: documentIDs.length > contentDocs.length,
		},
		results: contentDocs,
	};
});

exports.loadContentByIDs = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);
	// check if data.documentIDs is an array
	if (!Array.isArray(data.documentIDs))
		throw new Error('data.documentIDs must be an array of strings');

	// check if data.documentIDs is not empty
	// if (data.documentIDs.length == 0) throw new Error('data.documentIDs must not be empty');
	// check if data.documentIDs only contains strings
	for (const id of data.documentIDs)
		if (typeof id !== 'string') throw new Error('data.documentIDs must only contain strings');

	let documentIDs: string[] = data.documentIDs;
	const COLLECTION = 'content';
	const db = admin.firestore();

	// Get the document data
	let unfilteredContentDocs: (ContentDocument | null)[] = await Promise.all(
		documentIDs.map(async (docID) => {
			// Fetch the document with the specified ID from Firestore.
			const snapshot = await db.collection(COLLECTION).doc(docID).get();

			const rawData = snapshot.data();
			if (!rawData) return null;
			if (rawData!.pending == true) return null;

			// Get the document data
			try {
				var data = new ContentFirebaseDocument(rawData!);
			} catch {
				return null;
			}

			const tagData = {
				id: data.tagData.id,
				name: data.tagData.name,
				displayName: data.tagData.displayName,
			};
			try {
				const sourceURL = await getURLFor(`${data.source_path}`);
				const author = await getRabbiFor(data.attributionID, true);
				return {
					id: docID,
					fileID: strippedFilename(data.source_path),
					attributionID: data.attributionID,
					title: data.title,
					description: data.description,
					duration: data.duration,
					date: data.date,
					type: data.type,
					source_url: sourceURL,
					author: author,
					tagData: tagData,
					pending: data.pending,
				};
			} catch (err) {
				log(`Error getting data for docID: '${docID}': ${err}`, true);
				return null;
			}
		})
	);

	let contentDocs = unfilteredContentDocs.filter((doc) => {
		return doc != null;
	}) as ContentDocument[];

	return {
		metadata: {
			lastLoadedDocID: contentDocs.length > 0 ? contentDocs[contentDocs.length - 1].id : null,
			finalCall: documentIDs.length > contentDocs.length,
		},
		results: contentDocs,
	};
});

/**
 * @remarks
 * Returns a list of rebbeim in firebase
 * 
 * @param limit - The max amount of rebbeim to return, default is 10
 * @param lastLoadedDocID - Optional id of the last document retreived used to paginate the data
 * @param includePictureURLs - Indicates whether or not profile picture URLs should be generated and included
 * @param includeServiceProfiles - Indicates whether or not to include service profiles, including 'Guest Speaker'
 */
exports.loadRebbeim = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		previousDocID: data.lastLoadedDocID as string | undefined,
		includePictureURLs: data.includePictureURLs as boolean | undefined,
		includeServiceProfiles: data.includeServiceProfiles as boolean | false,
	};

	const COLLECTION = 'rebbeim';
	const db = admin.firestore();

	const GUEST_SPEAKER_ID = 'hn2GBxMrEbRSVtaxPC2K';

	let query = db.collection(COLLECTION)
		.orderBy('name', 'asc');

		// pagination
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		const snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// limiting, rebbeim in database are not expected to exceed a reasonable amount
	if (queryOptions.limit > 0) {
		query = query.limit(queryOptions.limit);
	}

	// Execute the query
	const rebbeimSnapshot = await query.get();

	// Get the documents returned from the query
	const docs = rebbeimSnapshot.docs;
	// if null, return
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: docs ? true : false,
			},
			results: docs ? [] : null,
		};
	}

	log(`Loaded ${docs.length} rebbeim documents.`);

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	const lastDocumentFromQueryID = docs[docs.length - 1].id;

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the rebbeim array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.
	const rebbeimDocs: (RebbeimDocument | null)[] = await Promise.all(
		docs.map(async (doc) => {
			if (!queryOptions.includeServiceProfiles) {
				if (doc.id == GUEST_SPEAKER_ID) {
					return null;
				}
			}

			// Get the document data
			try {
				var data = new RebbeimFirebaseDocument(doc.data());
			} catch {
				return null;
			}

			// log(`Loading rabbi: '${JSON.stringify(data)}'`);

			// Get the image path
			const path = data.profile_picture_filename;

			// Get the image URL
			try {
				const pfpURL = await getURLFor(`profile-pictures/${path}`);
				// return the document data
				const document: RebbeimDocument = {
					id: doc.id,
					name: data.name,
					profile_picture_url: pfpURL,
				};
				return document;
			} catch (err) {
				log(`Error getting image for '${path}': ${err}`, true);
				return null;
			}
		})
	);

	return {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			finalCall: queryOptions.limit > docs.length,
		},
		results: rebbeimDocs.filter((doc) => {
			return doc != null;
		}),
	};
});

exports.loadAlert = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	const db = admin.firestore();
	const COLLECTION = 'alerts';

	let query = db.collection(COLLECTION).orderBy('dateIssued', 'desc');

	const alert = await query.limit(1).get();
	if (alert.docs && alert.docs.length > 0 && alert.docs[0].exists) {
		const doc = alert.docs[0];
		const data = new AlertFirebaseDocument(doc.data());
		const document: AlertDocument = {
			id: doc.id,
			title: data.title,
			body: data.body,
			dateIssued: data.dateIssued,
			dateExpired: data.dateExpired,
		};

		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: true,
			},
			results: data.dateExpired.toDate() < new Date() ? null : [document],
		};
	} else {
		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: true,
			},
			results: null,
		};
	}
});

exports.loadContent = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		previousDocID: data.lastLoadedDocID as string | undefined,
		includeThumbnailURLs: data.includeThumbnailURLs as boolean,
		includeAllAuthorData: (data.includeAllAuthorData as boolean) || false,
		search: data.search as
			| {
					field: string;
					value: string;
			  }
			| undefined,
		pending: (data.pending as boolean) || false,
	};

	const COLLECTION = 'content';
	const db = admin.firestore();
	let query = db
		.collection(COLLECTION)
		.where('pending', '==', queryOptions.pending)
		.orderBy('date', 'desc');
	if (queryOptions.search) {
		// Make sure the field and value are set
		if (!queryOptions.search.field || !queryOptions.search.value) {
			throw new https.HttpsError('invalid-argument', 'The search field and value must be set.');
		}
		if (queryOptions.search.field == 'tagID') {
			// If it's a tag ID, we need to get the tag document using the tag ID
			const tagSnapshot = await db.collection('tags').doc(queryOptions.search.value).get();
			// If the tag document doesn't exist, return
			if (!tagSnapshot.exists) {
				return {
					metadata: {
						lastLoadedDocID: null,
						finalCall: true,
					},
					results: null,
				};
			}
			// Get the tag document
			const tagDoc = new TagFirebaseDocument(tagSnapshot.data()!);
			// If the tag is a child tag, we're good to go.
			// Otherwise, it't a parent tag, so we need to get all the child tags
			if (tagDoc.isParent) {
				let subCategoryIDs = tagDoc.subCategories!;
				// Get the child tags
				// Search the tags collection for all tags with a parentTagID equal to the tagID
				query = query.where('tagData.id', 'in', subCategoryIDs) as any;
			} else {
				query = query.where('tagData.id', '==', queryOptions.search.value) as any;
				log(`Only getting content where tagID == ${queryOptions.search.value}`);
			}
		} else {
			query = query.where(queryOptions.search.field, '==', queryOptions.search.value) as any;
			log(
				`Only getting content where ${queryOptions.search.field} == ${queryOptions.search.value}`
			);
		}
	} else {
		log(
			`Not filtering by search, sorting by upload date queryOptions.search: ${queryOptions.search}`
		);
	}

	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		const snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot) as any;
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	const contentSnapshot = await query.limit(queryOptions.limit).get();
	// Get the documents returned from the query
	const docs = contentSnapshot.docs;
	// If null, return
	if (!docs || docs.length == 0) {
		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: docs ? true : false,
			},
			results: docs ? [] : null,
		};
	}

	// Set a variable to hold the ID of the last document returned from the query.
	// This is so the client can use this ID to load the next page of documents.
	const lastDocumentFromQueryID = docs[docs.length - 1].id;
	console.log('Last document ID to be served: ' + lastDocumentFromQueryID);

	// Loop through the documents returned from the query.
	// For each document, get the desired data and add it to the content array.
	// Since we are using the await keyword, we need to make the
	// function asynchronous. Because of this, the function returns a Promise and
	// in turn, docs.map() returns an array of Promises.
	// To deal with this, we are passing that array of Promises to Promise.all(), which
	// returns a Promise that resolves when all the Promises in the array resolve.
	// To finish it off, we use await to wait for the Promise returned by Promise.all()
	// to resolve.
	const contentDocs: (ContentDocument | null)[] = await Promise.all(
		docs.map(async (doc) => {
			// Get the document data
			try {
				var data = new ContentFirebaseDocument(doc.data());
			} catch {
				return null;
			}

			const tagData = {
				id: data.tagData.id,
				name: data.tagData.name,
				displayName: data.tagData.displayName,
			};
			try {
				const sourceURL = await getURLFor(`${data.source_path}`);
				const author = await getRabbiFor(data.attributionID, queryOptions.includeAllAuthorData);
				return {
					id: doc.id,
					fileID: strippedFilename(data.source_path),
					attributionID: data.attributionID,
					title: data.title,
					description: data.description,
					duration: data.duration,
					date: data.date,
					type: data.type,
					source_url: sourceURL,
					author: author,
					tagData: tagData,
					pending: data.pending,
				};
			} catch (err) {
				log(`Error getting data for docID: '${doc.id}': ${err}`, true);
				return null;
			}
		})
	);

	return {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			finalCall: queryOptions.limit > docs.length,
		},
		results: contentDocs
			.filter((doc) => {
				return doc != null;
			})
			.sort((lhs, rhs) => {
				return lhs!.date < rhs!.date ? 1 : -1;
			}),
	};
});

exports.generateHLSStream = storage
	.bucket()
	.object()
	.onFinalize(async (object) => {
		// check if file is user uploaded
		const userUpload = object.name!.startsWith('user-submissions/');
		// Exit if this is triggered on a file that is not uplaoded to the content folder.
		if (!object.name!.startsWith('content/') && !userUpload) {
			return log(`File ${object.name} is not in the content folder. Exiting...`);
		}

		const storageObj = new Storage();
		const bucket = storageObj.bucket(object.bucket);

		const filepath = object.name!;
		const filename = strippedFilename(filepath);
		const tempFilePath = path.join(os.tmpdir(), filename);

		// limit file size to 250 mb
		if (parseInt(object.size) > 262144000) {
			return log(`File ${object.name} is too large. Exiting...`);
		}

		// Download file from bucket.
		await bucket.file(filepath).download({
			destination: tempFilePath,
			validation: false,
		});

		let newFolderPrefix = `HLSStreams/audio`;

		if (userUpload) {
			// count number of pending firebase documents
			const db = admin.firestore();
			const pendingCount = await db.collection('content').where('pending', '==', true).get();

			if (pendingCount.size > 400) {
				// delete file and return
				log(`Too many pending documents. Deleting file at ${object.name}`);
				return bucket.file(filepath).delete();
			}

			log('Detected user upload, running checks...');
			// sha256 hash the file
			const fileBuffer = fs.readFileSync(tempFilePath);
			const hashSum = crypto.createHash('sha256');
			hashSum.update(fileBuffer);
			const hex = hashSum.digest('hex');
			log(`File named ${filename} has hash: ${hex}`);

			// check that filename == hash
			if (filename != hex) {
				log(`Filename ${filename} does not match hash of content file ${hex}`);
				log(`Deleting file at ${object.name}`);
				await bucket.file(object.name!).delete();
				return 'Failed to authenticate file';
			} else {
				log(`Filename ${filename} matches hash of content file ${hex}`);
				// check if database has matching document
				var newFolderPath = newFolderPrefix + '/' + hex;
				const doc = await db
					.collection('content')
					.where('source_path', '==', newFolderPath + `/${hex}` + '.m3u8')
					.get();

				if (doc.empty) {
					// no matching document, delete file
					log(`No matching firebase document for file to be placed at ${newFolderPath}`);
					log(`Deleting file at ${object.name}`);
					await bucket.file(filepath).delete();
					return 'Failed to authenticate file';
				} else {
					// NOTE: Doesn't check for multiple matches
					log(`Found matching firebase document for file ${filename}: ${doc.docs[0].id}`);
				}
			}
		} else {
			var newFolderPath = newFolderPrefix + '/' + filename;
		}

		const inputPath = tempFilePath;
		const outputDir = path.join(os.tmpdir(), 'HLSStreams');
		log(`Input path: ${inputPath}`);
		log(`Output dir: ${outputDir}`);

		// Create the output directory if it does not exist
		await childProcessPromise.spawn('mkdir', ['-p', outputDir]);
		// Empty the output directory if it exists
		await childProcessPromise.spawn('rm', ['-rf', `${outputDir}/*`]);

		// Create the HLS stream
		let ffmpegArgs = [
			'-y',
			'-i',
			inputPath,
			'-hls_time',
			'10',
			'-hls_list_size',
			'0',
			'-hls_flags',
			'append_list',
			'-hls_segment_filename',
			`${outputDir}/${filename}_%d.ts`,
			`${outputDir}/${filename}.m3u8`,
		];

		if (object.contentType?.startsWith('audio/')) {
			ffmpegArgs.splice(3, 0, '-vn');
		}

		log(`ffmpegArgs: ${ffmpegArgs}`);
		try {
			await childProcessPromise.spawn(ffmpeg.path, ffmpegArgs, {
				stdio: 'inherit',
			});
		} catch (err) {
			log(`Error creating HLS stream for ${filename}: ${err}`);
		}

		log(`Uploading HLS stream from ${outputDir}`);

		const filenames = readdirSync(outputDir);

		// Upload the HLS stream to the bucket asynchronously
		await Promise.all(
			filenames.map((filePart) => {
				const fp = path.join(outputDir, filePart);
				log(`Uploading ${fp}...`);
				return bucket.upload(fp, {
					destination: `${newFolderPath}/${filePart}`,
					metadata: {
						'Cache-Control': 'public,max-age=3600',
					},
				});
			})
		);
		console.log('Uploaded all files.');

		// Delete the file in the content folder
		bucket.file(filepath).delete();
	});

exports.generateThumbnail = storage
	.bucket()
	.object()
	.onFinalize(async (object) => {
		// if it's a .ts file exit
		if (object.name!.endsWith('.ts')) {
			log(`File ${object.name} is part of a HLSS stream.`);
			return;
		}
		// Step 1: Preliminary filetype check
		// Exit if this is triggered on a file that is not a video.
		if (!object.contentType!.startsWith('video/')) {
			return log(`File ${object.name} is not a video. Exiting...`);
		}
		// Step 2: Download the file from the bucket to a temporary folder
		const filepath = object.name;
		const filename = strippedFilename(filepath!);
		const storage = new Storage();
		const bucket = storage.bucket(object.bucket);
		const tempFilePath = path.join(os.tmpdir(), filename);
		await bucket.file(filepath).download({
			destination: tempFilePath,
			validation: false,
		});
		const inputPath = tempFilePath;
		const outputDir = path.join(os.tmpdir(), 'thumbnails');
		// Step 3: Create the output folder
		await childProcessPromise.spawn('mkdir', ['-p', outputDir]);
		// delete everything in the output directory
		await childProcessPromise.spawn('rm', ['-rf', `${outputDir}/*`]);

		// Step 4: Generate the thumbnail using ffmpeg
		try {
			await childProcessPromise.spawn(
				ffmpeg.path,
				[
					'-ss',
					'0',
					'-i',
					inputPath,
					'-y',
					'-vframes',
					'1',
					'-vf',
					'scale=512:-1',
					'-update',
					'1',
					`${outputDir}/${filename}.jpg`,
				],
				{ stdio: 'inherit' }
			);
		} catch (error) {
			logger.error(`Error: ${error}`);
		}
		// Step 5: Upload the thumbnail to the bucket
		const metadata = {
			contentType: 'image/jpeg',
			// To enable Client-side caching you can set the Cache-Control headers here:
			'Cache-Control': 'public,max-age=3600',
		};
		await bucket.upload(`${outputDir}/${filename}.jpg`, {
			destination: `thumbnails/${filename}.jpg`,
			metadata: metadata,
		});
		// Step 6: Delete the temporary file
		unlinkSync(tempFilePath);
	});

exports.loadCategories = https.onCall(async (callData, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);
	if (callData == null) {
		// This will happen if the function is called from outdated clients (<= v1.1.3 (2))
		callData = {};
	}
	const queryOptions = {
		flatList: callData.flatList || (false as boolean),
	};
	// This function will load all tags documents from the database and return them in JSON format.
	const COLLECTION = 'tags';
	const db = admin.firestore();
	let query = db.collection(COLLECTION);
	let querySnapshot = await query.get();
	if (querySnapshot.empty) {
		return {
			metadata: {
				lastLoadedDocID: null,
				finalCall: true,
			},
			results: [],
		};
	}
	let categories: TagDocument[] = [];
	querySnapshot.forEach((doc) => {
		let data = new TagFirebaseDocument(doc.data());
		let category: TagDocument = {
			id: doc.id,
			name: data.name,
			displayName: data.displayName,
			isParent: data.isParent || false,
		};
		if (data.subCategories) {
			category.subCategories = data.subCategories
				.map((subCategoryID: string) => {
					// Get the subcategory document
					let subCategory = querySnapshot.docs.find((doc) => doc.id === subCategoryID);
					if (!subCategory) {
						return null;
					}
					let subCategoryData = new TagFirebaseDocument(subCategory.data());
					return {
						id: subCategory.id,
						name: subCategoryData.name,
						displayName: subCategoryData.displayName,
						isParent: subCategoryData.isParent || false, // This should always be false
					} as TagDocument;
				})
				.filter((subCategory) => subCategory !== null) as TagDocument[];
		}
		// Add the category to the list if
		// it does not have a parentID OR
		// we are loading the flat list
		if (!data.parentID || queryOptions.flatList) categories.push(category);
		if (queryOptions.flatList) categories = categories.filter((category) => !category.isParent);
		// Sort alphabetically
		categories.sort((a, b) => {
			if (a.displayName < b.displayName) return -1;
			if (a.displayName > b.displayName) return 1;
			return 0;
		});
	});
	return {
		metadata: {
			lastLoadedDocID: querySnapshot.docs[querySnapshot.docs.length - 1].id,
			finalCall: true,
		},
		results: categories,
	};
});

exports.incrementViewCount = https.onCall(async (callData, context): Promise<void> => {
	// === APP CHECK ===
	verifyAppCheck(context);
	// This function will increase the view count for the content with the given ID.
	// This function will only work if the user is authenticated.
	if (typeof callData.documentID !== 'string') return;
	let documentID = callData.documentID as string;
	const COLLECTION = 'content';
	const db = admin.firestore();
	let query = db.collection(COLLECTION).doc(documentID);
	let querySnapshot = await query.get();
	if (querySnapshot.exists) {
		let data = new ContentFirebaseDocument(querySnapshot.data()!);
		if (!data.viewCount) data.viewCount = 0;
		let newData = {
			viewCount: data.viewCount + 1,
		};
		await query.set(newData, { merge: true });
	}
});

exports.search = https.onCall(async (callData, context): Promise<any> => {
	// === APP CHECK ===
	verifyAppCheck(context);
	const defaultSearchOptions = {
		content: {
			limit: 5,
			includeThumbnailURLs: false,
			includeDetailedAuthorInfo: false,
			startAfterDocumentID: null,
		},
		rebbeim: {
			limit: 10,
			includePictureURLs: false,
			startAfterDocumentID: null,
		},
	};

	const searchOptions = supplyDefaultParameters(defaultSearchOptions, callData.searchOptions);

	log(`Searching with options: ${JSON.stringify(searchOptions)}`);

	const errors: string[] = [];

	const db = admin.firestore();

	if (!callData.searchQuery) {
		return {
			results: null,
			errors: ['This function requires a search query.'],
			request: searchOptions,
			metadata: null,
		};
	}
	const searchQuery = callData.searchQuery.toLowerCase();
	const searchArray = searchQuery.split(' ');

	// const phrasesToRemove = ['rabbi', 'the'];
	// // remove phrases from the search query
	// searchArray.forEach((phrase, index) => {
	// 	if (phrasesToRemove.includes(phrase)) {
	// 		searchArray.splice(index, 1);
	// 	}
	// });

	log(`Searching for ${searchArray}`);

	const documentsThatMeetSearchCriteria: QueryDocumentSnapshot[] = [];
	// For each collection, run the following async function:

	let databases: string[] = [];
	if (searchOptions['content'].limit > 0) {
		databases.push('content');
	} else {
		databases.push('skip');
	}
	if (searchOptions['rebbeim'].limit > 0) {
		databases.push('rebbeim');
	} else {
		databases.push('skip');
	}

	const docs = await Promise.all(
		databases.map(async (collectionName) => {
			if (collectionName == 'skip') {
				return null;
			}

			if (!Number.isInteger(searchOptions[collectionName].limit)) {
				errors.push(`Limit for ${collectionName} is not an integer.`);
				return [];
			}

			if (searchOptions[collectionName].limit > 15) {
				searchOptions[collectionName].limit = 15;
				errors.push(`Limit for ${collectionName} is greater than 15. Setting limit to 15.`);
			}
			// Get the collection
			var query = db.collection(collectionName);

			query = query.where('search_index', 'array-contains-any', searchArray) as any;

			switch (collectionName) {
				case 'content':
					query = query.where('pending', '==', false) as any;
					query = query.orderBy('date', 'desc') as any;
					break;
				case 'rebbeim':
					query = query.orderBy('name', 'asc') as any;
					break;
			}

			// query = query.orderBy(searchOptions.orderBy[collectionName].field, searchOptions.orderBy[collectionName].order);
			if (searchOptions[collectionName].startAfterDocumentID) {
				const startAfter = searchOptions[collectionName].startAfterDocumentID;
				await db
					.collection(collectionName)
					.doc(startAfter)
					.get()
					.then((snapshot) => {
						query = query.startAfter(snapshot) as any;
						log(`Starting collection '${collectionName}' after document ID: ${startAfter}`);
					})
					.catch((reason) => {
						log(`Error starting collection '${collectionName}' after document ID: ${startAfter}`);
						return null;
					});
			}

			query = query.limit(searchOptions[collectionName].limit) as any;
			// if (searchOptions[collectionName].includeThumbnailURLs);
			// if (searchOptions[collectionName].includeDetailedAuthorInfo);

			const contentSnapshot = await query.get();
			const docs = contentSnapshot.docs;
			for (const doc of docs) documentsThatMeetSearchCriteria.push(doc);
			return docs;
		})
	);

	const rawContent = docs[0];
	const rawRebbeim = docs[1];

	let content: (ContentDocument | null)[] | null;

	if (rawContent != null) {
		content = await Promise.all(
			rawContent.map(async (doc) => {
				// Get the document data
				try {
					var data = new ContentFirebaseDocument(doc.data());
				} catch {
					return null;
				}

				const tagData = {
					id: data.tagData.id,
					name: data.tagData.name,
					displayName: data.tagData.displayName,
				};

				try {
					const sourceURL = await getURLFor(`${data.source_path}`);
					const author = await getRabbiFor(
						data.attributionID,
						searchOptions.content.includeDetailedAuthorInfo
					);

					return {
						id: doc.id,
						fileID: strippedFilename(data.source_path),
						attributionID: data.attributionID,
						title: data.title,
						description: data.description,
						duration: data.duration,
						date: data.date,
						type: data.type,
						source_url: sourceURL,
						author: author,
						tagData: tagData,
						pending: data.pending,
					};
				} catch (err) {
					errors.push(err as string);
					return null;
				}
			})
		);
	} else {
		content = null;
	}

	let rebbeim: (RebbeimDocument | null)[] | null;
	// check if rawRebbeim is null
	if (rawRebbeim != null) {
		rebbeim = await Promise.all(
			rawRebbeim.map(async (doc) => {
				// Get the document data
				try {
					var data = new RebbeimFirebaseDocument(doc.data());
				} catch {
					return null;
				}

				// Get the image path
				const path = data.profile_picture_filename;
				// Get the image URL
				try {
					const pfpURL = await getURLFor(`profile-pictures/${path}`);
					// return the document data
					const document: RebbeimDocument = {
						id: doc.id,
						name: data.name,
						profile_picture_url: pfpURL,
					};
					return document;
				} catch (err) {
					errors.push(err as string);
					return null;
				}
			})
		);
	} else {
		rebbeim = null;
	}

	const result = {
		results: {
			content: rawContent ? content : null,
			rebbeim: rawRebbeim ? rebbeim : null,
		},
		errors: errors,
		request: searchOptions,
		metadata: {
			content: {
				lastLoadedDocID: rawContent
					? rawContent.length > 0
						? rawContent[rawContent.length - 1].id
						: null
					: null,
				finalCall: rawContent ? searchOptions.content.limit > rawContent.length : null,
			},
			rebbeim: {
				lastLoadedDocID: rawRebbeim
					? rawRebbeim.length > 0
						? rawRebbeim[rawRebbeim.length - 1].id
						: null
					: null,
				finalCall: rawRebbeim ? searchOptions.rebbeim.limit > rawRebbeim.length : null,
			},
		},
	};

	log(`Result: ${JSON.stringify(result)}`);
	return result;
});

exports.submitShiur = functions.https.onCall(async (data, context) => {
	const db = admin.firestore();

	verifyAppCheck(context);

	log(`Submitting shiur: ${JSON.stringify(data)}`);
	const filename = data.filename;

	const submission: SubmittedContentDocument = {
		attributionID: data.attributionID,
		title: data.title,
		description: data.description,
		duration: data.duration,
		date: data.date || new Date(),
		type: data.type,
		tagID: data.tagID,
	};

	// check that there is a attributionID
	if (!submission.attributionID || submission.attributionID.length === 0) {
		log(`No attributionID provided`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}

	// find author for attributionID
	const author = await getRabbiFor(submission.attributionID, false);
	if (!author) {
		log(`No author found for attributionID: ${submission.attributionID}`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}

	// check that there is a title
	if (!submission.title || submission.title.length === 0) {
		log(`No title provided`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}

	// check that there is a description
	if (!submission.description) {
		submission.description = '';
		// return {
		// 	status: 'denied',
		// 	message: 'Insufficient data',
		// };
	}

	// check that there is a duration
	if (!submission.duration || submission.duration < 60) {
		log(`No duration provided`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}

	//  only allow type audio
	if (submission.type != 'audio' && submission.type != 'video') {
		log(`Invalid type: ${submission.type}`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}

	// check that there is a tagID
	if (!submission.tagID || submission.tagID.length === 0) {
		log(`No tagID provided`);
		return {
			status: 'denied',
			message: 'Insufficient data',
		};
	}
	// find tag for tagID
	const tag = await getTagFor(submission.tagID);
	if (!tag) {
		log(`No tag found for tagID: ${submission.tagID}`);
		return {
			status: 'denied',
			message: 'Bad data',
		};
	}

	const fileID = generateFileID(filename);

	// ensure number of pending documents is not greater than 400
	const pendingDocs = await db.collection('content').where('pending', '==', true).get();
	if (pendingDocs.size > 400) {
		return {
			status: 'denied',
			message: 'Submissions not being accepted at this time',
		};
	}

	// get uid if exists
	const uid = context.auth?.uid;
	log(`uid: ${uid}`);

	//  create a prospective content document
	const prospectiveContent: ProspectiveContentDocument = {
		fileID: fileID,
		attributionID: submission.attributionID,
		title: submission.title,
		description: submission.description,
		duration: submission.duration,
		date: submission.date,
		type: submission.type,
		source_path: `HLSStreams/${submission.type}/${fileID}/${fileID}.m3u8`,
		author: author.name,
		tagData: {
			id: tag.id,
			name: tag.name,
			displayName: tag.displayName,
		},
		pending: true,
		upload_data: {
			// Note: Clients are authenticated via anonyomous auth
			uid: uid || null,
			timestamp: admin.firestore.Timestamp.now(),
		},
	};

	log(`Shiur passed auto-inspection. Uploading to Firebase...`);

	// upload to firebase

	try {
		await db.collection('content').add(prospectiveContent);
		log(`Shiur uploaded to Firebase.`);
		return {
			status: 'success',
			message: 'Shiur submitted',
		};
	} catch (err) {
		log(`Error uploading to Firebase: ${err}`);
		return {
			status: 'failed',
			message: 'Internal error',
		};
	}
});

function generateFileID(filename: string): string {
	return strippedFilename(filename);
}

exports.reloadDocuments = https.onCall((data, context) => {
	let collectionName = data.collectionName;
	var db = admin.firestore();
	db.collection(collectionName)
		.get()
		.then(async (snapshot) => {
			snapshot.forEach(async (s) => {
				var doc = db.collection(collectionName).doc(s.id);
				await doc
					.set(
						{
							temp: `temp`,
						},
						{
							merge: true,
						}
					)
					.then(() => {
						setTimeout(function () {
							doc.set(
								{
									temp: FieldValue.delete(),
								},
								{
									merge: true,
								}
							);
						}, 10000);
					});
			});
		});
});

const ignoreWords = ['the', 'and', 'of', 'a', 'an', 'in', 'for', 'is', 'rabbi'];

exports.updateContentData = functions.firestore
	.document(`content/{contentID}`)
	.onWrite(async (ev) => {
		if (ev.after.data != undefined) {
			let data = ev.after.data();
			let components = [];
			let titleComponents = data.title
				.replace(/[^a-z\d\s]+/gi, '')
				.toLowerCase()
				.split(' ')
				.filter((x) => !ignoreWords.includes(x));
			let authorNameComponents = data.author
				.replace(/[^a-z\d\s]+/gi, '')
				.toLowerCase()
				.split(' ')
				.filter((x) => x != 'rabbi');
			let tagName = data.tagData.displayName
				.replace(/[^a-z\d\s]+/gi, '')
				.toLowerCase()
				.split(' ');

			components = components.concat(titleComponents);
			components = components.concat(authorNameComponents);
			components = components.concat(tagName);

			log(`Components for ${data.title}: ${components}`);

			var db = admin.firestore();
			let doc = db.collection('content').doc(ev.after.id);

			await doc.set(
				{
					search_index: components,
					title: titleFormat(data.title),
				},
				{
					merge: true,
				}
			);
		}
	});

exports.updateRabbiData = functions.firestore.document(`rebbeim/{rabbiID}`).onWrite(async (ev) => {
	if (ev.after.data != undefined) {
		let data = ev.after.data();
		let components = [];
		let nameComponents = data.name
			.replace(/[^a-z\d\s]+/gi, '')
			.toLowerCase()
			.split(' ')
			.filter((x) => x != 'rabbi');

		components = components.concat(nameComponents);

		log(`Components for ${data.name}: ${components}`);

		var db = admin.firestore();
		let doc = db.collection('rebbeim').doc(ev.after.id);

		await doc.set(
			{
				search_index: components,
				name: nameFormat(data.name),
			},
			{
				merge: true,
			}
		);
	}
});

const lowercase = ['the', 'and', 'of', 'a', 'an', 'in', 'for', 'is', 'zt"l', "zt'l"];

function titleFormat(s) {
	const titleComponents = s.split(' ');
	const title = titleComponents.map((x) => {
		if (x.length > 1 && lowercase.indexOf(x.toLowerCase()) == -1) {
			return x.replace(/\w\S*/g, function (t) {
				return t.charAt(0).toUpperCase() + t.substr(1).toLowerCase();
			});
		} else if (
			x.length > 1 &&
			titleComponents.indexOf(x) != 0 &&
			lowercase.indexOf(x.toLowerCase()) != -1
		) {
			return x.toLowerCase();
		} else {
			return x;
		}
	});
	return title.join(' ');
}

function nameFormat(s) {
	const titleComponents = s.split(' ');
	const title = titleComponents.map((x) => {
		if (x.length > 1 && lowercase.indexOf(x.toLowerCase()) == -1) {
			return x.replace(/\w\S*/g, function (t) {
				return t.charAt(0).toUpperCase() + t.substr(1).toLowerCase();
			});
		} else if (
			x.length > 1 &&
			titleComponents.indexOf(x) != 0 &&
			lowercase.indexOf(x.toLowerCase()) != -1
		) {
			return x.toLowerCase();
		} else {
			return x;
		}
	});
	return title.join(' ');
}

exports.cleanStorage = https.onCall(async (data, context) => {
	const bucket = admin.storage().bucket('gs://yeshivat-torat-shraga.appspot.com/');
	const files = await bucket.getFiles();
	const filenames = files.map((file) => file.name);
	const filesToDelete = filenames.filter(
		(file) => file.startsWith('content/') || file.startsWith('thumbnails/')
	);
	await filesToDelete.map((file) => bucket.file(file).delete());
	log(`Deleted ${filesToDelete.length} files in content/ and thumbnails/`);

	const hlsFilenames = filenames.filter((file) => file.startsWith('HLSStreams/'));
	// check each file if it has a corresponding firebase document
	const db = admin.firestore();
	const hlsFilesToDelete = await hlsFilenames.filter(async (file) => {
		const doc = await db.collection('content').where('fileID', '==', strippedFilename(file)).get();

		if (doc.empty) {
			return file;
		} else {
			return null;
		}
	});

	await hlsFilesToDelete.map((file) => bucket.file(file).delete());
	log(`Deleted ${hlsFilesToDelete.length} files in HLSStreams/`);
	return;
});
