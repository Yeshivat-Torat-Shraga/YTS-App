import { useContext } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { Button } from '@mui/material';
import { AuthContext } from '../authContext';
import { auth, firestore } from '../Firebase/firebase';
import { useAppDataStore } from '../state';
import { collection, getDocs } from 'firebase/firestore';
import Shiur from '../types/shiur';
import { RawRabbi } from '../types/rabbi';
import Article from '../types/article';

export default function AuthButton() {
	const appData = useAppDataStore((state) => state);
	const user = useContext(AuthContext);

	const fetchAppData = async () => {
		if (appData.shiur.shiurim.length === 0)
			await getDocs(collection(firestore, 'content')).then((querySnapshot) => {
				const newShiurim = (
					querySnapshot.docs.map((doc) => ({
						...doc.data(),
						id: doc.id,
					})) as Shiur[]
				)
					.filter((shiur) => shiur.source_path !== undefined)
					.sort((a, b) => b.date.toDate().getTime() - a.date.toDate().getTime());
				appData.shiur.setShiurim(newShiurim);
			});
		if (appData.rabbi.rebbeim.length === 0)
			await getDocs(collection(firestore, 'rebbeim')).then((querySnapshot) => {
				const newRebbeim = querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as RawRabbi[];
				appData.rabbi.setRebbeim(newRebbeim);
			});
		if (appData.news.articles.length === 0)
			await getDocs(collection(firestore, 'news')).then((querySnapshot) => {
				const newArticles = querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as Article[];
				appData.news.setArticles(newArticles);
			});
	};

	const clearAppData = () => {
		appData.shiur.clearShiurim();
		appData.rabbi.clearRebbeim();
		appData.news.clearArticles();
	};
	return (
		<Button
			onClick={() => onAuthButtonClick(fetchAppData, clearAppData)}
			variant="contained"
			fullWidth
		>
			{user ? 'Log Out' : 'Sign In'}
		</Button>
	);
}

function onAuthButtonClick(fetchAppData: () => Promise<void>, clearAppData: () => void) {
	if (auth.currentUser) {
		auth.signOut();
		clearAppData();
	} else {
		if (process.env.NODE_ENV === 'production') {
			// const provider = new auth.GoogleAuthProvider();
			// auth.signInWithPopup(provider);
		} else if (process.env.NODE_ENV === 'development') {
			const email = process.env.REACT_APP_DEV_EMAIL;
			const password = process.env.REACT_APP_DEV_PASSWORD;
			signInWithEmailAndPassword(auth, email!, password!)
				.then(() => {
					fetchAppData();
				})
				.catch((error) => {
					console.log(error);
				});
		}
	}
}
