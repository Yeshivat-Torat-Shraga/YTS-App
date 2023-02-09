import { useContext, useState, useEffect } from 'react';
import { signInWithEmailAndPassword, browserLocalPersistence } from 'firebase/auth';
import { Button, Paper, Stack, TextField, Typography } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth } from '../Firebase/firebase';

export default function LoginPrompt() {
	const user = useContext(AuthContext);
	const [username, setUsername] = useState('');
	const [password, setPassword] = useState('');
	const [errorMessage, setError] = useState<string | null>(null);

	return (
		<Paper sx={{ padding: 0, width: 500 }} elevation={1}>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					// Clear the error message
					setError(null);

					login(username, password, setError);
					setPassword('');

					// clear the password field
				}}
			>
				<Stack direction="column" justifyContent="space-evenly" alignItems="center" p={2}>
					<Typography variant="h5" noWrap component="div" fontWeight="bold" p={2}>
						Please Sign In
					</Typography>
					{/* <Stack direction="row" justifyContent="center" alignItems="center">
				</Stack> */}

					<TextField
						label="Username"
						variant="outlined"
						fullWidth
						autoFocus
						error={errorMessage ? true : false}
						onChange={(e) => setUsername(e.target.value)}
						value={username}
						defaultValue={username}
					/>
					<span style={{ height: 15 }} />
					<TextField
						label="Password"
						type="password"
						variant="outlined"
						fullWidth
						defaultValue={password}
						value={password}
						error={errorMessage ? true : false}
						helperText={errorMessage ?? ''}
						// Clear the password field on error
						onChange={(e) => setPassword(e.target.value)}
					/>
					<Button
						variant="contained"
						type="submit"
						fullWidth
						sx={{
							marginTop: 2,
						}}
					>
						{user ? 'Log Out' : 'Sign In'}
					</Button>
				</Stack>
			</form>
		</Paper>
	);
}

function login(
	username: string,
	password: string,
	setError: React.Dispatch<React.SetStateAction<string | null>>
) {
	if (auth.currentUser) {
		auth.signOut();
	} else {
		if (username !== '' && password !== '') {
			auth
				.setPersistence(browserLocalPersistence)
				.then(() => {
					return signInWithEmailAndPassword(auth, username, password);
				})
				.then((_) => {
					setError(null);
					// alert the user that this is a preview and a work in progress
					alert(
						'Welcome to the preview of the new website! This is a work in progress, so please be patient as I work out the design and features.'
					);
				})
				.catch((error) => {
					setError('Please check your username and password and try again.');
				});
		} else {
			setError('Username and password are both required, silly!');
		}
	}
}
