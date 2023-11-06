import { Button, Divider, Stack, TextField, Typography } from '@mui/material';
import { Nullable, sendNotification } from '../utils';
import { useState } from 'react';

export default function NotificationsManager() {
	const [formState, setFormState] = useState<Nullable<{ title: string; body: string }>>({
		title: null,
		body: null,
	});
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
					<TextField
						variant="outlined"
						label="Title"
						fullWidth
						required
						onChange={(e) =>
							setFormState({ ...formState, title: e.target.value.trimStart() })
						}
						value={formState.title}
					/>
					<TextField
						variant="outlined"
						label="Message"
						fullWidth
						required
						onChange={(e) =>
							setFormState({ ...formState, body: e.target.value.trimStart() })
						}
						value={formState.body}
					/>
					<Button
						variant="contained"
						color="primary"
						fullWidth
						disabled={
							formState.title === null ||
							formState.title.trim() === '' ||
							formState.body === null ||
							formState.body.trim() === ''
						}
						onClick={() => {
							if (formState.title === null || formState.body === null) return;
							const affirmation = window.confirm(
								'Are you sure you want to send this notification?\nEveryone with notifications enabled will receive this.\n\nThis cannot be undone.'
							);
							if (!affirmation) return;
							sendNotification({
								title: formState.title.trim(),
								body: formState.body.trim(),
								topic: 'debug',
							});
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
