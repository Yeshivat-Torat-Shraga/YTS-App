import { Box, Modal } from '@mui/material';
import { useAppDataStore } from '../state';
import _ from 'lodash';
import { useState } from 'react';
import { Shiur } from '../types/shiur';
import ShiurimTable from './ShiurimTable';
import EditShiurModalContents from './EditShiurModalContents';

export default function ShiurimMain() {
	const shiurim = useAppDataStore((state) => state.shiur.shiurim);
	const rebbeim = useAppDataStore((state) => state.rabbi.rebbeim);
	const [editShiur, setEditShiur] = useState<Shiur | undefined | null>(undefined);
	return (
		<div>
			<Box height="100%">
				<ShiurimTable shiurim={shiurim} rebbeim={rebbeim} setEditShiur={setEditShiur} />
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
