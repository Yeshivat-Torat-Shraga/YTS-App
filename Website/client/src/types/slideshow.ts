import { Timestamp } from 'firebase/firestore';

export type Slideshow = {
	id: string;
	url: string;
	title: string | null;
	uploaded: Timestamp;
};

export type RawSlideshow = {
	image_name: string;
	title: string | null;
	uploaded: Timestamp;
};
