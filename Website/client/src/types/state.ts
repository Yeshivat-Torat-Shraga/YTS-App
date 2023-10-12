import Article from './article';
import { Rabbi } from './rabbi';
import { Shiur, TagData } from './shiur';

export interface AppData {
	shiur: {
		shiurim: { [id: string]: Shiur };
		setShiurim: (shiurim: { [id: string]: Shiur }) => void;
		updateShiur: (shiur: Shiur) => void;
		deleteShiur: (shiur: Shiur) => void;
		clearShiurim: () => void;
	};
	rabbi: {
		rebbeim: { [id: string]: Rabbi };
		setRebbeim: (rebbeim: { [id: string]: Rabbi }) => void;
		updateRebbe: (rebbe: Rabbi) => void;
		deleteRebbe: (rebbe: Rabbi) => void;
		clearRebbeim: () => void;
	};
	news: {
		articles: { [id: string]: Article };
		setArticles: (articles: { [id: string]: Article }) => void;
		updateArticle: (article: Article) => void;
		deleteArticle: (article: Article) => void;
		clearArticles: () => void;
	};
	tags: {
		tags: { [id: string]: TagData };
		setTags: (tags: { [id: string]: TagData }) => void;
	};
}
