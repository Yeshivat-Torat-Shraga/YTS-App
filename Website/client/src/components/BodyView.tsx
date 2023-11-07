import { Backdrop, Box, Divider, LinearProgress, Toolbar, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import React from 'react';
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
		requiredPermission?: keyof ControlPanelUser['profile']['permissions'];
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
	const user = useAppDataStore((state) => state.userProfile);
	const requiredPermission = navComponents[activeTab].requiredPermission;
	const ActiveComponent = navComponents[activeTab].component;
	const userHasPermission =
		!requiredPermission ||
		(user?.profile.permissions && user.profile.permissions[requiredPermission]);
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
							<Typography variant="h4" color="error.main">
								403
							</Typography>
							<Divider
								orientation="vertical"
								flexItem
								sx={{
									height: '50%',
									alignSelf: 'unset',
									borderWidth: 1,
									borderColor: 'error.main',
								}}
							/>
							<Stack direction="column" spacing={2}>
								<Typography variant="h4" color="error.main">
									You do not have permission to view this page,{' '}
									{user?.profile.username}.
								</Typography>
								<Typography variant="body1" color="error.main">
									If you believe this is an error, please contact your
									administrator.
								</Typography>
								<Typography variant="body2" color="error.main">
									If you are the administrator, contact the developer.
								</Typography>
								<Typography variant="caption" color="error.main">
									If you are the developer, you probably messed up.
								</Typography>
							</Stack>
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
