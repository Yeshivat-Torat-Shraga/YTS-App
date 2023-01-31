import { Timestamp } from '@firebase/firestore';

type TagData = {
	id: string;
	displayName: string;
	name: string;
};

type Shiur = {
	attributionID: string;
	author: string;
	date: Timestamp;
	description: String;
	duration: number;
	id: string;
	pending: boolean;
	search_index: string[];
	source_path: string;
	tagData: TagData;
	title: string;
	type: string;
};

export default Shiur;
