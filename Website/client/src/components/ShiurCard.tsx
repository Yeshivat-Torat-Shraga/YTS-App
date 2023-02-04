import { Avatar, Card, CardContent, CardHeader, Grid, Typography } from '@mui/material';
import { Shiur } from '../types/shiur';
import { CalendarMonth, Person } from '@mui/icons-material';
import { useAppDataStore } from '../state';
export default function ShiurCard({ shiur }: { shiur: Shiur }) {
	const data = useAppDataStore.getState();
	if (shiur.date === undefined) {
		console.log(data);
		debugger;
	}
	return (
		<Grid sx={{ p: 2 }} xs={6} item>
			<Card
				variant="elevation"
				sx={{
					height: '170px',
				}}
			>
				<ShiurCardHeader shiur={shiur} />
				<CardContent>
					<Typography variant="h6" gutterBottom>
						{shiur.title}
					</Typography>
					{/* 
					If we're not taking up all the space, put a spacer here
					so that the buttons are always at the bottom of the card
					 */}
					<Typography variant="body1" gutterBottom color="text.secondary">
						<>
							<Person
								sx={{
									// adjust for the fact that this is a body1
									fontSize: '1.4rem',
									verticalAlign: 'text-bottom',
									paddingRight: '2px',
								}}
							/>
							{shiur.author?.name || shiur.authorName}
						</>
					</Typography>
					{/* Date, but nicely formatted */}
					<Typography variant="body2" gutterBottom color="text.secondary">
						<CalendarMonth
							sx={{
								// adjust for the fact that this is a body2
								fontSize: '1.4rem',
								verticalAlign: 'text-bottom',
								paddingRight: '2px',
							}}
						/>
						{shiur.date.toDate().toLocaleDateString()}
					</Typography>
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
			/>
		);
	} else {
		return (
			<CardHeader title={shiur.date.toDate().toLocaleDateString()} subheader={shiur.authorName} />
		);
	}
}
