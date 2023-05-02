import { initializeApp } from 'firebase/app';
import { collection, getDocs, getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { getStorage } from '@firebase/storage';
import firebaseConfig from './config.json';
import { useAppDataStore } from '../state';
import { RawRabbi } from '../types/rabbi';
import { RawShiur } from '../types/shiur';
import Article from '../types/article';
import { processRawRebbeim, processRawShiurim } from '../utils';

export const app = initializeApp(firebaseConfig);
// const analytics = getAnalytics(app);

export const firestore = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);

auth.onAuthStateChanged(async (user) => {
	let state = useAppDataStore.getState();
	if (user) {
		let rawData: {
			rabbi: RawRabbi[];
			shiur: RawShiur[];
			news: Article[];
		} = {
			rabbi: [],
			shiur: [],
			news: [],
		};
		await Promise.all([
			getDocs(collection(firestore, 'rebbeim')).then(async (querySnapshot) => {
				const newRebbeim = querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as RawRabbi[];
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

			getDocs(collection(firestore, 'news')).then(async (querySnapshot) => {
				const newArticles = querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as Article[];
				rawData.news = newArticles;
			}),
		]);
		let processedRebbeim = await processRawRebbeim(rawData.rabbi);
		let processedShiurim = processRawShiurim(rawData.shiur, processedRebbeim);
		let processedArticles = rawData.news;

		state.rabbi.setRebbeim(processedRebbeim);
		state.shiur.setShiurim(processedShiurim);
		state.news.setArticles(processedArticles);
	} else {
		state.shiur.clearShiurim();
		state.rabbi.clearRebbeim();
		state.news.clearArticles();
	}
});