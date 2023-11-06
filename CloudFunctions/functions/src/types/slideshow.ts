// Client
export type SlideshowImageClient = {
	url: string;
	id: string;
	title: string | null;
	uploaded: FirebaseFirestore.Timestamp;
};

// Firebase
export type SlideshowImageFirestore = {
	image_name: string;
	title: string;
	uploaded: FirebaseFirestore.Timestamp;
};
