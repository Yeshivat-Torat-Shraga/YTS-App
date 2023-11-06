import { initializeApp } from 'firebase/app';
import { collection, getDocs, getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';
import { getStorage } from '@firebase/storage';
import firebaseConfig from './config.json';
import { useAppDataStore } from '../state';
import { RawRabbi } from '../types/rabbi';
import { RawShiur, TagData } from '../types/shiur';
import Article from '../types/article';
import { processRawRebbeim, processRawShiurim } from '../utils';
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
import _ from 'lodash';
import { Sponsorship } from '../types/sponsorship';

export const app = initializeApp(firebaseConfig);
const appCheckToken = process.env.REACT_APP_FIREBASE_APPCHECK_TOKEN;
if (!appCheckToken) {
	throw new Error('Missing firebase app check token');
}
// @ts-expect-error
window.FIREBASE_APPCHECK_DEBUG_TOKEN = process.env.NODE_ENV === 'development';
export const appCheck = initializeAppCheck(app, {
	provider: new ReCaptchaV3Provider(appCheckToken),
	isTokenAutoRefreshEnabled: true,
});

// const analytics = getAnalytics(app);
export const firestore = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
export const functions = getFunctions(app);
// getToken(appCheck)
// 	.then(() => {
// 		console.log('success');
// 	})
// 	.catch((error) => {
// 		console.log(error.message);
// 	});

auth.onAuthStateChanged(async (user) => {
	let state = useAppDataStore.getState();
	if (user) {
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
		]);
		getDocs(collection(firestore, 'sponsorships')).then(async (querySnapshot) => {
			const newSponsors = querySnapshot.docs.map((doc) => ({
				...doc.data(),
				id: doc.id,
			})) as Sponsorship[];
			state.sponsors.setSponsors(_.keyBy(newSponsors, 'id'));
		});
		let processedRebbeim = await processRawRebbeim(rawData.rabbi);
		let processedShiurim = processRawShiurim(rawData.shiur, processedRebbeim);
		let processedArticles = _.keyBy(rawData.news, 'id');
		let processedTags = _.keyBy(rawData.tags, 'id');

		state.rabbi.setRebbeim(processedRebbeim);
		state.shiur.setShiurim(processedShiurim);
		state.news.setArticles(processedArticles);
		state.tags.setTags(processedTags);
	} else {
		state.shiur.clearShiurim();
		state.rabbi.clearRebbeim();
		state.news.clearArticles();
		state.tags.setTags({});
	}
});
