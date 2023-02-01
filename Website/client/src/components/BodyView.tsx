import { Backdrop, Box, Toolbar, Typography } from '@mui/material';
import { Stack } from '@mui/system';
import { useContext } from 'react';
import { AuthContext } from '../authContext';
import { loremIpsum } from '../loremipsum';
import { NavLabel } from '../nav';
import AuthButton from './AuthButton';
import ShiurimMain from './ShiurimMain';

const navComponents = {
	Authentication: Box,
	'-----': Box,
	Shiurim: ShiurimMain,
	'Pending Review': Box,
	Rebbeim: Box,
	News: Box,
	Slideshow: Box,
	'Notifications and Announcements': Box,
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
		<Box>
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
					<Typography variant="h5" noWrap component="div" fontWeight="bold">
						Please Sign In
					</Typography>
					<AuthButton />
				</Stack>
			</Backdrop>
		</Box>
	);
}
