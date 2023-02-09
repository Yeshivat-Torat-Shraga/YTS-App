import { Card, CardContent, CardMedia, Grid, Typography } from '@mui/material';
import { Rabbi } from '../types/rabbi';

export function RabbiCard({ rabbi }: { rabbi: Rabbi }) {
	return (
		<Grid item padding={2}>
			<Card key={rabbi.id} sx={{ width: 275 }}>
				<CardMedia
					component="img"
					height="225"
					sx={{ objectFit: 'cover' }}
					// style={{ paddingTop: '56.25%' }}
					image={rabbi.profilePictureURL}
					title={rabbi.name}
				/>
				<CardContent sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
					<Typography variant="h5" component="h2">
						{rabbi.name}
					</Typography>
					<Typography variant="body2" color="text.secondary">
						{rabbi.id}
					</Typography>
				</CardContent>
			</Card>
		</Grid>
	);
}
