import React, { useEffect, useState } from 'react';
import _ from 'lodash';
import {
	AppBar,
	CssBaseline,
	Toolbar,
	Typography,
	Box,
	createTheme,
	ThemeProvider,
} from '@mui/material';
// import { Box } from '@mui/system';
import NavDrawer from './components/NavDrawer';
import { NavLabel } from './nav';
import BodyView from './components/BodyView';
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from './Firebase/firebase';
import { AuthContext } from './authContext';

const theme = createTheme({
	palette: {
		mode: 'light',
	},
});

function App() {
	const [activeTab, setActiveTab] = useState('Shiurim' as NavLabel);
	const [user, setUser] = React.useState(auth.currentUser);
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
	}, []);

	return (
		<ThemeProvider theme={theme}>
			<Box sx={{ display: 'flex' }}>
				<CssBaseline />
				<AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
					<Toolbar>
						<Typography variant="h6" noWrap component="div">
							{activeTab}
						</Typography>
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
