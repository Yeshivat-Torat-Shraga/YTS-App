import { Timestamp } from 'firebase/firestore';

type Article = {
	id: string;
	author: string;
	date: Timestamp;
	body: string;
	title: string;
	imageURLs: string[];
};

export default Article;
