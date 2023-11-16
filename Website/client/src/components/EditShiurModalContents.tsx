import {
	Typography,
	Stack,
	Card,
	CardHeader,
	TextField,
	CardContent,
	MenuItem,
	Alert,
} from '@mui/material';
import { useAppDataStore } from '../state';
import _ from 'lodash';
import { uploadShiurFile } from '../utils';
import { useState } from 'react';
import { Shiur, shiurToRawShiur } from '../types/shiur';
import { Timestamp } from 'firebase/firestore';
import { DropzoneArea } from 'mui-file-dropzone';
import { LoadingButton } from '@mui/lab';

export default function EditShiurModalContents({
	shiur,
	closeModal,
}: {
	shiur: Shiur | null;
	closeModal: () => void;
}) {
	// If shiur is null, then we are creating a new shiur
	const isNewShiur = shiur === null;
	const [formState, setFormState] = useState<Partial<Shiur>>(shiur ?? {});
	const rebbeim = _.values(useAppDataStore((state) => state.rebbeim)).sort((a, b) =>
		a.name.localeCompare(b.name)
	);
	const [file, setFile] = useState<File | null>(null);
	const categories = _.values(useAppDataStore((state) => state.tags))
		.sort((a, b) => a.displayName.localeCompare(b.displayName))
		.filter((tag) => tag.subCategories === undefined);
	const formStateHasEmptyFields = [
		formState.title,
		formState.attributionID,
		formState.tagData,
		// formState.description,
	].some((field) => field === undefined || field === null || field === '');

	const [isUploading, setIsUploading] = useState(false);
	const [error, setError] = useState('');
	const [addShiur, updateShiur] = useAppDataStore((state) => [state.addShiur, state.updateShiur]);

	return (
		<Card sx={{ padding: 4 }}>
			<CardHeader
				title={
					<Stack direction="column" spacing={2}>
						<Typography variant="h4">
							{isNewShiur ? 'New Shiur' : 'Edit Shiur'}
						</Typography>
						<TextField
							fullWidth
							required
							error={formState.title?.trim() === ''}
							label="Title"
							// helperText={shiur !== null ? `ID: ${shiur.id}` : undefined}
							value={formState.title}
							onChange={(e) => {
								setFormState({ ...formState, title: e.target.value.trimStart() });
							}}
						/>
					</Stack>
				}
			/>
			<CardContent>
				<Stack direction="column" spacing={2}>
					<Stack direction="row" spacing={2}>
						<TextField
							select
							id="speaker"
							required
							error={formState.attributionID === ''}
							fullWidth
							label="Speaker"
							value={formState.attributionID ?? ''}
							onChange={(e) => {
								setFormState({
									...formState,
									attributionID: e.target.value,
									authorName: rebbeim.find(
										(rebbe) => rebbe.id === e.target.value
									)!.name,
								});
							}}
						>
							{rebbeim.map((rebbe) => (
								<MenuItem value={rebbe.id} key={rebbe.id}>
									{rebbe.name}
								</MenuItem>
							))}
						</TextField>
						<TextField
							fullWidth
							required
							// error={formState.tagData === undefined}
							label="Category"
							select
							value={formState.tagData?.id ?? ''}
							onChange={(e) => {
								console.log(e.target.value);
								setFormState({
									...formState,
									tagData: categories.find((tag) => tag.id === e.target.value),
								});
							}}
						>
							{categories.map((tag) => (
								<MenuItem value={tag.id} key={tag.id}>
									{tag.displayName}
								</MenuItem>
							))}
						</TextField>
					</Stack>
					<TextField
						fullWidth
						label="Description"
						value={formState.description}
						onChange={(e) => {
							setFormState({ ...formState, description: e.target.value });
						}}
					/>
					{shiur === null && (
						<DropzoneArea
							fileObjects={[]}
							filesLimit={1}
							maxFileSize={256 * 1024 * 1024}
							dropzoneText={`Drop an audio file or click to choose a file`}
							acceptedFiles={['audio/*', 'video/*']}
							onChange={(files) =>
								files.length === 0 ? setFile(null) : setFile(files[0])
							}
							useChipsForPreview
						/>
					)}

					<LoadingButton
						variant="outlined"
						color="primary"
						loading={isUploading}
						fullWidth
						disabled={
							formStateHasEmptyFields ||
							(shiur === null && file === null) ||
							(shiur !== null && _.isEqual(shiur, formState)) ||
							isUploading
						}
						onClick={() => {
							if (shiur === null) {
								formState.date = Timestamp.now();
								formState.pending = false;
								formState.viewCount = 0;
								formState.description = formState.description ?? '';
								// TODO: Upload audio file
								setIsUploading(true);
								uploadShiurFile(formState as Shiur, file as File)
									.then((resultingShiur) => {
										setIsUploading(false);
										addShiur(resultingShiur);
										closeModal();
									})
									.catch((error) => {
										setError(
											"Upload failed. If this is the first time you're uploading a shiur, please wait a few minutes and try again. If the problem persists, do not retry, and contact the developer."
										);
										setIsUploading(false);
									});
							} else {
								updateShiur(formState as Shiur);
								closeModal();
							}
						}}
					>
						{isUploading ? 'Uploading...' : shiur === null ? 'Upload' : 'Save'}
					</LoadingButton>
					{!!error && <Alert severity="error">{error}</Alert>}
				</Stack>
			</CardContent>
		</Card>
	);
}
