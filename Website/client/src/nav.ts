export const navLabels = [
	'Authentication',
	'-----',
	'Shiurim',
	'Pending Review',
	'Rebbeim',
	'News',
	'Slideshow',
	'Notifications and Announcements',
] as const;

export type NavLabel = typeof navLabels[number];
