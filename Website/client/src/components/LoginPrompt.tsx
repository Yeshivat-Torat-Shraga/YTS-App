import { useState } from 'react';
import { signInWithEmailAndPassword, browserLocalPersistence, UserCredential } from 'firebase/auth';
import { Button, Paper, Stack, TextField, Typography } from '@mui/material';
import { auth } from '../Firebase/firebase';
import { useAppDataStore } from '../state';
import { validateProfile } from '../utils';

export default function LoginPrompt() {
	const [username, setUsername] = useState('');
	const [password, setPassword] = useState('');
	const [errorMessage, setError] = useState<string | null>(null);
	const [userProfile, setUserProfile] = useAppDataStore((state) => [
		state.userProfile,
		state.setUserProfile,
	]);
	return (
		<Paper sx={{ padding: 0, width: 500 }} elevation={1}>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					// Clear the error message
					setError(null);

					login(username, password, setError)
						.then(validateProfile)
						.then(setUserProfile)
						.catch(() => {
							setError("You don't have permission to access the control panel.");
						})
						.finally(() => {
							// clear the password field
							setPassword('');
						});
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
						placeholder="Username"
					/>
					<span style={{ height: 15 }} />
					<TextField
						label="Password"
						type="password"
						variant="outlined"
						fullWidth
						placeholder="Password"
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
						{userProfile ? 'Log Out' : 'Sign In'}
					</Button>
				</Stack>
			</form>
		</Paper>
	);
}

async function login(
	username: string,
	password: string,
	setError: React.Dispatch<React.SetStateAction<string | null>>
): Promise<UserCredential['user']> {
	if (auth.currentUser) {
		await auth.signOut();
	}
	if (username !== '' && password !== '') {
		return auth
			.setPersistence(browserLocalPersistence)
			.then(() => signInWithEmailAndPassword(auth, username, password))
			.then((cred) => {
				setError(null);
				return cred.user;
			})
			.catch((_error) => {
				setError('Please check your username and password and try again.');
				return Promise.reject(null);
			});
	} else {
		setError('Username and password are both required, silly!');
		return Promise.reject(null);
	}
}
