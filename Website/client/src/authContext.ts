import { createContext } from 'react';
import { auth } from './Firebase/firebase';

export const AuthContext = createContext(auth.currentUser);
