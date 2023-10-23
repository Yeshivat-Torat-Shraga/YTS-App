export const navLabels = [
	'Authentication',
	'-----',
	'Shiurim',
	'Pending Review',
	'Rebbeim',
	'News',
	'Slideshow',
	'Notifications and Sponsorships',
] as const;

export type NavLabel = (typeof navLabels)[number];
