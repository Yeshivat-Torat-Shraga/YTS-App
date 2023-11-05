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
	Modal,
	Card,
	CardHeader,
	CardContent,
	TextField,
} from '@mui/material';
import { Optional, useAppDataStore } from '../state';
import { Sponsorship, SponsorshipStatus } from '../types/sponsorship';
import { Nullable, getSponsorshipStatus } from '../utils';
import _, { Dictionary } from 'lodash';
import { useState } from 'react';
import 'react-date-range/dist/styles.css'; // main css file
import 'react-date-range/dist/theme/default.css'; // theme css file
import { DateRange, Range } from 'react-date-range';
import { addDays } from 'date-fns';
import { Timestamp } from 'firebase/firestore';

export default function SponsorshipPage() {
	const sponsors = useAppDataStore((state) => _.values(state.sponsors.sponsors)).sort(
		(a, b) => a.dateBegin.seconds - b.dateBegin.seconds
	);

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
			{isShowingAddSponsor && (
				<NewSponsorshipModal // so the modal gets unmounted on close (and internal state gets reset)
					open={true}
					dismiss={() => setIsShowingAddSponsor(false)}
					sponsors={sponsors}
				/>
			)}
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

function NewSponsorshipModal({
	open,
	dismiss,
	sponsors,
}: {
	open: boolean;
	dismiss: () => void;
	sponsors: Sponsorship[];
}) {
	const lastSponsor = _.last(sponsors);
	const newSponsorshipStart = new Date(
		((lastSponsor?.dateEnd.seconds ?? Date.now() / 1000) + 24 * 60 * 60) * 1000
	);
	const [formState, setFormState] = useState<Nullable<Sponsorship>>({
		dateBegin: null,
		dateEnd: null,
		dedication: null,
		name: null,
		title: null,
		isBlockedFromDeletion: false,
		id: null,
	});
	const [sponsorRange, setSponsorRange] = useState<Range>({
		showDateDisplay: true,
		autoFocus: true,
		disabled: false,
		color: '#3f51b5',
		startDate: newSponsorshipStart,
		endDate: addDays(newSponsorshipStart, 7),
		key: 'selection',
	});
	const existingSponsorRanges: Dictionary<Range> = _.fromPairs(
		_.map(sponsors, (sponsor) => [
			sponsor.id,
			{
				startDate: new Date(sponsor.dateBegin.seconds * 1000),
				endDate: new Date(sponsor.dateEnd.seconds * 1000),
				key: sponsor.id,
				disabled: true,
				autoFocus: false,
				showDateDisplay: false,
			} as Range,
		])
	);
	const addSponsor = useAppDataStore((state) => state.sponsors.addSponsor);
	return (
		<Modal open={open} onClose={dismiss}>
			<Box
				sx={{
					position: 'absolute',
					top: '50%',
					left: '50%',
					transform: 'translate(-50%, -50%)',
					width: 700,
				}}
			>
				<Card sx={{ padding: 2 }}>
					<CardHeader title="New Sponsor" />
					<CardContent>
						<Stack direction="column" spacing={1}>
							<TextField
								fullWidth
								required
								error={formState.name !== null && formState.name?.trim() === ''}
								label="Name of Sponsor"
								value={formState.name ?? ''}
								onChange={(e) => {
									setFormState({
										...formState,
										name: e.target.value.trimStart(),
									});
								}}
							/>
							<TextField
								fullWidth
								required
								error={formState.title !== null && formState.title?.trim() === ''}
								label="Dedication Title"
								placeholder={
									'e.g. "Learning for the month of... is sponsored by..."'
								}
								value={formState.title ?? ''}
								onChange={(e) => {
									setFormState({
										...formState,
										title: e.target.value.trimStart(),
									});
								}}
							/>
							<TextField
								fullWidth
								required
								error={
									formState.dedication !== null &&
									formState.dedication?.trim() === ''
								}
								label="Dedication Subtitle"
								placeholder={'e.g. "Leilui Nishmas..." or "In honor of..."'}
								value={formState.dedication}
								onChange={(e) => {
									setFormState({
										...formState,
										dedication: e.target.value.trimStart(),
									});
								}}
							/>
							<Box />
						</Stack>
						<Stack justifyContent="center" alignItems="center" width="100%">
							<DateRange
								editableDateInputs={true}
								onChange={(item) => {
									setSponsorRange({ ...item.selection });
								}}
								moveRangeOnFirstSelection={false}
								ranges={_.concat(sponsorRange, ..._.values(existingSponsorRanges))}
								minDate={new Date()}
								disabledDay={(date) => {
									return _.some(
										existingSponsorRanges,
										(range) =>
											(range.startDate &&
												range.endDate &&
												range.endDate >= date &&
												range.startDate <= date) ??
											false
									);
								}}
							/>
						</Stack>
						<Stack direction="column" spacing={2}>
							<Box />
							<Stack direction="row" spacing={2}>
								<Button
									variant="outlined"
									color="error"
									fullWidth
									onClick={dismiss}
								>
									Cancel
								</Button>
								<Button
									variant="contained"
									color="primary"
									fullWidth
									disabled={
										formState.dedication === null ||
										formState.name === null ||
										formState.title === null ||
										formState.dedication === '' ||
										formState.name === '' ||
										formState.title === ''
									}
									onClick={() => {
										// Set sponsorship end-date to extend until that night (11:59:59)
										sponsorRange.endDate = addDays(sponsorRange.endDate!, 1);
										formState.dateBegin = new Timestamp(
											sponsorRange.startDate!.getTime() / 1000,
											0
										);
										formState.dateEnd = new Timestamp(
											sponsorRange.endDate!.getTime() / 1000 - 1,
											0
										);
										addSponsor(
											formState as NonNullable<Optional<Sponsorship, 'id'>>
										);
										dismiss();
									}}
								>
									Add Sponsor
								</Button>
							</Stack>
						</Stack>
					</CardContent>
				</Card>
			</Box>
		</Modal>
	);
}
