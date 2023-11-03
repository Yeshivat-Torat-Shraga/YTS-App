import { Timestamp } from '@firebase/firestore';
export type Sponsorship = {
	id: string;
	title: string;
	name: string;
	dedication: string;
	dateBegin: Timestamp;
	dateEnd: Timestamp;
	isBlockedFromDeletion?: boolean;
};

export enum SponsorshipStatus {
	ACTIVE,
	EXPIRED,
	INACTIVE,
}
