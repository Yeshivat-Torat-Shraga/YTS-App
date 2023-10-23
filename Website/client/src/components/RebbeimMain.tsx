import { Avatar, Box, Button, Modal, Typography } from '@mui/material';
import { useAppDataStore } from '../state';
import { DataGrid, GridToolbarContainer } from '@mui/x-data-grid';
import _ from 'lodash';
import { PersonAdd } from '@mui/icons-material';
import { useState } from 'react';
import NewRabbiModalContents from './NewRabbiModalContents';
export default function AllRebbeim() {
	const rebbeim = useAppDataStore((state) => state.rabbi.rebbeim);
	const [isAddingRabbi, setIsAddingRabbi] = useState(false);
	return (
		<Box height="100%" width="100%">
			<DataGrid
				rows={_.values(rebbeim)}
				rowHeight={80}
				slots={{
					toolbar: () => (
						<GridToolbarContainer>
							<Button
								variant="contained"
								fullWidth
								color="primary"
								startIcon={<PersonAdd />}
								onClick={() => {
									setIsAddingRabbi(true);
								}}
							>
								New Rebbi
							</Button>
						</GridToolbarContainer>
					),
				}}
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
			/>
			<Modal open={isAddingRabbi} onClose={() => setIsAddingRabbi(false)}>
				{!!isAddingRabbi ? (
					<Box
						sx={{
							position: 'absolute',
							top: '50%',
							left: '50%',
							transform: 'translate(-50%, -50%)',
							width: 700,
						}}
					>
						<NewRabbiModalContents />
					</Box>
				) : (
					<></>
				)}
			</Modal>
		</Box>
	);
}
