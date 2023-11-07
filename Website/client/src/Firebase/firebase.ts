import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import firebaseConfig from './config.json';
import { getFunctions } from 'firebase/functions';
import { getStorage } from '@firebase/storage';
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
import _ from 'lodash';

export const app = initializeApp(firebaseConfig);
const appCheckToken = process.env.REACT_APP_FIREBASE_APPCHECK_TOKEN;
if (!appCheckToken) {
	throw new Error('Missing firebase app check token');
}
// @ts-expect-error
window.FIREBASE_APPCHECK_DEBUG_TOKEN = process.env.NODE_ENV === 'development';
export const appCheck = initializeAppCheck(app, {
	provider: new ReCaptchaV3Provider(appCheckToken),
	isTokenAutoRefreshEnabled: true,
});

// const analytics = getAnalytics(app);
export const firestore = getFirestore(app);
export const storage = getStorage(app);
export const auth = getAuth(app);
export const functions = getFunctions(app);
