import { Card, CardContent, Grid, Typography } from '@mui/material';
import { collection, getDocs } from 'firebase/firestore';
import React, { useContext, useEffect, useState } from 'react';
import { firestore } from '../Firebase/firebase';
// import _ from 'lodash';
import Shiur from '../types/shiur';
import { Box } from '@mui/system';
import ShiurCard from './Shiur';
import { loremIpsum } from '../loremipsum';
import { AuthContext } from '../authContext';

export default function ShiurimMain() {
	const [shiurim, setShiurim] = useState([] as Shiur[]);
	const auth = useContext(AuthContext);

	const fetchShiurim = async () => {
		await getDocs(collection(firestore, 'content')).then((querySnapshot) => {
			const newShiurim = (
				querySnapshot.docs.map((doc) => ({
					...doc.data(),
					id: doc.id,
				})) as Shiur[]
			)
				.filter((shiur) => shiur.source_path !== undefined)
				.sort((a, b) => b.date.toDate().getTime() - a.date.toDate().getTime());
			setShiurim(newShiurim);
			// console.log(newShiurim);
		});
	};

	useEffect(() => {
		fetchShiurim();
	}, []);

	return (
		<Box>
			<Grid container>
				{auth ? (
					shiurim.map((shiur) => <ShiurCard shiur={shiur} key={shiur.id} />)
				) : (
					<Typography variant="body1" padding={5}>
						{loremIpsum} {loremIpsum}
					</Typography>
				)}
			</Grid>
		</Box>
	);
}
