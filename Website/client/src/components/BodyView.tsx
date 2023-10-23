import { Backdrop, Box, Toolbar, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import { useContext } from 'react';
import { AuthContext } from '../authContext';
import { loremIpsum } from '../loremipsum';
import { NavLabel } from '../nav';
import LoginPrompt from './LoginPrompt';
import { NewsMain } from './NewsMain';
import PendingShiurim from './PendingShiurim';
import AllRebbeim from './RebbeimMain';
import ShiurimMain from './ShiurimMain';
import NotificationsManager from './NotificationsSponsorships';

const navComponents = {
	Authentication: Box,
	'-----': Box,
	Shiurim: ShiurimMain,
	'Pending Review': PendingShiurim,
	Rebbeim: AllRebbeim,
	News: NewsMain,
	Slideshow: Box,
	'Notifications and Sponsorships': NotificationsManager,
};

export default function BodyView({ activeTab }: { activeTab: NavLabel }) {
	const ActiveComponent = navComponents[activeTab];
	const user = useContext(AuthContext);
	const blurProps = {
		filter: 'blur(3px)',
		opacity: 0.65,
		overflow: 'hidden',
		maxHeight: '100vh',
	};
	return (
		<Box sx={{ width: '100%' }}>
			<Box
				component="main"
				sx={{
					flexGrow: 1,
					bgcolor: 'background.default',
					p: 3,
					...(!user ? blurProps : {}),
				}}
			>
				<Toolbar />
				{!user && (
					<Typography variant="body1" padding={5}>
						{loremIpsum} {loremIpsum}
					</Typography>
				)}
				<ActiveComponent />
			</Box>
			<Backdrop
				open={!user}
				invisible
				sx={{
					opacity: 0,
					// zIndex: (theme) => theme.zIndex.drawer + 1,
				}}
			>
				<Stack direction="column" maxWidth="30vw">
					<LoginPrompt />
				</Stack>
			</Backdrop>
		</Box>
	);
}
