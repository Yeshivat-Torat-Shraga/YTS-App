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
	useTheme,
	Stack,
} from '@mui/material';
import { NavLabel, navLabels } from '../nav';
import { useContext } from 'react';
import { AuthContext } from '../authContext';
import { auth } from '../Firebase/firebase';
import { useAppDataStore } from '../state';

const drawerWidth = 240;

export default function NavDrawer({
	activeTab,
	setActiveTab,
}: {
	activeTab: NavLabel;
	setActiveTab: (navLabel: NavLabel) => void;
}) {
	const user = useContext(AuthContext);
	const theme = useTheme();
	const pendingReview = useAppDataStore((state) =>
		_.filter(state.shiur.shiurim, (shiur) => shiur.pending)
	).length;
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
										sx={{ width: '100%' }}
										selected={activeTab === label}
										onClick={() => {
											setActiveTab(label);
										}}
									>
										<Stack
											direction="row"
											spacing={2}
											justifyContent="space-between"
											width="100%"
										>
											<ListItemText primary={label} />
											{label === 'Pending Review' && pendingReview > 0 && (
												<div
													style={{
														borderRadius: 10,
														border:
															'1px solid' +
															theme.palette.warning.main,
														// textTransform: 'none',
														color: theme.palette.warning.dark,
														paddingTop: 2,
														paddingBottom: 2,
														paddingLeft: 7,
														paddingRight: 7,
														fontWeight: 'bold',
														// center the text
														display: 'flex',
														justifyContent: 'center',
														alignItems: 'center',
													}}
													color="warning"
													// endIcon={}
												>
													{pendingReview}
												</div>
											)}
										</Stack>
										{/* Trailing badge */}
									</ListItemButton>
								</ListItem>
							);
					}
				})}
			</List>
		</Drawer>
	);
}
