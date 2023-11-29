import { logger } from 'firebase-functions';
import admin from 'firebase-admin';
import { Author, TagClient, TagFirebase } from './types';

export const ENABLEAPPCHECK = true;

export function log(data: any, structured = false): string {
	logger.log(data, {
		structuredData: structured,
	});

	return JSON.stringify(data);
}
export function info(data: any, structured = false): string {
	logger.info(data, {
		structuredData: structured,
	});

	return JSON.stringify(data);
}

export function warn(data: any, structured = false): string {
	logger.warn(data, {
		structuredData: structured,
	});

	return JSON.stringify(data);
}
export function error(data: any, structured = false): string {
	logger.error(data, {
		structuredData: structured,
	});

	return JSON.stringify(data);
}

export function debugLog(data: any, structured = false): string {
	logger.debug(data, {
		structuredData: structured,
	});

	return JSON.stringify(data);
}

export async function getRabbiFor(id: string, includeAllAuthorData: boolean): Promise<Author> {
	return new Promise(async (resolve, reject) => {
		const db = admin.firestore();
		db.collection('rebbeim')
			.doc(id)
			.get()
			.then(async (personSnapshot) => {
				const personData = personSnapshot.data();

				if (personData == undefined) {
					reject("Rabbi doesn't exist");
					return;
				}

				if (includeAllAuthorData) {
					const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
					const filename = personData.profile_picture_filename; // appendToEndOfFilename(personData.profilepic, '_300x1000');
					// bucket.file(`profile-pictures/resized/${filename}`).getSignedUrl({
					bucket
						.file(`profile-pictures/${filename}`)
						.getSignedUrl({
							action: 'read',
							expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // One week
						})
						.then((url) => {
							resolve({
								id: id,
								name: personData.name,
								profile_picture_filename: personData.profile_picture_filename,
								profile_picture_url: url[0],
							});
						})
						.catch((reason) => {
							reject(reason);
							log(`Rejected getRabbiFor(). Reason: ${reason}`);
						});
				} else {
					resolve({
						id: id,
						name: personData.name,
						profile_picture_filename: personData.profile_picture_filename,
					});
				}
			});
	});
}

export async function getTagFor(id: string): Promise<TagClient> {
	return new Promise(async (resolve, reject) => {
		const db = admin.firestore();
		try {
			const tagDoc = await db.collection('tags').doc(id).get();

			const data = tagDoc.data();
			if (data) {
				const fd = data as TagFirebase;

				const document: TagClient = {
					id: tagDoc.id,
					name: fd.name,
					displayName: fd.displayName,
					isParent: fd.isParent || false,
				};

				resolve(document);
			} else {
				reject('Tag undefined');
			}
		} catch (reason) {
			reject(reason);
		}
	});
}

export async function getURLFor(path: string): Promise<string> {
	return new Promise((resolve, reject) => {
		const bucket = admin.storage().bucket('yeshivat-torat-shraga.appspot.com');
		bucket
			.file(path)
			.getSignedUrl({
				action: 'read',
				expires: Date.now() + 1000 * 60 * 60 * 24 * 7, // 7 days
			})
			.then((url) => {
				resolve(url[0]);
			})
			.catch((err) => {
				reject(err);
				log(`Rejected getURLFor('${path}') becuase ${err}`, true);
			});
	});
}

export function strippedFilename(filename: string) {
	// Remove directory path
	const components = filename.split('/');
	// Remove file extension
	return components[components.length - 1].split('.')[0];
}

export function supplyDefaultParameters(
	def: any,
	prov: any
): {
	[key: string]: any;
	content: {
		limit: number;
		includeThumbnailURLs: boolean;
		includeDetailedAuthorInfo: boolean;
		startFromDocumentID: string | null;
	};
	rebbeim: {
		limit: number;
		includePictureURLs: boolean;
		startFromDocumentID: string | null;
	};
} {
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

export function isString(value: any) {
	return typeof value === 'string';
}
