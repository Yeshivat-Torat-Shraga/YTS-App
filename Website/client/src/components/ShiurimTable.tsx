// import hlsjs from 'hls.js';
// import 'mediaelement';
import { DataGrid, GridToolbarContainer } from '@mui/x-data-grid';
import { generateTimeString } from '../utils';
import { Check, Clear, Delete, Edit, Schedule, UploadFile } from '@mui/icons-material';
import { Shiur } from '../types/shiur';
import { Box, Typography, Avatar, Button, Stack, CircularProgress } from '@mui/material';
import _ from 'lodash';
import { useAppDataStore } from '../state';
import { useMemo, useState } from 'react';
import { functions } from '../Firebase/firebase';
import { httpsCallable } from 'firebase/functions';
import HLSAudioPlayer from './Player';

export default function ShiurimTable({
	shiurim,
	rebbeim,
	setEditShiur,
	isForPending = false,
}: {
	shiurim: { [key: string]: Shiur };
	rebbeim: { [key: string]: { name: string; profilePictureURL: string } };
	setEditShiur: (shiur: Shiur | null) => void;
	isForPending?: boolean;
}) {
	const [deleteShiur, updateShiur] = useAppDataStore((state) => [
		state.deleteShiur,
		state.updateShiur,
	]);
	const sortedIndexedShiurim = useMemo(() => {
		const numberOfShiurim = Object.keys(shiurim).length;
		return _.values(shiurim)
			.sort((a, b) => b.date.seconds - a.date.seconds)
			.map((shiur, index) => {
				return {
					...shiur,
					// Reverse the index so that the most recent shiur is at the top
					index: numberOfShiurim - index,
				};
			});
	}, [shiurim]);

	return sortedIndexedShiurim.length === 0 ? (
		<Stack direction="column" alignItems="center" justifyContent="center" p={10} spacing={3}>
			<Typography variant="h4" align="center" color="text.disabled">
				{isForPending ? 'No Pending Shiurim' : 'No Shiurim'}
			</Typography>
			<Typography variant="body1" align="center" color="text.disabled">
				{isForPending ? (
					<>
						This is where user submitted shiurim will appear.
						<br /> They will be available for approval here.
					</>
				) : (
					'There are no shiurim at this time'
				)}
			</Typography>
		</Stack>
	) : (
		<DataGrid
			sx={{ maxWidth: '100%' }}
			rows={sortedIndexedShiurim}
			rowHeight={80}
			initialState={{ pagination: { paginationModel: { pageSize: 25 } } }}
			columnVisibilityModel={{
				index: !isForPending,
				pending: !isForPending,
				audioPreview: isForPending,
			}}
			columns={[
				{
					field: 'index',
					headerName: '#',
					filterable: false,
					sortable: false,
					// flex: 1,
					width: 16,
					renderCell: (params) => {
						// we need to get the index of the row in the sorted list of shiurim
						return (
							<Typography color="text.disabled" variant="body1">
								{params.row.index}
							</Typography>
						);
					},
				},
				{
					field: 'picURL',
					headerName: 'Speaker',
					flex: 2,
					renderCell: (params) => (
						<Stack direction="row" alignItems="center">
							<Avatar
								src={rebbeim[params.row.attributionID].profilePictureURL}
								sx={{ width: 70, height: 70, borderRadius: '10%' }}
								title={rebbeim[params.row.attributionID].name}
							/>
							<Typography variant="body1" m={2}>
								{rebbeim[params.row.attributionID].name}
							</Typography>
						</Stack>
					),
				},
				{
					field: 'duration',
					headerName: 'Length',
					flex: 1,
					renderCell: (params) => (
						<Typography variant="body1">
							{generateTimeString(params.row.duration)}
						</Typography>
					),
				},
				{
					field: 'title',
					headerName: 'Title',
					flex: 4,
				},
				{
					field: 'pending',
					headerName: 'Availability',
					flex: 1,
					type: 'boolean',
					renderCell: (params) => (
						<Box p={10}>
							<Button
								variant="outlined"
								sx={{
									borderRadius: 8,
									// textTransform: 'none',
									paddingY: 0.2,
									paddingX: 1,
									fontWeight: 'bold',
								}}
								color={params.row.pending ? 'warning' : 'success'}
								onClick={() => {
									params.row.pending = !params.row.pending;
									updateShiur(params.row);
								}}
								endIcon={
									params.row.pending ? (
										<Schedule color="warning" />
									) : (
										<Check color="success" />
									)
								}
							>
								{params.row.pending ? 'Pending' : 'Live'}
							</Button>
						</Box>
					),
				},
				{
					field: 'audioPreview',
					headerName: 'Audio Preview',
					flex: 3,
					renderCell: (params) => <AudioPreview params={params} />,
				},
				{
					field: 'date',
					headerName: 'Upload Date',
					flex: 1,
					renderCell: (params) => (
						<Typography variant="body1">
							{new Date(params.row.date.seconds * 1000).toLocaleDateString()}
						</Typography>
					),
				},
				{
					field: 'actions',
					headerName: 'Actions',
					flex: 2,
					renderCell: (params) => (
						<Stack direction="row" spacing={2}>
							{isForPending ? (
								<>
									<Button
										variant="outlined"
										sx={{
											borderRadius: 8,
											paddingY: 0.2,
											paddingX: 1,
											fontWeight: 'bold',
										}}
										color="success"
										endIcon={<Check />}
										onClick={() => {
											params.row.pending = false;
											updateShiur(params.row);
										}}
									>
										Approve
									</Button>
									<Button
										variant="outlined"
										sx={{
											borderRadius: 8,
											paddingY: 0.2,
											paddingX: 1,
											fontWeight: 'bold',
										}}
										color="error"
										endIcon={<Clear />}
										onClick={() => {
											deleteShiur(params.row);
										}}
									>
										Reject
									</Button>
								</>
							) : (
								<>
									<Button
										variant="outlined"
										sx={{
											borderRadius: 8,
											paddingY: 0.2,
											paddingX: 1,
											fontWeight: 'bold',
										}}
										color="primary"
										endIcon={<Edit />}
										onClick={() => {
											setEditShiur(params.row);
										}}
									>
										Edit
									</Button>
									<Button
										variant="outlined"
										sx={{
											borderRadius: 8,
											paddingY: 0.2,
											paddingX: 1,
											fontWeight: 'bold',
										}}
										color="error"
										endIcon={<Delete />}
										onClick={() => {
											deleteShiur(params.row);
										}}
									>
										Delete
									</Button>
								</>
							)}
						</Stack>
					),
				},
			]}
			slots={{
				toolbar: isForPending
					? null
					: () => (
							<GridToolbarContainer>
								<Button
									variant="contained"
									fullWidth
									color="primary"
									startIcon={<UploadFile />}
									onClick={() => {
										setEditShiur(null);
									}}
								>
									New Shiur
								</Button>
							</GridToolbarContainer>
					  ),
			}}
			slotProps={{
				toolbar: {
					// disableExport: true,
					// disableColumnSelector: true,
					// disableDensitySelector: true,
					// disableFilterButton: true,
					// disableColumnFilter: true,
					// disableColumnMenu: true,
					// disableColumnReorder: true,
					// disableColumnResize: true,
				},
			}}
		/>
	);
}

function AudioPreview({ params }: { params: any }) {
	const [audioURL, setAudioURL] = useState<string | undefined>(undefined);
	const shiur = params.row as Shiur;
	useMemo(async () => {
		if (!audioURL) {
			generateV4ReadSignedUrlFor(shiur).then((url) => {
				setAudioURL(url);
			});
		}
	}, [shiur, audioURL]);
	return audioURL ? <HLSAudioPlayer hlsSource={audioURL} /> : <CircularProgress />;
}

async function generateV4ReadSignedUrlFor(shiur: Shiur) {
	// Get a v4 signed URL for reading the file
	const getURL = httpsCallable(functions, 'loadSignedUrlBySourcePath');

	const url = (await getURL({ sourcePath: shiur.source_path }).then(
		(result) => result.data
	)) as string;

	return url;
}
