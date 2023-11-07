import { Typography, Button, Stack, Card, CardHeader, TextField, CardContent } from '@mui/material';
import { useAppDataStore } from '../state';
import { useState } from 'react';
import { DropzoneArea } from 'mui-file-dropzone';
import { Portrait } from '@mui/icons-material';
import { uploadNewRebbi } from '../utils';
export default function NewRabbiModalContents() {
	// If shiur is null, then we are creating a new shiur
	// Max file size is 256MB
	const [formState, setFormState] = useState<Partial<{ name: string; profilePicture: File }>>({
		name: '',
		profilePicture: undefined,
	});
	const addRebbi = useAppDataStore((state) => state.addRebbi);
	return (
		<Card sx={{ padding: 4 }}>
			<CardHeader
				title={
					<Stack direction="column" spacing={2}>
						<Typography variant="h4">New Rebbi</Typography>
						<TextField
							fullWidth
							required
							error={formState.name?.trim() === ''}
							label="Name"
							value={formState.name}
							onChange={(e) => {
								setFormState({ ...formState, name: e.target.value.trimStart() });
							}}
						/>
					</Stack>
				}
			/>
			<CardContent>
				<Stack direction="column" spacing={2}>
					<DropzoneArea
						fileObjects={[]}
						filesLimit={1}
						dropzoneText={`Drop a profile picture or click to choose a file`}
						acceptedFiles={['image/*']}
						maxFileSize={256 * 1024 * 1024}
						Icon={Portrait}
						onChange={(files) =>
							files.length === 0
								? setFormState({ ...formState, profilePicture: undefined })
								: setFormState({ ...formState, profilePicture: files[0] })
						}
						useChipsForPreview
					/>

					<Button
						variant="outlined"
						color="primary"
						fullWidth
						disabled={
							formState.name?.trim() === '' || formState.profilePicture === undefined
						}
						onClick={() => {
							uploadNewRebbi(formState.name!, formState.profilePicture!).then(
								addRebbi
							);
						}}
					>
						Add Rebbi
					</Button>
				</Stack>
			</CardContent>
		</Card>
	);
}
