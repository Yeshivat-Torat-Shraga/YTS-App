import { Button, Divider, Stack, TextField, Typography } from '@mui/material';

export default function NotificationsManager() {
	return (
		<Stack width="100%" height="100%" justifyContent="center" alignItems="center">
			<Stack
				direction="column"
				justifyContent="space-evenly"
				alignItems="center"
				height="100%"
				width="66vw"
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
			</Stack>
		</Stack>
	);
}
