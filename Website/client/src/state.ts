import { create } from 'zustand';
import Article from './types/article';
import { Rabbi } from './types/rabbi';
import { Shiur, TagData } from './types/shiur';
import { AppData } from './types/state';
import { doc, setDoc, deleteDoc, addDoc, collection } from '@firebase/firestore';
import { auth, firestore, storage } from './Firebase/firebase';
import { shiurToRawShiur } from './types/shiur';
import { deleteObject, ref } from '@firebase/storage';
import _ from 'lodash';
import { Sponsorship } from './types/sponsorship';
export type Optional<T, K extends keyof T> = Pick<Partial<T>, K> & Omit<T, K>;

export const useAppDataStore = create<AppData>()((set) => ({
	shiur: {
		shiurim: {},
		setShiurim: (shiurim: { [id: string]: Shiur }) => {
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim,
				},
			}));
		},
		addShiur(shiur) {
			addDoc(collection(firestore, 'content'), shiurToRawShiur(shiur)).catch(permissionError);
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: {
						...state.shiur.shiurim,
						[shiur.id]: shiur,
					},
				},
			}));
		},
		updateShiur: async (shiur: Shiur) => {
			// First update Firebase
			// Then update state

			await setDoc(
				doc(firestore, 'content', shiur.id),
				{
					...shiurToRawShiur(shiur),
				},
				{ merge: true }
			).catch(permissionError);
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: {
						...state.shiur.shiurim,
						[shiur.id]: shiur,
					},
				},
			}));
		},
		// newShiur: (doc: {
		// 	attributionID: string;
		// 	author: string;
		// 	date: Timestamp;
		// 	description: string;
		// 	duration: number;
		// 	source_path: string;
		// 	tagData: TagData;
		// 	title: string;
		// 	type: 'audio';
		// 	pending: boolean;
		// }) => {
		// 	// const shiur = processRawShiurim([doc], get().rabbi.rebbeim)[0];
		// },
		deleteShiur: async (shiur: Shiur) => {
			// First delete from Firebase
			// Then delete from storage
			// Then delete from state
			const fileHash = shiur.source_path.split('/')[2];
			await deleteObject(ref(storage, `HLSStreams/${shiur.type}/${fileHash}`)).catch(
				permissionError
			);
			deleteDoc(doc(firestore, 'content', shiur.id)).catch(permissionError);
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: Object.fromEntries(
						Object.entries(state.shiur.shiurim).filter(([id, _]) => id !== shiur.id)
					),
				},
			}));
		},
		clearShiurim: () =>
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: {},
				},
			})),
	},
	rabbi: {
		rebbeim: {},
		setRebbeim: (rebbeim: { [id: string]: Rabbi }) => {
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim,
				},
			}));
		},
		async addRebbi(rebbe) {
			const newDoc = await addDoc(collection(firestore, 'rebbeim'), rebbe).catch(
				permissionError
			);
			if (!newDoc) throw new Error('Failed to add new rebbi');
			rebbe.id = newDoc.id;
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: {
						...state.rabbi.rebbeim,
						[newDoc.id]: new Rabbi(
							newDoc.id,
							rebbe.name,
							rebbe.profilePictureURL,
							rebbe.profile_picture_filename,
							rebbe.visible
						),
					},
				},
			}));
		},
		deleteRebbi(rebbe) {
			deleteDoc(doc(firestore, 'rebbeim', rebbe.id)).catch(permissionError);
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: Object.fromEntries(
						Object.entries(state.rabbi.rebbeim).filter(([id, _]) => id !== rebbe.id)
					),
				},
			}));
		},
		updateRebbe: async (rebbe: Rabbi) => {
			// First update Firebase
			// Then update state

			await setDoc(
				doc(firestore, 'rebbeim', rebbe.id),
				{
					...rebbe,
				},
				{ merge: true }
			).catch(permissionError);
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: {
						...state.rabbi.rebbeim,
						[rebbe.id]: rebbe,
					},
				},
			}));
		},
		deleteRebbe: async (rebbe: Rabbi) => {
			// First remove profile picture from storage
			// Then delete from Firebase
			// Then delete from state
			await deleteObject(ref(storage, `profile-pictures/${rebbe.profilePictureFileName}`));
			await deleteDoc(doc(firestore, 'rebbeim', rebbe.id));
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: Object.fromEntries(
						Object.entries(state.rabbi.rebbeim).filter(([id, _]) => id !== rebbe.id)
					),
				},
			}));
		},
		clearRebbeim: () =>
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: {},
				},
			})),
	},
	news: {
		articles: {},
		setArticles: (articles: { [id: string]: Article }) =>
			set((state) => ({
				news: {
					...state.news,
					articles,
				},
			})),
		updateArticle: async (article: Optional<Article, 'id'>) => {
			// First update Firebase
			// Then update state
			if (!article.id) {
				let newDoc = await addDoc(
					collection(firestore, 'news'),
					_.omit(article, 'id')
				).catch(permissionError);
				if (!newDoc) throw new Error('Failed to add new article');
				article.id = newDoc.id;
			} else {
				await setDoc(
					doc(firestore, 'news', article.id),
					{
						..._.omit(article, 'id'),
					},
					{ merge: true }
				).catch(permissionError);
			}
			set((state) => ({
				news: {
					...state.news,
					articles: {
						...state.news.articles,
						[article.id!]: article as Article,
					},
				},
			}));
		},
		deleteArticle: (article: Article) => {
			deleteDoc(doc(firestore, 'news', article.id)).catch(permissionError);
			set((state) => ({
				news: {
					...state.news,
					articles: Object.fromEntries(
						Object.entries(state.news.articles).filter(([id, _]) => id !== article.id)
					),
				},
			}));
		},
		clearArticles: () =>
			set((state) => ({
				news: {
					...state.news,
					articles: {},
				},
			})),
	},
	tags: {
		tags: {},
		setTags: (tags: { [id: string]: TagData }) =>
			set((state) => ({
				tags: {
					...state.tags,
					tags,
				},
			})),
	},
	sponsors: {
		sponsors: {},
		async addSponsor(sponsor) {
			let newDoc = await addDoc(
				collection(firestore, 'sponsorship'),
				_.omit(sponsor, 'id')
			).catch(permissionError);
			if (!newDoc) throw new Error('Failed to add new article');
			sponsor.id = newDoc.id;
			set((state) => ({
				sponsors: {
					...state.sponsors,
					sponsors: {
						...state.sponsors.sponsors,
						[sponsor.id!]: sponsor as Sponsorship,
					},
				},
			}));
		},
		deleteSponsor(sponsor) {
			deleteDoc(doc(firestore, 'sponsorships', sponsor.id)).catch(permissionError);
			set((state) => ({
				sponsors: {
					...state.sponsors,
					sponsors: Object.fromEntries(
						Object.entries(state.sponsors.sponsors).filter(
							([id, _]) => id !== sponsor.id
						)
					),
				},
			}));
		},

		setSponsors(sponsors: { [id: string]: Sponsorship }) {
			set((state) => ({
				sponsors: {
					...state.sponsors,
					sponsors,
				},
			}));
		},
	},
}));

function permissionError(err: any) {
	if (err.code === 'permission-denied') {
		console.error(`Request from user ${auth.currentUser?.uid} failed: permission denied`);
	} else throw err;
}
