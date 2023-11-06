/**
 * `NewsArticleClient` represents individual news articles that are sent to the client.
 */
export interface NewsArticleClient {
	/** The ID of the Firestore Document that represents this News Article */
	id: string;
	/** The title of the News Article */
	title: string;
	/** The name of the author of the News Article */
	author: string;
	/** The contents of the News Article*/
	body: string;
	/** The date when this article was published */
	uploaded: FirebaseFirestore.Timestamp;
	/**
	 * @alpha
	 * URLs for attached images. This is not fully implemented */
	imageURLs: string[] | null;
}

/**
 * `NewsArticleFirestore` represents news article documents in the firestore
 */
export type NewsArticleFirestore = {
	/** The name of the author of the News Article */
	author: string;
	/** The contents of the News Article*/
	body: string;
	/** The date when this article was published */
	date: FirebaseFirestore.Timestamp;
	/**
	 * @alpha
	 * URLs for attached images. This is not fully implemented
	 */
	imageURLs: string[];
	/** The title of the News Article */
	title: string;
};
