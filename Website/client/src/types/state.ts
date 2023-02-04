import Article from './article';
import { Rabbi, RawRabbi } from './rabbi';
import { RawShiur, Shiur } from './shiur';

export interface AppData {
	shiur: {
		shiurim: Shiur[];
		setShiurim: (shiurim: RawShiur[], rabbis: Rabbi[]) => void;
		updateShiur: (shiur: Shiur) => void;
		deleteShiur: (shiur: Shiur) => void;
		clearShiurim: () => void;
	};
	rabbi: {
		rebbeim: Rabbi[];
		setRebbeim: (rebbeim: RawRabbi[]) => void;
		updateRebbe: (rebbe: Rabbi) => void;
		deleteRebbe: (rebbe: Rabbi) => void;
		clearRebbeim: () => void;
	};
	news: {
		articles: Article[];
		setArticles: (articles: Article[]) => void;
		updateArticle: (article: Article) => void;
		deleteArticle: (article: Article) => void;
		clearArticles: () => void;
	};
}
