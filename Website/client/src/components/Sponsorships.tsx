import {
	Stack,
	Typography,
	Button,
	TableContainer,
	Paper,
	Table,
	TableHead,
	TableRow,
	TableCell,
	TableBody,
	TablePagination,
	Box,
} from '@mui/material';
import { useAppDataStore } from '../state';
import { Sponsorship, SponsorshipStatus } from '../types/sponsorship';
import { getSponsorshipStatus } from '../utils';
import _ from 'lodash';
import { useState } from 'react';

export default function SponsorshipPage() {
	const sponsors = useAppDataStore((state) => _.values(state.sponsors.sponsors));
	const [isShowingAddSponsor, setIsShowingAddSponsor] = useState(false);
	return (
		<Stack
			direction="column"
			id="Sponsorships"
			justifyContent="center"
			alignItems="center"
			width="100%"
			spacing={2}
		>
			<Typography variant="h4">Sponsorship</Typography>
			<Typography variant="body1">Set the app sponsor.</Typography>

			<SponsorTable sponsorships={sponsors} />
			<Button
				variant="contained"
				color="primary"
				fullWidth
				onClick={() => setIsShowingAddSponsor(true)}
			>
				Add Sponsor
			</Button>
		</Stack>
	);
}

export function SponsorTable({ sponsorships }: { sponsorships: Sponsorship[] }) {
	const deleteSponsor = useAppDataStore((state) => state.sponsors.deleteSponsor);
	const [page, setPage] = useState(0);
	const [rowsPerPage, setRowsPerPage] = useState(5);

	return (
		<Box>
			<TableContainer component={Paper}>
				<Table aria-label="simple table">
					<TableHead>
						<TableRow>
							<TableCell>Status</TableCell>
							<TableCell>NAME</TableCell>
							<TableCell align="left">Title</TableCell>
							<TableCell align="left">Dedication</TableCell>
							<TableCell align="left">Start</TableCell>
							<TableCell align="left">End</TableCell>
							<TableCell align="left">Delete</TableCell>
						</TableRow>
					</TableHead>
					<TableBody>
						{sponsorships
							.sort((lhs, rhs) => lhs.dateBegin.seconds - rhs.dateBegin.seconds)
							.reverse()
							.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
							.map((sponsor, idx) => {
								const status = getSponsorshipStatus(sponsor);
								return (
									<TableRow
										selected={status === SponsorshipStatus.ACTIVE}
										key={idx}
										sx={{
											'&:last-child td, &:last-child th': { border: 0 },
										}}
									>
										<TableCell component="th" scope="row">
											{status === SponsorshipStatus.ACTIVE
												? 'Active'
												: status === SponsorshipStatus.INACTIVE
												? 'Inactive'
												: 'Expired'}
										</TableCell>
										<TableCell component="th" scope="row">
											{sponsor.name}
										</TableCell>
										<TableCell align="left">{sponsor.title}</TableCell>
										<TableCell align="left">{sponsor.dedication}</TableCell>
										<TableCell
											align="left"
											sx={{
												fontWeight: 'bold',
											}}
										>
											{new Date(
												sponsor.dateBegin.seconds * 1000
											).toLocaleDateString()}
										</TableCell>
										<TableCell align="left">
											{new Date(
												sponsor.dateEnd.seconds * 1000
											).toLocaleDateString()}
										</TableCell>
										<TableCell align="left">
											<Button
												variant="outlined"
												color="error"
												disabled={sponsor.isBlockedFromDeletion}
												onClick={() => {
													const affirmation = window.confirm(
														'Are you sure you want to delete this sponsorship?\n\nThis cannot be undone.'
													);
													if (!affirmation) return;
													deleteSponsor(sponsor);
												}}
											>
												Delete
											</Button>
										</TableCell>
									</TableRow>
								);
							})}
					</TableBody>
				</Table>
				<TablePagination
					rowsPerPageOptions={[5, 10, 25, { label: 'All', value: sponsorships.length }]}
					component="div"
					count={sponsorships.length}
					rowsPerPage={rowsPerPage}
					page={page}
					onPageChange={(_e: unknown, newPage: number) => {
						setPage(newPage);
					}}
					onRowsPerPageChange={(event: React.ChangeEvent<HTMLInputElement>) => {
						setRowsPerPage(+event.target.value);
						setPage(0);
					}}
				/>
			</TableContainer>
		</Box>
	);
}
