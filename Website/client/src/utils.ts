import { UploadResult, getDownloadURL, ref, uploadBytes } from '@firebase/storage';
import { auth, firestore, functions, storage } from './Firebase/firebase';
import { Rabbi, RawRabbi } from './types/rabbi';
import { RawShiur, Shiur, TagData, shiurToRawShiur } from './types/shiur';
import _ from 'lodash';
import {
	collection,
	addDoc,
	getDocs,
	doc,
	getDoc,
	DocumentData,
	DocumentReference,
} from 'firebase/firestore';
import { Sponsorship, SponsorshipStatus } from './types/sponsorship';
import { httpsCallable } from 'firebase/functions';
import { User, UserCredential } from 'firebase/auth';
import { useAppDataStore } from './state';
import Article from './types/article';
import { Slideshow } from './types/slideshow';
import { AppData, ControlPanelUser } from './types/state';
window.Buffer = window.Buffer || require('buffer').Buffer; // Required for get-mp3-duration

export type Nullable<T> = {
	[P in keyof T]: T[P] | null;
};

type SendNotificationPayload = {
	title: string;
	body: string;
} & (
	| {
			topic: string;
	  }
	| {
			token: string;
	  }
);

export async function sendNotification({
	title,
	body,
	topic,
}: {
	title: string;
	body: string;
	topic: string;
}) {
	const sendNotification = httpsCallable<SendNotificationPayload, string>(
		functions,
		'pushNotification'
	);
	console.log('sending notification to topic', topic);
	return sendNotification({
		title,
		body,
		topic,
	});
}

export async function processRawRebbeim(rawRebbeim: RawRabbi[]): Promise<{ [id: string]: Rabbi }> {
	return Promise.all(
		rawRebbeim.map(async (rawRabbi) => {
			let rabbi: Rabbi = new Rabbi(
				rawRabbi.id,
				rawRabbi.name,
				'',
				rawRabbi.profile_picture_filename,
				rawRabbi.visible
			);

			rabbi.profilePictureURL = await getDownloadURL(
				ref(storage, `profile-pictures/${rawRabbi.profile_picture_filename}`)
			);
			return rabbi;
		})
	).then((rabbis) => {
		return _.keyBy(rabbis, 'id');
	});
}

export function processRawShiurim(
	rawShiurim: RawShiur[],
	rabbis: { [id: string]: Rabbi }
): { [id: string]: Shiur } {
	return _.keyBy(
		rawShiurim.map((rawShiur) => {
			// let rabbi: Rabbi =
			let shiur: Shiur = {
				...rawShiur,
				author: rabbis[rawShiur.attributionID],
				authorName: rawShiur.author,
			};
			return shiur;
		}),
		'id'
	);
}

export function generateTimeString(seconds: number) {
	let hours = Math.floor(seconds / 3600);
	let minutes = Math.floor((seconds % 3600) / 60);
	let secondsLeft = Math.floor((seconds % 3600) % 60);

	let hoursString = hours > 0 ? hours.toString() + ':' : '';
	let minutesString = minutes.toString().padStart(2, '0') + ':';
	let secondsString = secondsLeft.toString().padStart(2, '0');

	return hoursString + minutesString + secondsString;
}

export async function uploadShiurFile(fullShiur: Omit<Shiur, 'id'>, file: File): Promise<Shiur> {
	let shiurData = shiurToRawShiur(fullShiur);
	// First we need to set the proper firestore document
	// Then we need to upload the file to storage

	// Todo:
	//  1. Duration
	////2. Search indices NOPE
	//  3. Generate filepath via sha256 hash
	//  4. Tag data
	//  5. Attribution ID
	//  6. Attribution Name
	//  7. Date: now
	//  8. Description
	//  9. Title
	// 10. Visibility: true
	// 11. type: audio

	// Submit to firestore
	// Submit to storage

	// A. Submit to firestore
	// 1. Calculate duration
	let ctx = new AudioContext();
	const duration = await ctx
		.decodeAudioData(await file.arrayBuffer())
		.then((decodedData) => Math.ceil(decodedData.duration));

	// 2. Search indices
	// 3. Generate filepath via sha256 hash
	let hash = await crypto.subtle.digest('SHA-256', await file.arrayBuffer());
	let hashArray = Array.from(new Uint8Array(hash));
	const hashHex = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');

	// 4. Tag data
	const tagData = shiurData.tagData;

	// 5. Attribution ID
	const attributionID = shiurData.attributionID;

	// 6. Attribution Name
	const author = shiurData.author;

	// 7. Date
	const date = shiurData.date;

	// 8. Description
	const description = shiurData.description;

	// 9. Title
	const title = shiurData.title;

	// 10. Visibility
	const pending = false;

	// 11. Type
	const type = 'audio';

	// 12. Upload to storage

	// B. Submit to storage
	// 1. Get Bucket

	const storageRef = ref(storage, `content/${hashHex}`);
	if (
		_.some(
			[attributionID, author, date, description, duration, tagData, title, type, pending],
			_.isNil
		)
	) {
		throw new Error('Missing required field');
	}

	return addDoc(collection(firestore, 'content'), {
		attributionID,
		author,
		date,
		description,
		duration,
		source_path: `HLSStreams/audio/${hashHex}/${hashHex}.m3u8`,
		tagData,
		title,
		type,
		pending,
	}).then((docRef) =>
		uploadBytes(storageRef, file).then((__) => {
			return {
				id: docRef.id,
				duration,
				source_path: `HLSStreams/audio/${hashHex}/${hashHex}.m3u8`,
				type,
				attributionID,
				date,
				description,
				title,
				tagData,
				authorName: author,
				pending,
				author: fullShiur.author,
				search_index: [],
			};
		})
	);
}

/**
 * new_content_document = {
            "attributionID": attributionID,
            "author": author,
            "date": date,
            "description": description,
            "duration": duration,
            "source_path": source_path,
            "tagData": tag_data,
            "title": title,
            "type": content_type,
            "pending": False
        }
 */

export async function uploadNewRebbi(
	name: string,
	profilePic: File
): Promise<Omit<RawRabbi, 'id'>> {
	// First upload file to storage
	// Then upload document to firestore
	const storageRef = ref(storage, `profile-pictures/${profilePic.name}`);
	await uploadBytes(storageRef, profilePic);
	const profilePictureURL = await getDownloadURL(
		ref(storage, `profile-pictures/${profilePic.name}`)
	);

	return {
		name,
		profile_picture_filename: profilePic.name,
		profilePictureURL,
		visible: true,
	};
}

export function getSponsorshipStatus(sponsorship: Sponsorship): SponsorshipStatus {
	const isBefore = sponsorship.dateBegin.toDate().getTime() > Date.now();
	const isAfter = sponsorship.dateEnd.toDate().getTime() < Date.now();
	if (isBefore) {
		return SponsorshipStatus.INACTIVE;
	} else if (isAfter) {
		return SponsorshipStatus.EXPIRED;
	} else {
		return SponsorshipStatus.ACTIVE;
	}
}

export async function validateProfile(user: UserCredential['user']) {
	// Get the user from Firebase to check permissions
	const userProfile = await getDoc(doc(firestore, 'administrators', user.uid));
	// If the user is not an admin, log them out
	if (!userProfile.exists()) {
		auth.signOut();
		return Promise.reject('You are not authorized to access this page.');
	} else {
		const userData = userProfile.data() as ControlPanelUser['profile'];
		return {
			cred: user,
			profile: userData,
		};
	}
}

export async function loadData(): Promise<Partial<AppData>> {
	const data: {
		shiurim: AppData['shiurim'];
		rebbeim: AppData['rebbeim'];
		articles: AppData['articles'];
		tags: AppData['tags'];
		sponsors: AppData['sponsors'];
		slideshow: AppData['slideshow'];
	} = {
		shiurim: {},
		rebbeim: {},
		articles: {},
		tags: {},
		sponsors: {},
		slideshow: {},
	};

	let rawData: {
		rabbi: RawRabbi[];
		shiur: RawShiur[];
		tags: TagData[];
		news: Article[];
	} = {
		rabbi: [],
		shiur: [],
		tags: [],
		news: [],
	};
	await Promise.all([
		getDocs(collection(firestore, 'rebbeim')).then(async (querySnapshot) => {
			const newRebbeim = querySnapshot.docs.map((doc) => {
				return {
					...doc.data(),
					id: doc.id,
				};
			}) as RawRabbi[];
			rawData.rabbi = newRebbeim;
		}),
		getDocs(collection(firestore, 'content')).then(async (querySnapshot) => {
			const newShiurim = (
				querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as RawShiur[]
			)
				.filter((shiur) => shiur.source_path !== undefined)
				.sort((a, b) => b.date.toDate().getTime() - a.date.toDate().getTime());
			rawData.shiur = newShiurim;
		}),
		getDocs(collection(firestore, 'tags')).then(async (querySnapshot) => {
			const newTags = querySnapshot.docs.map((doc) => ({
				...doc.data(),
				id: doc.id,
			})) as TagData[];
			rawData.tags = newTags;
		}),
		getDocs(collection(firestore, 'news')).then(async (querySnapshot) => {
			const newArticles = querySnapshot.docs.map((doc) => ({
				...doc.data(),
				id: doc.id,
			})) as Article[];
			rawData.news = newArticles;
		}),
		getDocs(collection(firestore, 'sponsorships')).then(async (querySnapshot) => {
			const newSponsors = querySnapshot.docs.map((doc) => ({
				...doc.data(),
				id: doc.id,
			})) as Sponsorship[];
			data.sponsors = _.keyBy(newSponsors, 'id');
		}),
		getDocs(collection(firestore, 'slideshowImages')).then(async (querySnapshot) => {
			const newSlides = await Promise.all(
				querySnapshot.docs.map(async (doc) => {
					const data = doc.data();
					const url = await getDownloadURL(ref(storage, `slideshow/${data.image_name}`));
					const slideshow: Slideshow = {
						title: data.title,
						id: doc.id,
						url,
						uploaded: data.uploaded,
					};
					return slideshow;
				})
			);
			data.slideshow = _.keyBy(newSlides, 'id');
		}),
	]);
	let processedRebbeim = await processRawRebbeim(rawData.rabbi);
	let processedShiurim = processRawShiurim(rawData.shiur, processedRebbeim);
	let processedArticles = _.keyBy(rawData.news, 'id');
	let processedTags = _.keyBy(rawData.tags, 'id');

	data.rebbeim = processedRebbeim;
	data.shiurim = processedShiurim;
	data.articles = processedArticles;
	data.tags = processedTags;

	const returnData: Partial<AppData> = {
		...data,
		loading: false,
	};
	return returnData;
}
