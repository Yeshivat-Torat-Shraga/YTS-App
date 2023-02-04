import { Box, Grid } from '@mui/material';
import { useAppDataStore } from '../state';
import ShiurCard from './ShiurCard';

export default function PendingShiurim() {
	const shiurim = useAppDataStore((state) => state.shiur.shiurim);
	return (
		<Box>
			<Grid container>
				{shiurim
					.filter((shiur) => shiur.pending)
					.map((shiur) => (
						<ShiurCard shiur={shiur} key={shiur.id} />
					))}
			</Grid>
		</Box>
	);
}
