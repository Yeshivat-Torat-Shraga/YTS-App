import { Box, Grid } from '@mui/material';
import { useAppDataStore } from '../state';
import ShiurCard from './ShiurCard';
import _ from 'lodash';
export default function PendingShiurim() {
	const shiurim = _.values(useAppDataStore((state) => state.shiur.shiurim));
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
