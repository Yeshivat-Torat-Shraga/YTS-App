import { useContext } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { Button } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth } from '../Firebase/firebase';

export default function AuthButton() {
	const user = useContext(AuthContext);
	return (
		<Button onClick={onAuthButtonClick} variant="contained" fullWidth>
			{user ? 'Log Out' : 'Sign In'}
		</Button>
	);
}

function onAuthButtonClick() {
	if (auth.currentUser) {
		auth.signOut();
	} else {
		if (process.env.NODE_ENV === 'production') {
			// const provider = new auth.GoogleAuthProvider();
			// auth.signInWithPopup(provider);
		} else if (process.env.NODE_ENV === 'development') {
			const email = process.env.REACT_APP_DEV_EMAIL;
			const password = process.env.REACT_APP_DEV_PASSWORD;
			signInWithEmailAndPassword(auth, email!, password!).catch((error) => {
				console.log(error);
			});
		}
	}
}
