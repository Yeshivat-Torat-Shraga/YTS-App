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
import { Refresh } from '@mui/icons-material';
import { loadData, validateProfile } from './utils';
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
	const [setIsLoading, setState] = useAppDataStore((state) => [state.setLoading, state.setState]);
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
	const setUserProfile = useAppDataStore((state) => state.setUserProfile);
	useEffect(() => {
		onAuthStateChanged(auth, (user) => {
			if (user) {
				auth.updateCurrentUser(user);
				setIsLoading(true);
				validateProfile(user)
					.then(setUserProfile)
					.then(loadData)
					.then(setState)
					.finally(() => setIsLoading(false));
			} else {
				auth.signOut();
				setUserProfile(user);
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
		<Box sx={{ display: 'flex', height: '100%' }}>
			<ThemeProvider theme={isLightTheme ? lightTheme : darkTheme}>
				<CssBaseline />
				<AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
					<Toolbar>
						<Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
							{activeTab}
						</Typography>
						<IconButton
							onClick={() => {
								setIsLoading(true);
								loadData()
									.then(setState)
									.finally(() => setIsLoading(false));
							}}
							sx={{ color: 'white' }}
						>
							<Refresh />
						</IconButton>
					</Toolbar>
				</AppBar>
				<NavDrawer activeTab={activeTab} setActiveTab={setActiveTab} />
				<BodyView activeTab={activeTab} />
			</ThemeProvider>
		</Box>
	);
}

export default App;
