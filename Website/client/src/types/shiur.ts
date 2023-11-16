import { Timestamp } from '@firebase/firestore';
import { Rabbi } from './rabbi';

export type TagData = {
	id: string;
	displayName: string;
	name: string;
	parentID?: string;
	isParent?: boolean;
	subCategories?: string[];
};

export type RawShiur = {
	attributionID: string;
	author: string;
	date: Timestamp;
	description: string;
	duration: number;
	id: string;
	pending: boolean;
	search_index: string[];
	source_path: string;
	tagData: TagData;
	title: string;
	type: string;
	viewCount?: number;
};

export type Shiur = {
	attributionID: string;
	author?: Rabbi;
	authorName: string;
	date: Timestamp;
	description: string;
	duration: number;
	id: string;
	pending: boolean;
	search_index: string[];
	source_path: string;
	tagData: TagData;
	title: string;
	type: string;
	viewCount?: number;
};

export function shiurToRawShiur(shiur: Omit<Shiur, 'id'>): Omit<RawShiur, 'id'> {
	return {
		attributionID: shiur.attributionID,
		author: shiur.authorName,
		date: shiur.date,
		description: shiur.description,
		duration: shiur.duration,
		pending: shiur.pending,
		search_index: shiur.search_index,
		source_path: shiur.source_path,
		tagData: shiur.tagData,
		title: shiur.title,
		type: shiur.type,
	};
}
