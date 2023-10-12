export class Rabbi {
	id: string;
	name: string;
	profilePictureURL: string;
	visible: boolean;
	constructor(id: string, name: string, profilePictureURL: string, visible: boolean) {
		this.id = id;
		this.name = name;
		this.profilePictureURL = profilePictureURL;
		this.visible = visible;
	}

	setVisible(visible: boolean) {
		this.visible = visible;
	}
}

export type RawRabbi = {
	id: string;
	name: string;
	visible: boolean;
	profile_picture_filename: string;
};
