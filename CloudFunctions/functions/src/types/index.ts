export type ContentType = 'audio' | 'video';

export type { AlertClient, AlertFirestore } from './alert';
export type {
	ContentClient,
	ContentFirestore,
	UserSubmittedContentClient,
	UserSubmittedContentFirestore,
} from './content';
export type { NewsArticleClient, NewsArticleFirestore } from './news';
export type { Author, RabbiClient, RabbiFirestore } from './rabbi';
export type { SlideshowImageClient, SlideshowImageFirestore } from './slideshow';
export type { TagClient, TagFirebase } from './tag';

export type HTTPFunctionResult<T> = Promise<{
	metadata: {
		lastLoadedDocID: string | null;
		finalCall: boolean;
		error?: string;
	};
	results: T[] | null;
}>;
