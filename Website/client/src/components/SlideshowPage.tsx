import { Paper, Stack, Typography, styled, useTheme } from '@mui/material';
import { Masonry } from '@mui/lab';
import { useAppDataStore } from '../state';
import _ from 'lodash';
import { ReactNode } from 'react';

function Label({ error, children }: { error?: boolean; children: ReactNode }) {
	const theme = useTheme();
	return (
		<Paper
			sx={{
				backgroundColor: theme.palette.mode === 'dark' ? '#1A2027' : '#fff',
				...theme.typography.body2,
				padding: theme.spacing(0.5),
				textAlign: 'center',
				color: theme.palette.text.secondary,
				borderBottomLeftRadius: 0,
				borderBottomRightRadius: 0,
			}}
		>
			<Typography
				variant="body2"
				color={error ? 'error.main' : undefined}
				fontStyle={error ? 'italic' : undefined}
			>
				{children}
			</Typography>
		</Paper>
	);
}

export default function SlideshowPage() {
	const slideshowImages = _.values(useAppDataStore((state) => state.slideshow.slideshow));
	useAppDataStore(console.info);
	return (
		<Stack direction="column" justifyContent="center" alignItems="center" spacing={2}>
			<Typography variant="body1" color="text.secondary">
				This page features many high-resolution images. It may take a while to load.
			</Typography>
			<Masonry columns={3} spacing={2}>
				{slideshowImages.map((item, index) => (
					<div key={index}>
						<Label error={item.title === null}>
							{item.title ?? 'No caption provided'}
						</Label>
						<img
							// srcSet={`${item.img}?w=162&auto=format&dpr=2 2x`}
							src={item.url}
							alt={item.title ?? undefined}
							loading="lazy"
							style={{
								borderBottomLeftRadius: 4,
								borderBottomRightRadius: 4,
								display: 'block',
								width: '100%',
							}}
						/>
					</div>
				))}
			</Masonry>
		</Stack>
	);
}
