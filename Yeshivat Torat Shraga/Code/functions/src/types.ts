import admin from 'firebase-admin';
const FirebaseFirestore = admin.firestore;
import { log } from 'firebase-functions/logger';
import { isString } from './helpers';

export interface LoadData {
	metadata: {
		lastLoadedDocID: string | null;
		includesLastElement: boolean;
		error?: string;
	};
	results: any[] | null;
}

export interface NewsDocument {
	id: string;
	title: string;
	author: string;
	body: string;
	uploaded: FirebaseFirestore.Timestamp;
	imageURLs: string[] | null;
}

export interface SlideshowImageDocument {
	url: string;
	id: string;
	title: string | null;
	uploaded: FirebaseFirestore.Timestamp;
}

export interface RebbeimDocument {
	id: string;
	name: string;
	profile_picture_url: string;
}

export interface ContentDocument {
	id: string;
	fileID: string;
	attributionID: string;
	title: string;
	description: string;
	duration: number;
	date: FirebaseFirestore.Timestamp;
	type: string;
	source_url: string;
	author: Author;
}

export class NewsFirebaseDocument {
	author: string;
	body: string;
	date: FirebaseFirestore.Timestamp;
	imageURLs: string[];
	title: string;

	constructor(data: FirebaseFirestore.DocumentData) {
		if (
			isString(data.author) &&
			isString(data.body) &&
			data.date instanceof FirebaseFirestore.Timestamp &&
			Array.isArray(data.imageURLs) &&
			isString(data.title)
		) {
			this.author = data.author;
			this.body = data.body;
			this.date = data.date;
			this.imageURLs = data.imageURLs;
			this.title = data.title;
		} else {
			log(`Failed to initialize new object: ${JSON.stringify(data)}`);
			throw new Error('Invalid data');
		}
	}
}

export class SlideshowImageFirebaseDocument {
	/** The name of the file inside of the cloud storage folder */
	image_name: string;
	title: string;
	uploaded: FirebaseFirestore.Timestamp;

	constructor(data: FirebaseFirestore.DocumentData) {
		if (
			isString(data.image_name) &&
			data.uploaded instanceof FirebaseFirestore.Timestamp
		) {
			this.image_name = data.image_name;
			this.title = data.title;
			this.uploaded = data.uploaded;
			// log(`Succeeded initializing new object: ${JSON.stringify(data)}`);
		} else {
			log(`Failed to initialize new object: ${JSON.stringify(data)}`);
			throw new Error('Invalid data');
		}
	}
}

export class RebbeimFirebaseDocument {
	name: string;
	profile_picture_filename: string;
	search_index: string[];

	constructor(data: FirebaseFirestore.DocumentData) {
		if (
			isString(data.name) &&
			isString(data.profile_picture_filename) &&
			Array.isArray(data.search_index)
		) {
			this.name = data.name;
			this.profile_picture_filename = data.profile_picture_filename;
			this.search_index = data.search_index;
		} else {
			log(`Failed to initialize new object: ${JSON.stringify(data)}`);
			throw new Error('Invalid data');
		}
	}
}

export class ContentFirebaseDocument {
	attributionID: string;
	author: string;
	date: FirebaseFirestore.Timestamp;
	description: string;
	duration: number;
	search_index: string[];
	source_path: string;
	tags: string[];
	title: string;
	type: string;

	constructor(data: FirebaseFirestore.DocumentData) {
		if (
			isString(data.attributionID) &&
			isString(data.author) &&
			data.date instanceof FirebaseFirestore.Timestamp &&
			isString(data.description) &&
			typeof data.duration === 'number' &&
			Array.isArray(data.search_index) &&
			isString(data.source_path) &&
			Array.isArray(data.tags) &&
			isString(data.title) &&
			isString(data.type)
		) {
			this.attributionID = data.attributionID;
			this.author = data.author;
			this.date = data.date;
			this.description = data.description;
			this.duration = data.duration;
			this.search_index = data.search_index;
			this.source_path = data.source_path;
			this.tags = data.tags;
			this.title = data.title;
			this.type = data.type;
		} else {
			log(`Failed to initialize new object: ${JSON.stringify(data)}`);
			throw new Error('Invalid data');
		}
	}
}

export class Author {
	id: string;
	name: string;
	profile_picture_filename: string;
	profile_picture_url?: string;

	constructor(data: FirebaseFirestore.DocumentData) {
		if (
			isString(data.id) &&
			isString(data.name) &&
			isString(data.profile_picture_filename) &&
			(isString(data.profile_picture_url) ||
				data.profile_picture_url === undefined)
		) {
			this.id = data.id;
			this.name = data.name;
			this.profile_picture_filename = data.profile_picture_filename;
			this.profile_picture_url = data.profile_picture_url;
		} else {
			log(`Failed to initialize new object: ${JSON.stringify(data)}`);
			throw new Error('Invalid data');
		}
	}
}
