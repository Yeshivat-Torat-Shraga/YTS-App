import * as React from 'react';
import _ from 'lodash';
import {
	Drawer,
	Toolbar,
	Divider,
	List,
	ListItem,
	ListItemButton,
	ListItemText,
} from '@mui/material';
import { NavLabel, navLabels } from '../nav';
import AuthButton from './AuthButton';

const drawerWidth = 240;

export default function NavDrawer({
	activeTab,
	setActiveTab,
}: {
	activeTab: NavLabel;
	setActiveTab: (navLabel: NavLabel) => void;
}) {
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
									<AuthButton />
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
