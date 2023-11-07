import { Optional } from '../state';
import Article from './article';
import { Rabbi, RawRabbi } from './rabbi';
import { Shiur, TagData } from './shiur';
import { Slideshow } from './slideshow';
import { Sponsorship } from './sponsorship';

export type ControlPanelUser = {
	username: string;
	permissions: {
		pushNotifications: boolean;
		sponsorships: boolean;
		articles: boolean;
		shiurim: boolean;
		rebbeim: boolean;
		slideshow: boolean;
	};
};
export interface AppData {
	setState: (state: Partial<AppData>) => void;
	loading: boolean;
	userProfile: ControlPanelUser | null;
	setUserProfile: (userProfile: ControlPanelUser | null) => void;
	setLoading: (loading: boolean) => void;
	shiurim: { [id: string]: Shiur };
	addShiur: (shiur: Shiur) => void;
	deleteShiur: (shiur: Shiur) => void;
	setShiurim: (shiurim: { [id: string]: Shiur }) => void;
	updateShiur: (shiur: Shiur) => void;
	clearShiurim: () => void;
	rebbeim: { [id: string]: Rabbi };
	addRebbi: (rebbe: Optional<RawRabbi, 'id'>) => void;
	deleteRebbi: (rebbe: Rabbi) => void;
	setRebbeim: (rebbeim: { [id: string]: Rabbi }) => void;
	updateRebbe: (rebbe: Rabbi) => void;
	deleteRebbe: (rebbe: Rabbi) => void;
	clearRebbeim: () => void;
	articles: { [id: string]: Article };
	setArticles: (articles: { [id: string]: Article }) => void;
	updateArticle: (article: Optional<Article, 'id'>) => void;
	deleteArticle: (article: Article) => void;
	clearArticles: () => void;
	tags: { [id: string]: TagData };
	setTags: (tags: { [id: string]: TagData }) => void;
	sponsors: { [id: string]: Sponsorship };
	addSponsor: (sponsor: Optional<Sponsorship, 'id'>) => void;
	deleteSponsor: (sponsor: Sponsorship) => void;
	setSponsors: (sponsors: { [id: string]: Sponsorship }) => void;
	slideshow: { [id: string]: Slideshow };
	addSlide: (slide: { title: string | null; uploaded: Date; image: File }) => void;
	deleteSlide: (slide: Slideshow) => void;
	setSlideshow: (slideshow: { [id: string]: Slideshow }) => void;
}
