import { Box, Grid } from '@mui/material';
import { useAppDataStore } from '../state';
import { RabbiCard } from './RabbiCard';

export default function AllRebbeim() {
	const rebbeim = useAppDataStore((state) => state.rabbi.rebbeim);
	return (
		<Box>
			<Grid container p={1}>
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
			</Grid>
		</Box>
	);
}
