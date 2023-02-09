import { Timestamp } from '@firebase/firestore';
import { Rabbi } from './rabbi';

type TagData = {
	id: string;
	displayName: string;
	name: string;
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
