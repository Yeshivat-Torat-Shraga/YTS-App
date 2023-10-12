import {
	Box,
	Typography,
	Avatar,
	Button,
	Stack,
	Modal,
	Card,
	CardHeader,
	TextField,
	CardContent,
	Select,
	MenuItem,
	InputLabel,
	FormControl,
} from '@mui/material';
import ShiurCard from './ShiurCard';
import { useAppDataStore } from '../state';
import {
	GridRowsProp,
	GridRowModesModel,
	GridRowModes,
	DataGrid,
	GridColDef,
	GridToolbarContainer,
	GridActionsCellItem,
	GridEventListener,
	GridRowId,
	GridRowModel,
	GridRowEditStopReasons,
} from '@mui/x-data-grid';
import _ from 'lodash';
import { generateTimeString, uploadShiurFile } from '../utils';
import { Add, Check, Delete, Edit, Schedule, UploadFile } from '@mui/icons-material';
import { useState } from 'react';
import { RawShiur, Shiur, shiurToRawShiur } from '../types/shiur';
import { Timestamp } from 'firebase/firestore';
import { DropzoneArea } from 'mui-file-dropzone';

export default function ShiurimMain() {
	const shiurim = useAppDataStore((state) => state.shiur.shiurim);
	const rebbeim = useAppDataStore((state) => state.rabbi.rebbeim);
	const [editShiur, setEditShiur] = useState<Shiur | undefined | null>(undefined);
	return (
		<div>
			<Box height="100%" width="100%">
				<DataGrid
					rows={_.values(shiurim).sort((a, b) => b.date.seconds - a.date.seconds)}
					rowHeight={80}
					columns={[
						{
							field: 'picURL',
							headerName: 'Speaker',
							flex: 2,
							renderCell: (params) => (
								<Stack
									direction="row"
									/* Vertically center content */ alignItems="center"
								>
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
							// renderCell: (params) => (
							// 	<Typography variant="h6" sx={{ wordWrap: 'break-word' }}>
							// 		{params.row.title}
							// 	</Typography>
							// ),
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
											useAppDataStore
												.getState()
												.shiur.updateShiur(params.row);
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
											useAppDataStore
												.getState()
												.shiur.deleteShiur(params.row);
										}}
									>
										Delete
									</Button>
								</Stack>
							),
						},
					]}
					slots={{
						toolbar: () => (
							<GridToolbarContainer>
								<Button
									variant="outlined"
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
			</Box>
			<Modal open={editShiur !== undefined} onClose={() => setEditShiur(undefined)}>
				{editShiur !== undefined ? (
					<Box
						sx={{
							position: 'absolute',
							top: '50%',
							left: '50%',
							transform: 'translate(-50%, -50%)',
							width: 700,
						}}
					>
						<EditShiurModalContents shiur={editShiur} />
					</Box>
				) : (
					<></>
				)}
			</Modal>
		</div>
	);
}

function EditShiurModalContents({ shiur }: { shiur: Shiur | null }) {
	// If shiur is null, then we are creating a new shiur
	const isNewShiur = shiur === null;
	const [formState, setFormState] = useState<Partial<Shiur>>(shiur ?? {});
	const rebbeim = _.values(useAppDataStore((state) => state.rabbi.rebbeim)).sort((a, b) =>
		a.name.localeCompare(b.name)
	);
	const [file, setFile] = useState<File | null>(null);
	const categories = _.values(useAppDataStore((state) => state.tags.tags))
		.sort((a, b) => a.displayName.localeCompare(b.displayName))
		.filter((tag) => tag.subCategories === undefined);
	return (
		<Card sx={{ padding: 4 }}>
			<CardHeader
				title={
					<Stack direction="column" spacing={2}>
						<Typography variant="h4">
							{isNewShiur ? 'New Shiur' : 'Edit Shiur'}
						</Typography>
						<TextField
							fullWidth
							label="Title"
							value={formState.title}
							onChange={(e) => {
								setFormState({ ...formState, title: e.target.value });
							}}
						/>
					</Stack>
				}
			/>
			<CardContent>
				<Stack direction="column" spacing={2}>
					<Stack direction="row" spacing={2}>
						<TextField
							select
							id="speaker"
							fullWidth
							label="Speaker"
							value={formState.attributionID ?? ''}
							onChange={(e) => {
								setFormState({
									...formState,
									attributionID: e.target.value,
									authorName: rebbeim.find(
										(rebbe) => rebbe.id === e.target.value
									)!.name,
								});
							}}
						>
							{rebbeim.map((rebbe) => (
								<MenuItem value={rebbe.id}>{rebbe.name}</MenuItem>
							))}
						</TextField>
						<TextField
							fullWidth
							label="Category"
							select
							value={formState.tagData?.id ?? ''}
							onChange={(e) => {
								console.log(e.target.value);
								setFormState({
									...formState,
									tagData: categories.find((tag) => tag.id === e.target.value),
								});
							}}
						>
							{categories.map((tag) => (
								<MenuItem value={tag.id}>{tag.displayName}</MenuItem>
							))}
						</TextField>
					</Stack>
					<TextField
						fullWidth
						label="Description"
						value={formState.description}
						onChange={(e) => {
							setFormState({ ...formState, description: e.target.value });
						}}
					/>
					<DropzoneArea
						fileObjects={[]}
						filesLimit={1}
						dropzoneText={`Drop an audio file or click to choose a file`}
						acceptedFiles={['audio/*']}
						onChange={(files) => setFile(files[0])}
					/>

					<Button
						variant="outlined"
						color="primary"
						fullWidth
						disabled={
							_.values(formState).some((value) => _.isNil(value)) || file === null
						}
						onClick={() => {
							formState.date = Timestamp.now();
							// TODO: Upload audio file
							uploadShiurFile(shiurToRawShiur(formState as Shiur), file as File);
						}}
					>
						Submit
					</Button>
				</Stack>
			</CardContent>
		</Card>
	);
}
