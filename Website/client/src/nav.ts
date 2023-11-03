export const navLabels = [
	'Authentication',
	'-----',
	'Shiurim',
	'Pending Review',
	'Rebbeim',
	'News',
	'Slideshow',
	'Notifications',
	'Sponsorships',
] as const;

export type NavLabel = (typeof navLabels)[number];
