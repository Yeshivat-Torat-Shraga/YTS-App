import { Backdrop, Box, Divider, LinearProgress, Toolbar, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import React, { useContext } from 'react';
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
import { ControlPanelUser } from '../types/state';

const navComponents: {
	[key in NavLabel]: {
		component: React.FC;
		requiredPermission?: keyof ControlPanelUser['permissions'];
	};
} = {
	Authentication: { component: Box },
	'-----': { component: Box },
	Shiurim: { component: ShiurimMain, requiredPermission: 'shiurim' },
	'Pending Review': { component: PendingShiurim, requiredPermission: 'shiurim' },
	Rebbeim: { component: AllRebbeim, requiredPermission: 'rebbeim' },
	News: { component: NewsMain, requiredPermission: 'articles' },
	Slideshow: { component: SlideshowPage, requiredPermission: 'slideshow' },
	Notifications: { component: NotificationsManager, requiredPermission: 'pushNotifications' },
	Sponsorships: { component: SponsorshipPage, requiredPermission: 'sponsorships' },
};

export default function BodyView({ activeTab }: { activeTab: NavLabel }) {
	const userPermissions = useAppDataStore((state) => state.userProfile?.permissions);
	const username = useAppDataStore((state) => state.userProfile?.username);
	const requiredPermission = navComponents[activeTab].requiredPermission;
	const ActiveComponent = navComponents[activeTab].component;
	const userHasPermission =
		!requiredPermission || (userPermissions && userPermissions[requiredPermission]);
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
				<Box width="100%" height="100%">
					{userHasPermission ? (
						<ActiveComponent />
					) : (
						<Stack
							direction="row"
							justifyContent="center"
							alignItems="center"
							height="100%"
							spacing={5}
						>
							<Typography variant="h4">403</Typography>
							<Divider
								orientation="vertical"
								flexItem
								sx={{
									borderWidth: 1,
									borderColor: 'error.main',
								}}
							/>
							<Typography variant="h4">
								You do not have permission to view this page, {username}.
							</Typography>
						</Stack>
					)}
				</Box>
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
