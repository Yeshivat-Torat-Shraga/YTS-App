import admin from 'firebase-admin';
import { https, storage, logger } from 'firebase-functions';
import ffmpeg from '@ffmpeg-installer/ffmpeg';
import childProcessPromise from 'child-process-promise';

import os from 'os';
import {
	AlertDocument,
	AlertFirebaseDocument,
	ContentDocument,
	ContentFirebaseDocument,
	LoadData,
	NewsDocument,
	NewsFirebaseDocument,
	RebbeimDocument,
	RebbeimFirebaseDocument,
	SlideshowImageDocument,
	SlideshowImageFirebaseDocument,
} from './types';
import {
	log,
	getURLFor,
	getRabbiFor,
	strippedFilename,
	supplyDefaultParameters,
	verifyAppCheck,
} from './helpers';
import path from 'path';
import { readdirSync, unlinkSync } from 'fs';
const Storage = require('@google-cloud/storage').Storage;

admin.initializeApp({
	projectId: 'yeshivat-torat-shraga',
	// credential: admin.credential.cert(
	// 	require('/Users/benjitusk/Downloads/firebase.json')
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

	return await admin
		.messaging()
		.send({
			notification: payload,
			topic: 'all',
		})
		.then((response) => {
			logger.info('Successfully sent message:', response);
			return `Successfully sent message: ${response}`;
		})
		.catch((error) => {
			logger.error('Error sending message:', error);
			return `Error sending message: ${error}`;
		});
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
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	const newsSnapshot = await query.limit(queryOptions.limit).get();

	// Get the documents returned from the query
	const docs = newsSnapshot.docs;
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
	return {
		metadata: {
			lastLoadedDocID: lastDocumentFromQueryID,
			finalCall: queryOptions.limit > docs.length,
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
				log(`Returning data: '${JSON.stringify(document)}'`);

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

exports.loadRebbeim = https.onCall(async (data, context): Promise<LoadData> => {
	// === APP CHECK ===
	verifyAppCheck(context);

	// Get the query options
	const queryOptions = {
		limit: (data.limit as number) || 10,
		previousDocID: data.lastLoadedDocID as string | undefined,
		includePictureURLs: data.includePictureURLs as boolean | undefined,
	};

	const COLLECTION = 'rebbeim';
	const db = admin.firestore();

	let query = db.collection(COLLECTION).orderBy('name', 'asc');
	if (queryOptions.previousDocID) {
		// Fetch the document with the specified ID from Firestore.
		const snapshot = await db.collection(COLLECTION).doc(queryOptions.previousDocID).get();
		// Overwrite the query to start after the specified document.
		query = query.startAfter(snapshot);
		log(`Starting after document '${snapshot}'`);
	}

	// Execute the query
	const rebbeimSnapshot = await query.limit(queryOptions.limit).get();

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
			// Get the document data
			try {
				var data = new RebbeimFirebaseDocument(doc.data());
			} catch {
				return null;
			}

			log(`Loading rabbi: '${JSON.stringify(data)}'`);

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
	if (alert.docs) {
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
	};

	const COLLECTION = 'content';
	const db = admin.firestore();
	let query = db.collection(COLLECTION);
	if (queryOptions.search) {
		if (queryOptions.search.field == 'tag') {
			query = query.where('tags', 'array-contains', queryOptions.search.value) as any;
			log(`Only getting content where [tags] contains ${queryOptions.search.value}`);
		} else {
			query = query.where(queryOptions.search.field, '==', queryOptions.search.value) as any;
			log(
				`Only getting content where ${queryOptions.search.field} == ${queryOptions.search.value}`
			);
		}
	} else {
		log(`Not filtering by search. queryOptions.search: ${queryOptions.search}`);
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

			try {
				const sourcePath = await getURLFor(`${data.source_path}`);
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
					source_url: sourcePath,
					author: author,
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
		results: contentDocs.filter((doc) => {
			return doc != null;
		}),
	};
});

exports.generateHLSStream = storage
	.bucket()
	.object()
	.onFinalize(async (object) => {
		// Exit if this is triggered on a file that is not uplaoded to the content folder.
		if (!object.name!.startsWith('content/')) {
			return log(`File ${object.name} is not in the content folder. Exiting...`);
		}
		const storageObj = new Storage();
		const bucket = storageObj.bucket(object.bucket);

		const filepath = object.name!;
		const filename = strippedFilename(filepath);
		const tempFilePath = path.join(os.tmpdir(), filename);

		// Download file from bucket.
		await bucket.file(filepath).download({
			destination: tempFilePath,
			validation: false,
		});

		const inputPath = tempFilePath;
		const outputDir = path.join(os.tmpdir(), 'HLSStreams');
		log(`Input path: ${inputPath}`);
		log(`Output dir: ${outputDir}`);

		// Create the output directory if it does not exist
		await childProcessPromise.spawn('mkdir', ['-p', outputDir]);
		// Empty the output directory if it exists
		await childProcessPromise.spawn('rm', ['-rf', `${outputDir}/*`]);

		// Create the HLS stream
		try {
			await childProcessPromise.spawn(
				ffmpeg.path,
				[
					'-y',
					'-i',
					inputPath,
					'-hls_list_size',
					'0',
					'-hls_time',
					'10',
					'-hls_segment_filename',
					`${outputDir}/${filename}-%03d.ts`,
					`${outputDir}/${filename}.m3u8`,
				],
				{
					stdio: 'inherit',
				}
			);
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
					destination: `HLSStreams/${object.contentType!.split('/')[0]}/${filename}/${filePart}`,
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
	const documentsThatMeetSearchCriteria = [];
	// For each collection, run the following async function:

	let databases = [];
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
			if (searchOptions[collectionName].limit > 30) {
				searchOptions[collectionName].limit = 30;
				errors.push(`Limit for ${collectionName} is greater than 30. Setting limit to 30.`);
			}
			// Get the collection
			let query = db.collection(collectionName);
			query = query.where('search_index', 'array-contains-any', searchArray) as any;
			switch (collectionName) {
				case 'content':
					query = query.orderBy('date', 'desc') as any;
					break;
				case 'rebbeim':
					query = query.orderBy('name', 'asc') as any;
					break;
			}

			// query = query.orderBy(searchOptions.orderBy[collectionName].field, searchOptions.orderBy[collectionName].order);
			if (searchOptions[collectionName].startFromDocumentID) {
				query = query.startAt(searchOptions[collectionName].startFromDocumentID) as any;
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

				try {
					const sourcePath = await getURLFor(`${data.source_path}`);
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
						source_url: sourcePath,
						author: author,
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

	return {
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
});
