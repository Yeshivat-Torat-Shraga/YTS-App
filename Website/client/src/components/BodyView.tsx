import { Backdrop, Box, LinearProgress, Toolbar, Typography } from '@mui/material';
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
import NotificationsManager from './Notifications';
import SponsorshipPage from './Sponsorships';
import SlideshowPage from './SlideshowPage';
import { useAppDataStore } from '../state';

const navComponents = {
	Authentication: Box,
	'-----': Box,
	Shiurim: ShiurimMain,
	'Pending Review': PendingShiurim,
	Rebbeim: AllRebbeim,
	News: NewsMain,
	Slideshow: SlideshowPage,
	Notifications: NotificationsManager,
	Sponsorships: SponsorshipPage,
};

export default function BodyView({ activeTab }: { activeTab: NavLabel }) {
	const ActiveComponent = navComponents[activeTab];
	const user = useContext(AuthContext);
	const isLoading = useAppDataStore((state) => state.loading);
	const blurProps = {
		filter: 'blur(3px)',
		opacity: 0.65,
		overflow: 'hidden',
	};
	return (
		<Box
			sx={{
				flexGrow: 1,
				bgcolor: undefined,
				p: 3,
				height: '100%',
				minHeight: '100%',
				overflow: 'auto',
				display: 'flex',
				flexDirection: 'column',
				...({ user } ? {} : blurProps),
			}}
		>
			<Toolbar />
			{!user && (
				<Typography variant="body1" padding={5}>
					{loremIpsum} {loremIpsum}
				</Typography>
			)}
			{isLoading ? (
				<Stack
					direction="column"
					width="100%"
					alignItems="center"
					height="100%"
					spacing={2}
					justifyContent="center"
				>
					<Typography variant="h4">Loading</Typography>
					<Box sx={{ width: '25%' }}>
						<LinearProgress />
					</Box>
				</Stack>
			) : (
				<ActiveComponent />
			)}
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
