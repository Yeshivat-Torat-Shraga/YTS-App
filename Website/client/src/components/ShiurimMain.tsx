import { Grid } from '@mui/material';
import { Box } from '@mui/system';
import ShiurCard from './ShiurCard';
import { useAppDataStore } from '../state';

export default function ShiurimMain() {
	const shiurim = useAppDataStore((state) => state.shiur.shiurim);
	return (
		<Box>
			<Grid container>
				{shiurim.map((shiur) => (
					<ShiurCard shiur={shiur} key={shiur.id} />
				))}
			</Grid>
		</Box>
	);
}