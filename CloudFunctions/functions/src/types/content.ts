import { ContentType } from '.';
import { Author } from './rabbi';

/**
 * The `ContentClient` type represents "Content" that is sent to the client.
 */
export type ContentClient = {
	/** The ID of the Firestore Document that represents this Content */
	id: string;
	/** The hash created from the contents of the file. This is used to validate and name the file */
	fileID: string;
	/** The ID of the Rabbi that gave this Shiur */
	attributionID: string;
	/** The title of the Shiur */
	title: string;
	/** The description of the Shiur. Unfortunatly, this is usually empty */
	description: string;
	/** The duration of the Shiur, in seconds */
	duration: number;
	/** The date that the Shiur was uploaded */
	date: FirebaseFirestore.Timestamp;
	/** The type of the Shiur. */
	type: ContentType;
	/** The fully qualified URL of the Shiur, accessible by anyone */
	source_url: string;
	/** The author of the Shiur */
	author: Author;
	/** The tag of the Shiur */
	tagData: {
		id: string;
		name: string;
		displayName: string;
	};
	/** Whether or not the Shiur is pending approval.
	 * This will only be set to true if the Shiur was uploaded by an app user.
	 */
	pending: boolean;
};

/**
 * The `UserSubmittedContentFirestore` type represents a new "Content" submitted by the user, after it has been sanitized and processed, to be stored in Firestore.
 */
export type UserSubmittedContentFirestore = {
	/** The hash created from the contents of the file. This is used to validate and name the file */
	fileID: string;
	/** The ID of the Rabbi that gave this Shiur */
	attributionID: string;
	/** The title of the Shiur */
	title: string;
	/** The description of the Shiur. Unfortunatly, this is usually empty */
	description: string;
	/** The duration of the Shiur, in seconds */
	duration: number;
	/** The date that the Shiur was submitted */
	date: FirebaseFirestore.Timestamp;
	/** The type of the Shiur. */
	type: ContentType;
	/** The pre-generated location where the content will be stored in storage */
	source_path: string;
	/** The name of the author of the Shiur */
	author: string;
	/** The tag of the Shiur */
	tagData: {
		id: string;
		name: string;
		displayName: string;
	};
	/** Whether or not the Shiur is pending approval.
	 * This will be set to true since the Shiur was uploaded by an app user.
	 */
	pending: true;
	/**
	 * The upload data of the Shiur
	 * This is used to send a private push notification to the user when the Shiur is approved or rejected
	 */
	upload_data: {
		/** The ID of the user that uploaded the Shiur */
		uid: string | null;
		/** The timestamp of when the Shiur was uploaded */
		timestamp: FirebaseFirestore.Timestamp;
	};
};

/**
 * The `ContentFirestore` type represents a "Content" that is stored in Firestore.
 */
export type ContentFirestore = {
	/** The ID of the Rabbi that gave this Shiur */
	attributionID: string;
	/** The name of the Rabbi that gave the Shiur */
	author: string;
	/** The date that the Shiur was uploaded */
	date: FirebaseFirestore.Timestamp;
	/** The description of the Shiur. Unfortunatly, this is usually empty */
	description: string;
	/** The duration of the Shiur, in seconds */
	duration: number;
	/** A list of keywords that can be used to search for this Shiur */
	search_index: string[];
	/** The location of the shiur in storage */
	source_path: string;
	/** The tag of the Shiur */
	tagData: {
		id: string;
		name: string;
		displayName: string;
	};
	/** The title of the Shiur */
	title: string;
	/** The type of the Shiur. */
	type: ContentType;
	/** Whether or not the Shiur is pending approval.
	 * This will only be set to true if the Shiur was uploaded by an app user.
	 */
	pending: boolean;
	/** The number of times a shiur was listened to */
	viewCount?: number;
};

/**
 * The `UserSubmittedContentClient` type represents data that is sent when a user submits a new Shiur.
 */
export type UserSubmittedContentClient = {
	/** The ID of the Rabbi that gave this Shiur */
	attributionID: string;
	/** The title of the Shiur */
	title: string;
	/** The description of the Shiur. Unfortunatly, this is usually empty */
	description: string;
	/** The duration of the Shiur, in seconds */
	duration: number;
	/** The date that the Shiur was submitted */
	date: FirebaseFirestore.Timestamp;
	/** The type of the Shiur. */
	type: ContentType;
	/** The _ID_ of the tag this Shiur is associated with */
	tagID: string;
};
