import { Grid } from '@mui/material';
import { Box } from '@mui/system';
import ShiurCard from './Shiur';
import { useShiurimStore } from '../state';

export default function ShiurimMain() {
	const shiurim = useShiurimStore((state) => state.shiurim);
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
