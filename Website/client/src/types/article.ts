import { Timestamp } from 'firebase/firestore';

type Article = {
	id: string;
	author: string;
	date: Timestamp;
	body: string;
	title: string;
};

export default Article;
