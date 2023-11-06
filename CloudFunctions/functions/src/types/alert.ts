/**
 * The `AlertClient` type represents the Alert that is sent to the client.
 * Active alerts are shown to the user as a UI-blocking alert dialog.
 */
export type AlertClient = {
	/** The ID of the Firestore Document that represents this Alert */
	id: string;
	/** The title of the Alert */
	title: string;
	/** The body of the Alert */
	body: string;
	/** The date that the Alert was issued */
	dateIssued: FirebaseFirestore.Timestamp;
	/** The date that the Alert expires */
	dateExpired: FirebaseFirestore.Timestamp;
};

/**
 * The `AlertFirestore` type represents the Alert that is stored in Firestore.
 * Active alerts are shown to the user as a UI-blocking alert dialog.
 */
export type AlertFirestore = Omit<AlertClient, 'id'>;
