import { Avatar, Box, Button, Grid, Typography } from '@mui/material';
import { useAppDataStore } from '../state';
import { RabbiCard } from './RabbiCard';
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
export default function AllRebbeim() {
	const rebbeim = useAppDataStore((state) => state.rabbi.rebbeim);
	return (
		<Box height="100%" width="100%">
			<DataGrid
				rows={_.values(rebbeim)}
				rowHeight={80}
				columns={[
					{
						field: 'picURL',
						headerName: 'Profile',
						flex: 1,
						renderCell: (params) => (
							<Box>
								<Avatar
									src={params.row.profilePictureURL}
									sx={{ width: 70, height: 70, borderRadius: '10%' }}
								/>
							</Box>
						),
					},
					{
						field: 'name',
						headerName: 'Name',
						flex: 6,
						renderCell: (params) => (
							<Typography variant="h6">{params.row.name}</Typography>
						),
					},
					{
						field: 'visible',
						headerName: 'Visible',
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
									color={params.row.visible ? 'success' : 'error'}
									onClick={() => {
										params.row.visible = !params.row.visible;
										useAppDataStore.getState().rabbi.updateRebbe(params.row);
									}}
								>
									{params.row.visible ? 'Visible' : 'Hidden'}
								</Button>
							</Box>
						),
					},
				]}
				// components={{
				// 	Toolbar: GridToolbarContainer,
				// }}
				// componentsProps={{
				// 	toolbar: {
				// 		// disableExport: true,
				// 		// disableColumnSelector: true,
				// 		// disableDensitySelector: true,
				// 		// disableFilterButton: true,
				// 		// disableColumnFilter: true,
				// 		// disableColumnMenu: true,
				// 		// disableColumnReorder: true,
				// 		// disableColumnResize: true,
			/>
			{/* <Grid container p={1}>
				{rebbeim
					.sort((rhs, lhs) => {
						if (rhs.name < lhs.name) {
							return -1;
						}
						if (rhs.name > lhs.name) {
							return 1;
						}
						return 0;
					})
					.map((rabbi) => (
						<RabbiCard rabbi={rabbi} key={rabbi.id} />
					))}
			</Grid> */}
		</Box>
	);
}
