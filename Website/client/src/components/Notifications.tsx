import {
	Alert,
	Box,
	Button,
	Checkbox,
	Collapse,
	Divider,
	FormControlLabel,
	Stack,
	TextField,
	Tooltip,
	Typography,
} from '@mui/material';
import { Nullable, sendNotification } from '../utils';
import { useState } from 'react';
import { NotificationAdd, NotificationImportant, Warning } from '@mui/icons-material';

export default function NotificationsManager() {
	const [formState, setFormState] = useState<Nullable<{ title: string; body: string }>>({
		title: null,
		body: null,
	});
	const [isTest, setIsTest] = useState<boolean>(true);
	const [alertState, setAlertState] = useState<{ status: 'error' | 'info'; visible: boolean }>({
		status: 'info',
		visible: false,
	});
	return (
		<Box width="100%" height="100%" display="flex" justifyContent="center">
			<Stack
				direction="column"
				marginTop={3}
				justifySelf="center"
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
						disabled={alertState.status === 'error'}
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
						disabled={alertState.status === 'error'}
						onChange={(e) =>
							setFormState({ ...formState, body: e.target.value.trimStart() })
						}
						value={formState.body}
					/>

					<Stack direction="row" width="100%" spacing={2}>
						<Tooltip title="Send a notification to yourself to test the notification system. This will only be delivered to devices with developer mode enabled.">
							<FormControlLabel
								control={
									<Checkbox
										checked={isTest}
										onChange={() => setIsTest(!isTest)}
										disabled={alertState.status === 'error'}
									/>
								}
								label="Test Notification"
								// sx={{ marginRight: 'auto!important' }}
							/>
						</Tooltip>
						<Button
							variant="contained"
							color={isTest ? 'primary' : 'warning'}
							fullWidth
							startIcon={isTest ? <NotificationAdd /> : <NotificationImportant />}
							disabled={
								formState.title === null ||
								formState.title.trim() === '' ||
								formState.body === null ||
								formState.body.trim() === ''
								// ||
								// alertState.status === 'error'
							}
							onClick={() => {
								if (formState.title === null || formState.body === null) return;
								if (!isTest) {
									const affirmation = window.confirm(
										'Are you sure you want to send this notification?\nEveryone with notifications enabled will receive this.\n\nThis cannot be undone.'
									);
									if (!affirmation) return;
								}
								sendNotification({
									title: formState.title.trim(),
									body: formState.body.trim(),
									topic: isTest ? 'debug' : 'all',
								})
									.then(() => {
										setAlertState({ status: 'info', visible: true });
									})
									.catch(() => {
										setAlertState({ status: 'error', visible: true });
									});
								// .finally(() => setFormState({ title: null, body: null }));
							}}
						>
							{isTest
								? 'Send Test Notification to developers'
								: 'Send Notification to All Users'}
						</Button>
					</Stack>
					<Collapse in={alertState.visible} sx={{ width: '100%' }}>
						<Alert
							severity={alertState.status}
							onClose={
								alertState.status === 'error'
									? undefined
									: () => setAlertState({ ...alertState, visible: false })
							}
						>
							{alertState.status === 'info' ? 'Notification sent!' : null}
							{alertState.status === 'error'
								? 'Notification failed to send. Do not retry. Contact the developer.'
								: null}
						</Alert>
					</Collapse>
				</Stack>
			</Stack>
		</Box>
	);
}
