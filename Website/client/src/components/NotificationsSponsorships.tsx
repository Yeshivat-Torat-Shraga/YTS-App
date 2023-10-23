import { CardGiftcardOutlined, Delete, Folder } from '@mui/icons-material';
import {
	Avatar,
	Box,
	Button,
	Divider,
	IconButton,
	List,
	ListItem,
	ListItemAvatar,
	ListItemButton,
	ListItemText,
	Stack,
	TextField,
	Typography,
	useTheme,
} from '@mui/material';

export default function NotificationsManager() {
	const theme = useTheme();
	return (
		<Stack width="100%" height="100%" justifyContent="center" alignItems="center">
			<Stack
				direction="column"
				justifyContent="space-evenly"
				alignItems="center"
				height="100%"
				width="60%"
				spacing={2.5}
			>
				<Stack
					width="100%"
					direction="column"
					id="Push-Notifications"
					justifyContent="center"
					alignItems="center"
					spacing={2}
				>
					<Typography variant="h4">Push Notifications</Typography>
					<Typography variant="body1">Send a push notification to all users.</Typography>
					<TextField variant="outlined" label="Title" fullWidth required />
					<TextField variant="outlined" label="Message" fullWidth />
					<Button
						variant="contained"
						color="primary"
						fullWidth
						onClick={() => {
							const affirmation = window.confirm(
								'Are you sure you want to send this notification?\nEveryone with notifications enabled will receive this.\n\nThis cannot be undone.'
							);
							if (!affirmation) return;
							alert('Notification sent!');
						}}
					>
						Send
					</Button>
				</Stack>
				<Divider variant="fullWidth" />
				<Stack
					direction="column"
					id="Sponsorships"
					justifyContent="center"
					alignItems="center"
					width="100%"
					spacing={2}
				>
					<Typography variant="h4">Sponsorship</Typography>
					<Typography variant="body1">Set the app sponsor.</Typography>
					<Box
						width="100%"
						display="flex"
						justifyContent="center"
						alignItems="center"
						border={`1px solid ${theme.palette.grey[800]}`}
						borderRadius={1}
					>
						<List
							sx={{
								width: '100%',
								bgcolor: 'background.paper',
								position: 'relative',
								overflow: 'auto',
								maxHeight: '28vh',
								'& ul': { padding: 0 },
							}}
						>
							{[0, 1, 2, 3, 4, 5, 6, 7, 8].map((item) => {
								const isActive = item === 2;
								return (
									<>
										<ListItem
											secondaryAction={
												<IconButton edge="end" aria-label="delete">
													<Delete
														color={isActive ? 'error' : 'inherit'}
													/>
												</IconButton>
											}
										>
											<ListItemAvatar>
												<Avatar
													sx={{
														backgroundColor: isActive
															? 'primary.main'
															: undefined,
													}}
												>
													<CardGiftcardOutlined
													// color={isActive ? 'warning' : 'inherit'}
													/>
												</Avatar>
											</ListItemAvatar>
											<ListItemText
												primary={
													'Single-line item ' +
													item +
													(isActive ? ' (Active)' : '')
												}
											/>
										</ListItem>

										{item !== 8 && <Divider variant="inset" />}
									</>
								);
							})}
						</List>
					</Box>
					<Button variant="contained" color="primary" fullWidth>
						Add Sponsor
					</Button>
				</Stack>
			</Stack>
		</Stack>
	);
}
