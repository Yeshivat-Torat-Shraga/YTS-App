import { create } from 'zustand';
import Article from './types/article';
import { Rabbi } from './types/rabbi';
import { Shiur, TagData } from './types/shiur';
import { AppData } from './types/state';
import { doc, setDoc, deleteDoc } from '@firebase/firestore';
import { firestore, storage } from './Firebase/firebase';
import { shiurToRawShiur } from './types/shiur';
import { deleteObject, ref } from '@firebase/storage';
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
		updateShiur: (shiur: Shiur) => {
			// First update Firebase
			// Then update state

			setDoc(
				doc(firestore, 'content', shiur.id),
				{
					...shiurToRawShiur(shiur),
				},
				{ merge: true }
			);
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
			await deleteObject(ref(storage, `shiurim/${shiur.type}/${fileHash}`));
			deleteDoc(doc(firestore, 'content', shiur.id));
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
		updateRebbe: (rebbe: Rabbi) => {
			// First update Firebase
			// Then update state

			setDoc(
				doc(firestore, 'rebbeim', rebbe.id),
				{
					...rebbe,
				},
				{ merge: true }
			);
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
		deleteRebbe: (rebbe: Rabbi) => {
			// First remove profile picture from storage
			// Then delete from Firebase
			// Then delete from state
			deleteObject(ref(storage, `profile-pictures/${rebbe.profilePictureFileName}`));
			deleteDoc(doc(firestore, 'rebbeim', rebbe.id));
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
		updateArticle: (article: Article) =>
			set((state) => ({
				news: {
					...state.news,
					articles: {
						...state.news.articles,
						[article.id]: article,
					},
				},
			})),
		deleteArticle: (article: Article) =>
			set((state) => ({
				news: {
					...state.news,
					articles: Object.fromEntries(
						Object.entries(state.news.articles).filter(([id, _]) => id !== article.id)
					),
				},
			})),
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
}));
