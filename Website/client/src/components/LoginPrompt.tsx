import { useContext, useState } from 'react';
import { signInWithEmailAndPassword, browserLocalPersistence } from 'firebase/auth';
import { Button, Paper, Stack, TextField, Typography } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth } from '../Firebase/firebase';

export default function LoginPrompt() {
	const user = useContext(AuthContext);
	const [username, setUsername] = useState('');
	const [password, setPassword] = useState('');
	const [errorMessage, setError] = useState<string | null>(null);
	// Trigger form submission on enter key
	// useEffect(() => {
	// 	const handleKeyDown = (event: KeyboardEvent) => {
	// 		if (event.key === 'Enter') {
	// 			onLogin(username!, password!);
	// 		}
	// 	};
	// 	document.addEventListener('keydown', handleKeyDown);
	// 	return () => {
	// 		document.removeEventListener('keydown', handleKeyDown);
	// 	};
	// }, [username, password]);

	return (
		<Paper sx={{ padding: 0, width: 500 }} elevation={1}>
			<form onSubmit={(e) => e.preventDefault()}>
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
					/>
					<span style={{ height: 15 }} />
					<TextField
						label="Password"
						type="password"
						variant="outlined"
						fullWidth
						// value={password}
						error={errorMessage ? true : false}
						helperText={errorMessage ?? ''}
						// Clear the password field on error
						onChange={(e) => setPassword(e.target.value)}
					/>
					<Button
						onClick={() => {
							onLogin(username, password, setError);
							setPassword('');
						}}
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

function onLogin(
	username: string,
	password: string,
	setError: React.Dispatch<React.SetStateAction<string | null>>
) {
	if (auth.currentUser) {
		auth.signOut();
	} else {
		// if (process.env.NODE_ENV === 'production') {
		// const provider = new auth.GoogleAuthProvider();
		// auth.signInWithPopup(provider);
		// } else if (process.env.NODE_ENV === 'development') {
		// const email = process.env.REACT_APP_DEV_EMAIL;
		// const password = process.env.REACT_APP_DEV_PASSWORD;
		if (username !== '' && password !== '') {
			// Set login persistence to session
			auth
				.setPersistence(browserLocalPersistence)
				.then(() => {
					return signInWithEmailAndPassword(auth, username, password);
				})
				.then((_) => {
					setError(null);
				})
				.catch((error) => {
					setError('Please check your username and password and try again.');
				});
			// signInWithEmailAndPassword(auth, username, password)
			// 	.then((_) => {
			// 		setError(null);
			// 	})
			// 	.catch((error) => {
			// 		setError('Please check your username and password and try again.');
			// 	});
		} else {
			setError('Username and password are required');
		}
		// }
	}
}
