import { create } from 'zustand';
import Article from './types/article';
import { Rabbi } from './types/rabbi';
import { Shiur } from './types/shiur';
import { AppData } from './types/state';

export const useAppDataStore = create<AppData>()((set) => ({
	shiur: {
		shiurim: [],
		setShiurim: (shiurim: Shiur[]) => {
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim,
				},
			}));
		},
		updateShiur: (shiur: Shiur) =>
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: state.shiur.shiurim.map((s) => (s.id === shiur.id ? shiur : s)),
				},
			})),
		deleteShiur: (shiur: Shiur) =>
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: state.shiur.shiurim.filter((s) => s.id !== shiur.id),
				},
			})),
		clearShiurim: () =>
			set((state) => ({
				shiur: {
					...state.shiur,
					shiurim: [],
				},
			})),
	},
	rabbi: {
		rebbeim: [],
		setRebbeim: (rebbeim: Rabbi[]) => {
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim,
				},
			}));
		},
		updateRebbe: (rebbe: Rabbi) =>
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: state.rabbi.rebbeim.map((r) => (r.id === rebbe.id ? rebbe : r)),
				},
			})),
		deleteRebbe: (rebbe: Rabbi) =>
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: state.rabbi.rebbeim.filter((r) => r.id !== rebbe.id),
				},
			})),
		clearRebbeim: () =>
			set((state) => ({
				rabbi: {
					...state.rabbi,
					rebbeim: [],
				},
			})),
	},
	news: {
		articles: [],
		setArticles: (articles: Article[]) =>
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
					articles: state.news.articles.map((a) => (a.id === article.id ? article : a)),
				},
			})),
		deleteArticle: (article: Article) =>
			set((state) => ({
				news: {
					...state.news,
					articles: state.news.articles.filter((a) => a.id !== article.id),
				},
			})),
		clearArticles: () =>
			set((state) => ({
				news: {
					...state.news,
					articles: [],
				},
			})),
	},
}));
