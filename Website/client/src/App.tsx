import { useCallback, useEffect, useState } from 'react';
import {
	AppBar,
	CssBaseline,
	Toolbar,
	Typography,
	Box,
	createTheme,
	ThemeProvider,
	IconButton,
	useMediaQuery,
} from '@mui/material';
// import { Box } from '@mui/system';
import NavDrawer from './components/NavDrawer';
import { NavLabel } from './nav';
import BodyView from './components/BodyView';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './Firebase/firebase';
import { AuthContext } from './authContext';
import { Refresh } from '@mui/icons-material';
import { loadData } from './utils';
import { useAppDataStore } from './state';

const lightTheme = createTheme({
	palette: {
		mode: 'light',
	},
});
// Make a copy of the light theme and change it to dark
const darkTheme = createTheme({
	palette: {
		mode: 'dark',
	},
});

function App() {
	const [activeTab, setActiveTab] = useState('Shiurim' as NavLabel);
	const [user, setUser] = useState(auth.currentUser);
	const [loading, setIsLoading, setState] = useAppDataStore((state) => [
		state.loading,
		state.setLoading,
		state.setState,
	]);
	const [isLightTheme, setIsLightTheme] = useState(
		useMediaQuery('(prefers-color-scheme: light)')
	);
	const themeListener = useCallback(
		({ matches }: { matches: boolean }) => {
			if (matches) {
				if (isLightTheme) setIsLightTheme(false);
			} else {
				if (!isLightTheme) setIsLightTheme(true);
			}
		},
		[isLightTheme]
	);
	// const loadContent = useAppDataStore((state) => state.load.shiurim);
	// We need to make sure onAuthStateChanged is only called once
	// so we use React.useEffect to make sure it's only called once
	useEffect(() => {
		onAuthStateChanged(auth, (user) => {
			if (user) {
				auth.updateCurrentUser(user);
				setIsLoading(true);
				setUser(user);
				loadData(user)
					.then(setState)
					.finally(() => setIsLoading(false));
			} else {
				auth.signOut();
				setUser(user);
			}
		});
	}, [auth]);
	useEffect(() => {
		window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', themeListener);
		return () => {
			window
				.matchMedia('(prefers-color-scheme: dark)')
				.removeEventListener('change', themeListener);
		};
	}, []);
	return (
		<ThemeProvider theme={isLightTheme ? lightTheme : darkTheme}>
			<Box sx={{ display: 'flex' }}>
				<CssBaseline />
				<AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
					<Toolbar>
						<Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
							{activeTab}
						</Typography>
						<IconButton
							onClick={() => {
								setIsLoading(true);
								loadData(user)
									.then(setState)
									.finally(() => setIsLoading(false));
							}}
							sx={{ color: 'white' }}
						>
							<Refresh />
						</IconButton>
					</Toolbar>
				</AppBar>
				<AuthContext.Provider value={user}>
					<NavDrawer activeTab={activeTab} setActiveTab={setActiveTab} />
					<BodyView activeTab={activeTab} />
				</AuthContext.Provider>
			</Box>
		</ThemeProvider>
	);
}

export default App;
