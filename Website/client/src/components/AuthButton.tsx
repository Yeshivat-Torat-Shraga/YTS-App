import { useContext } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { Button } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth, firestore } from '../Firebase/firebase';
import { useShiurimStore } from '../state';
import { collection, getDocs } from 'firebase/firestore';
import Shiur from '../types/shiur';

export default function AuthButton() {
	const shiurim = useShiurimStore((state) => state.shiurim);
	const setShiurim = useShiurimStore((state) => state.setShiurim);
	const user = useContext(AuthContext);

	const fetchShiurim = async () => {
		if (shiurim.length > 0) return;
		await getDocs(collection(firestore, 'content')).then((querySnapshot) => {
			const newShiurim = (
				querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as Shiur[]
			)
				.filter((shiur) => shiur.source_path !== undefined)
				.sort((a, b) => b.date.toDate().getTime() - a.date.toDate().getTime());
			setShiurim(newShiurim);
		});
	};
	return (
		<Button onClick={() => onAuthButtonClick(fetchShiurim)} variant="contained" fullWidth>
			{user ? 'Log Out' : 'Sign In'}
		</Button>
	);
}

function onAuthButtonClick(fetchShiurim: () => Promise<void>) {
	if (auth.currentUser) {
		auth.signOut();
		// clearShiurim();
	} else {
		if (process.env.NODE_ENV === 'production') {
			// const provider = new auth.GoogleAuthProvider();
			// auth.signInWithPopup(provider);
		} else if (process.env.NODE_ENV === 'development') {
			const email = process.env.REACT_APP_DEV_EMAIL;
			const password = process.env.REACT_APP_DEV_PASSWORD;
			signInWithEmailAndPassword(auth, email!, password!)
				.then(() => {
					fetchShiurim();
				})
				.catch((error) => {
					console.log(error);
				});
		}
	}
}
