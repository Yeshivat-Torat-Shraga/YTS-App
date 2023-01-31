import React from 'react';
import { Button, Card, CardContent, Grid, Typography } from '@mui/material';
import Shiur from '../types/shiur';
import { CalendarMonth, Person } from '@mui/icons-material';

export default function ShiurCard({ shiur }: { shiur: Shiur }) {
	return (
		<Grid sx={{ p: 2 }} xs={4} item>
			<Card
				variant="elevation"
				sx={{
					height: '170px',
				}}
			>
				<CardContent>
					<Typography variant="h6" gutterBottom>
						{shiur.title}
					</Typography>
					{/* 
					If we're not taking up all the space, put a spacer here
					so that the buttons are always at the bottom of the card
					 */}
					<Typography variant="body1" gutterBottom color="text.secondary">
						<Person
							sx={{
								// adjust for the fact that this is a body1
								fontSize: '1.4rem',
								verticalAlign: 'text-bottom',
								paddingRight: '2px',
							}}
						/>
						{shiur.author}
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
