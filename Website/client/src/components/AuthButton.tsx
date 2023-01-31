import React, { useContext, useEffect } from 'react';
import { Auth, signInWithEmailAndPassword, User } from 'firebase/auth';
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
		signInWithEmailAndPassword(auth, 'test@gmail.com', 'testing').catch((error) => {
			console.log(error);
		});
	}
}
