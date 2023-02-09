import {
	Avatar,
	Card,
	CardContent,
	CardHeader,
	Grid,
	IconButton,
	ListItemIcon,
	ListItemText,
	Menu,
	MenuItem,
	MenuList,
	Paper,
	Typography,
} from '@mui/material';
import { Shiur } from '../types/shiur';
import { AccessTime, MoreVert, Headphones, HeadsetOff, Edit, Delete } from '@mui/icons-material';
import { useAppDataStore } from '../state';
import { useState } from 'react';
export default function ShiurCard({ shiur }: { shiur: Shiur }) {
	const data = useAppDataStore.getState();
	if (shiur.date === undefined) {
		console.log(data);
		debugger;
	}

	const iconStyle = {
		fontSize: '1.4rem',
		verticalAlign: 'text-bottom',
		paddingRight: '2px',
	};

	return (
		<Grid sx={{ p: 2 }} xs={6} item>
			<Card
				variant="elevation"
				sx={{
					height: '200px',
				}}
			>
				<ShiurCardHeader shiur={shiur} />
				<CardContent>
					<Typography variant="h6" gutterBottom noWrap>
						{shiur.title}
					</Typography>
					{/* 
					If we're not taking up all the space, put a spacer here
					so that the buttons are always at the bottom of the card
					 */}
					<Typography variant="body1" gutterBottom color="text.secondary">
						<>
							<AccessTime sx={iconStyle} />
							{new Date(shiur.duration * 1000).toISOString().substring(11, 19).replace(/^00:/, '')}
						</>
					</Typography>
					{shiur.pending ? (
						<>
							<Typography variant="body2" color="error">
								<HeadsetOff sx={iconStyle} />
								Pending
							</Typography>
							{/* <ReactPlayer
								url="https://storage.googleapis.com/yeshivat-torat-shraga.appspot.com/HLSStreams/audio/03042022222053185926/03042022221434815855.m3u8"
								controls
							/> */}
						</>
					) : (
						<Typography variant="body2" gutterBottom color="text.secondary">
							<Headphones sx={iconStyle} />
							{shiur.viewCount ?? 'N/A'}
						</Typography>
					)}
				</CardContent>
			</Card>
		</Grid>
	);
}

function ShiurCardHeader({ shiur }: { shiur: Shiur }) {
	if (shiur.author) {
		return (
			<CardHeader
				avatar={<Avatar aria-label="author" src={shiur.author.profilePictureURL} />}
				title={shiur.author.name}
				subheader={shiur.date.toDate().toLocaleDateString()}
				action={<EditMenu shiur={shiur} />}
			/>
		);
	} else {
		return (
			<CardHeader title={shiur.date.toDate().toLocaleDateString()} subheader={shiur.authorName} />
		);
	}
}

function EditMenu({ shiur }: { shiur: Shiur }) {
	const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
	const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
		setAnchorEl(event.currentTarget);
	};
	const handleClose = () => {
		setAnchorEl(null);
	};
	type menuItem = {
		text: string;
		shortcut: string;
		icon: React.ReactNode;
		onClick: () => void;
	};
	const menuItems: menuItem[] = [
		{
			text: 'Edit',
			shortcut: '⌘E       ',
			icon: <Edit fontSize="small" />,
			onClick: () => {},
		},
		{
			text: 'Delete',
			shortcut: '⌘D',
			icon: <Delete fontSize="small" />,
			onClick: () => {},
		},
	];
	return (
		<MenuList>
			<IconButton onClick={handleClick}>
				<MoreVert />
			</IconButton>
			<Menu
				anchorEl={anchorEl}
				open={Boolean(anchorEl)}
				onClose={handleClose}
				PaperProps={{
					style: {
						width: 175,
						maxWidth: '100%',
					},
				}}
			>
				{menuItems.map((item) => (
					<MenuItem onClick={handleClose}>
						<ListItemIcon>{item.icon}</ListItemIcon>
						<ListItemText>
							<Typography variant="inherit">{item.text}</Typography>
						</ListItemText>
						<Typography variant="inherit" color="text.secondary">
							{item.shortcut}
						</Typography>
					</MenuItem>
				))}
			</Menu>
		</MenuList>
	);
}
