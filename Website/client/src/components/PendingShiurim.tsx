import { Box, Modal } from '@mui/material';
import { useAppDataStore } from '../state';
import _ from 'lodash';
import { useMemo, useState } from 'react';
import { Shiur } from '../types/shiur';
import ShiurimTable from './ShiurimTable';
import EditShiurModalContents from './EditShiurModalContents';

export default function PendingShiurim() {
	const shiurim = useAppDataStore((state) => state.shiurim);
	const rebbeim = useAppDataStore((state) => state.rebbeim);
	const [editShiur, setEditShiur] = useState<Shiur | undefined | null>(undefined);
	const pendingShiurim = useMemo(() => {
		const list = _.values(shiurim)
			.filter((shiur) => shiur.pending)
			.sort((a, b) => b.date.seconds - a.date.seconds);
		return _.keyBy(list, 'id');
	}, [shiurim]);
	return (
		<div>
			<Box height="100%">
				<ShiurimTable
					shiurim={pendingShiurim}
					rebbeim={rebbeim}
					setEditShiur={setEditShiur}
					isForPending
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
