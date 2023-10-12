import { useEffect, useState } from 'react';
import {
	AppBar,
	CssBaseline,
	Toolbar,
	Typography,
	Box,
	createTheme,
	ThemeProvider,
	IconButton,
} from '@mui/material';
// import { Box } from '@mui/system';
import NavDrawer from './components/NavDrawer';
import { NavLabel } from './nav';
import BodyView from './components/BodyView';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './Firebase/firebase';
import { AuthContext } from './authContext';
import { Refresh } from '@mui/icons-material';
import { useAppDataStore } from './state';

const theme = createTheme({
	palette: {
		mode: 'light',
	},
});

function App() {
	const [activeTab, setActiveTab] = useState('Shiurim' as NavLabel);
	const [user, setUser] = useState(auth.currentUser);
	// const loadContent = useAppDataStore((state) => state.load.shiurim);
	// We need to make sure onAuthStateChanged is only called once
	// so we use React.useEffect to make sure it's only called once
	useEffect(() => {
		onAuthStateChanged(auth, (user) => {
			if (user) {
				auth.updateCurrentUser(user);
				setUser(user);
			} else {
				auth.signOut();
				setUser(user);
			}
		});
	}, [auth]);
	useEffect(() => {
		window.process = {
			...window.process,
		};
	}, []);
	return (
		<ThemeProvider theme={theme}>
			<Box sx={{ display: 'flex' }}>
				<CssBaseline />
				<AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
					<Toolbar>
						<Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
							{activeTab}
						</Typography>
						<IconButton onClick={() => null} sx={{ color: 'white' }}>
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
