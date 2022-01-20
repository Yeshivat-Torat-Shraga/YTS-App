import functions from 'firebase-functions';
import admin from 'firebase-admin';

export function log(data: any, structured = false) {
	functions.logger.info(data, {
		structuredData: structured,
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
