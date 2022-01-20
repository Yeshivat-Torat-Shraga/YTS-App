export interface LoadData {
	metadata: {
		lastLoadedDocID: string;
		includesLastElement: boolean;
	};
	content: any[] | null;
}

export interface NewsDocument {
	id: string;
	title: string;
	author: string;
	body: string;
	uploaded: Date;
	imageURLs: string[] | null;
}

export interface SlideshowImageDocument {
	url: string;
	id: string;
	title: string | null;
	uploaded: Date;
}

export interface NewsFirebaseDocument {
	author: string;
	body: string;
	date: Date;
	imageURLs: string[];
	title: string;
}

export interface SlideshowImageFirebaseDocument {
	/** The name of the file inside of the cloud storage folder */
	image_name: string;
	title: string;
	uploaded: Date;
}
