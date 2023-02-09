import _ from 'lodash';
import {
	Drawer,
	Toolbar,
	Divider,
	List,
	ListItem,
	ListItemButton,
	ListItemText,
	Tooltip,
	Button,
} from '@mui/material';
import { NavLabel, navLabels } from '../nav';
import { useContext } from 'react';
import { AuthContext } from '../authContext';
import { auth } from '../Firebase/firebase';

const drawerWidth = 240;

export default function NavDrawer({
	activeTab,
	setActiveTab,
}: {
	activeTab: NavLabel;
	setActiveTab: (navLabel: NavLabel) => void;
}) {
	const user = useContext(AuthContext);
	return (
		<Drawer
			sx={{
				width: drawerWidth,
				flexShrink: 0,
				'& .MuiDrawer-paper': {
					width: drawerWidth,
					boxSizing: 'border-box',
				},
			}}
			variant="permanent"
			anchor="left"
		>
			<Toolbar />
			<Divider />
			<List>
				{_.map(navLabels, (label: NavLabel, index: number) => {
					switch (label) {
						case 'Authentication':
							return (
								<ListItem key={index}>
									<Tooltip title={user ? '' : 'Login to press this button'}>
										<span style={{ width: '100%' }}>
											<Button
												variant="contained"
												disabled={!user}
												fullWidth
												onClick={() => auth.signOut()}
											>
												Logout
											</Button>
										</span>
									</Tooltip>
								</ListItem>
							);
						case '-----':
							return <Divider key={index} />;
						default:
							return (
								<ListItem key={index} disablePadding>
									<ListItemButton
										selected={activeTab === label}
										onClick={() => {
											setActiveTab(label);
										}}
									>
										<ListItemText primary={label} />
									</ListItemButton>
								</ListItem>
							);
					}
				})}
			</List>
		</Drawer>
	);
}
