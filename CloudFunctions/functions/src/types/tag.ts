// Client
export type TagClient = {
	id: string;
	name: string;
	displayName: string;
	isParent: boolean;
	parentID?: string;
	subCategories?: TagClient[];
};

// Firebase
export type TagFirebase = {
	name: string;
	displayName: string;
	parentID?: string;
	isParent?: boolean;
	subCategories?: string[];
};
