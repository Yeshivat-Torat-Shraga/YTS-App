/**
 * A `Rabbi` is a person who authors Shiurim
 */
export type RabbiClient = {
	/** The ID of the Firestore Document that represents this Rabbi */
	id: string;
	/** The name of the Rabbi */
	name: string;
	/** The full, publicly accessable URL to the Rabbi's profile picture */
	profile_picture_url: string;
};

/**
 * This is the Firestore Representation of a {@link RabbiClient}
 */
export type RabbiFirestore = {
	/** The name of the Rabbi */
	name: string;
	/** The path to the profile picture, in storage */
	profile_picture_filename: string;
	/** A list of keywords that can be used to search for this Rabbi */
	search_index: string[];
};

// Unknown
export type Author = {
	id: string;
	name: string;
	profile_picture_filename: string;
	profile_picture_url?: string;
};
