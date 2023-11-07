import { useContext, useState, useEffect } from 'react';
import { signInWithEmailAndPassword, browserLocalPersistence, UserCredential } from 'firebase/auth';
import { Button, Paper, Stack, TextField, Typography } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth, firestore } from '../Firebase/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { ControlPanelUser } from '../types/state';
import { useAppDataStore } from '../state';

export default function LoginPrompt() {
	const user = useContext(AuthContext);
	const [username, setUsername] = useState('');
	const [password, setPassword] = useState('');
	const [errorMessage, setError] = useState<string | null>(null);
	const setUser = useAppDataStore((state) => state.setUserProfile);
	return (
		<Paper sx={{ padding: 0, width: 500 }} elevation={1}>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					// Clear the error message
					setError(null);

					login(username, password, setError).then(async (cred) => {
						// Get the user from Firebase to check permissions
						const userProfile = await getDoc(
							doc(firestore, 'administrators', cred.user.uid)
						);
						// If the user is not an admin, log them out
						if (!userProfile.exists()) {
							auth.signOut();
							setError('You are not authorized to access this page.');
						} else {
							const userData = userProfile.data() as ControlPanelUser;
							setUser(userData);
							alert(`Welcome, ${userData.username}!`);
						}
					});
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
						{user ? 'Log Out' : 'Sign In'}
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
): Promise<UserCredential> {
	if (auth.currentUser) {
		await auth.signOut();
	}
	if (username !== '' && password !== '') {
		return auth
			.setPersistence(browserLocalPersistence)
			.then(() => signInWithEmailAndPassword(auth, username, password))
			.then((user) => {
				setError(null);
				return user;
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
