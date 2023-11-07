import { create } from 'zustand';
import Article from './types/article';
import { Rabbi } from './types/rabbi';
import { Shiur, TagData } from './types/shiur';
import { AppData } from './types/state';
import { doc, setDoc, deleteDoc, addDoc, collection, Timestamp } from '@firebase/firestore';
import { auth, firestore, storage } from './Firebase/firebase';
import { shiurToRawShiur } from './types/shiur';
import { UploadResult, deleteObject, ref, uploadBytes } from '@firebase/storage';
import _ from 'lodash';
import { Sponsorship } from './types/sponsorship';
import { RawSlideshow } from './types/slideshow';
export type Optional<T, K extends keyof T> = Pick<Partial<T>, K> & Omit<T, K>;

export const useAppDataStore = create<AppData>()((set) => ({
	setState: (state) => set({ ...state }),
	loading: true,
	setLoading: (loading) => set((state) => ({ ...state, loading })),
	shiurim: {},
	setShiurim: (shiurim: { [id: string]: Shiur }) => {
		set((state) => ({
			shiurim,
		}));
	},
	addShiur(shiur) {
		addDoc(collection(firestore, 'content'), shiurToRawShiur(shiur)).catch(permissionError);
		set((state) => ({
			shiurim: {
				...state.shiurim,
				[shiur.id]: shiur,
			},
		}));
	},
	updateShiur: async (shiur: Shiur) => {
		await setDoc(
			doc(firestore, 'content', shiur.id),
			{
				...shiurToRawShiur(shiur),
			},
			{ merge: true }
		).catch(permissionError);
		set((state) => ({
			shiurim: {
				...state.shiurim,
				[shiur.id]: shiur,
			},
		}));
	},
	deleteShiur: async (shiur: Shiur) => {
		const fileHash = shiur.source_path.split('/')[2];
		await deleteObject(ref(storage, `HLSStreams/${shiur.type}/${fileHash}`)).catch(
			permissionError
		);
		deleteDoc(doc(firestore, 'content', shiur.id)).catch(permissionError);
		set((state) => ({
			shiurim: Object.fromEntries(
				Object.entries(state.shiurim).filter(([id, _]) => id !== shiur.id)
			),
		}));
	},
	clearShiurim: () =>
		set((state) => ({
			shiurim: {},
		})),
	rebbeim: {},
	setRebbeim: (rebbeim: { [id: string]: Rabbi }) => {
		set((state) => ({
			rebbeim,
		}));
	},
	async addRebbi(rebbe) {
		const newDoc = await addDoc(collection(firestore, 'rebbeim'), rebbe).catch(permissionError);
		if (!newDoc) throw new Error('Failed to add new rebbi');
		rebbe.id = newDoc.id;
		set((state) => ({
			rebbeim: {
				...state.rebbeim,
				[newDoc.id]: new Rabbi(
					newDoc.id,
					rebbe.name,
					rebbe.profilePictureURL,
					rebbe.profile_picture_filename,
					rebbe.visible
				),
			},
		}));
	},
	deleteRebbi(rebbe) {
		deleteDoc(doc(firestore, 'rebbeim', rebbe.id)).catch(permissionError);
		set((state) => ({
			rebbeim: Object.fromEntries(
				Object.entries(state.rebbeim).filter(([id, _]) => id !== rebbe.id)
			),
		}));
	},
	updateRebbe: async (rebbe: Rabbi) => {
		await setDoc(
			doc(firestore, 'rebbeim', rebbe.id),
			{
				...rebbe,
			},
			{ merge: true }
		).catch(permissionError);
		set((state) => ({
			rebbeim: {
				...state.rebbeim,
				[rebbe.id]: rebbe,
			},
		}));
	},
	deleteRebbe: async (rebbe: Rabbi) => {
		await deleteObject(ref(storage, `profile-pictures/${rebbe.profilePictureFileName}`));
		await deleteDoc(doc(firestore, 'rebbeim', rebbe.id));
		set((state) => ({
			rebbeim: Object.fromEntries(
				Object.entries(state.rebbeim).filter(([id, _]) => id !== rebbe.id)
			),
		}));
	},
	clearRebbeim: () =>
		set((state) => ({
			rebbeim: {},
		})),
	articles: {},
	setArticles: (articles: { [id: string]: Article }) =>
		set((state) => ({
			articles,
		})),
	updateArticle: async (article: Optional<Article, 'id'>) => {
		if (!article.id) {
			let newDoc = await addDoc(collection(firestore, 'news'), _.omit(article, 'id')).catch(
				permissionError
			);
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
			articles: {
				...state.articles,
				[article.id!]: article as Article,
			},
		}));
	},
	deleteArticle: (article: Article) => {
		deleteDoc(doc(firestore, 'news', article.id)).catch(permissionError);
		set((state) => ({
			articles: Object.fromEntries(
				Object.entries(state.articles).filter(([id, _]) => id !== article.id)
			),
		}));
	},
	clearArticles: () =>
		set((state) => ({
			articles: {},
		})),
	tags: {},
	setTags: (tags: { [id: string]: TagData }) =>
		set((state) => ({
			tags,
		})),
	sponsors: {},
	async addSponsor(sponsor) {
		let newDoc = await addDoc(
			collection(firestore, 'sponsorships'),
			_.omit(sponsor, 'id')
		).catch(permissionError);
		if (!newDoc) throw new Error('Failed to add new sponsorship');
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
			sponsors: Object.fromEntries(
				Object.entries(state.sponsors).filter(([id, _]) => id !== sponsor.id)
			),
		}));
	},

	setSponsors(sponsors: { [id: string]: Sponsorship }) {
		set((state) => ({
			sponsors,
		}));
	},
	slideshow: {},
	async addSlide(slide) {
		const newSlide: RawSlideshow = {
			title: slide.title,
			image_name: slide.image.name,
			uploaded: Timestamp.fromDate(slide.uploaded),
		};
		const results: void | [UploadResult, string?] = await Promise.all([
			uploadBytes(ref(storage, `slideshow/${slide.image.name}`), slide.image),
			addDoc(collection(firestore, 'slideshowImages'), newSlide)
				.catch(permissionError)
				.then((newDoc) => newDoc?.id),
		]).catch(permissionError);
		if (!results) throw new Error('Failed to add new slide');
		const newDocID = results[1];
		if (!newDocID) throw new Error('Failed to add new slide');
		set((state) => ({
			slideshow: {
				...state.slideshow,
				slideshow: {
					...state.slideshow.slideshow,
					[newDocID]: {
						id: newDocID,
						title: slide.title,
						url: URL.createObjectURL(slide.image),
						uploaded: Timestamp.fromDate(slide.uploaded),
					},
				},
			},
		}));
	},
	deleteSlide(slide) {
		deleteDoc(doc(firestore, 'slideshowImages', slide.id)).catch(permissionError);
		set((state) => ({
			slideshow: Object.fromEntries(
				Object.entries(state.slideshow).filter(([id, _]) => id !== slide.id)
			),
		}));
	},
	setSlideshow(slideshow) {
		set((state) => ({
			slideshow,
		}));
	},
}));

function permissionError(err: any) {
	if (err.code === 'permission-denied') {
		console.error(`Request from user ${auth.currentUser?.uid} failed: permission denied`);
	} else throw err;
}
