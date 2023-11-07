import {
	Box,
	Button,
	Card,
	CardContent,
	CardHeader,
	CardMedia,
	Modal,
	Paper,
	Stack,
	TextField,
	Typography,
	styled,
	useTheme,
} from '@mui/material';
import { Masonry } from '@mui/lab';
import { useAppDataStore } from '../state';
import _ from 'lodash';
import { ReactNode, useState } from 'react';
import { Delete, Upload } from '@mui/icons-material';
import { DropzoneArea } from 'mui-file-dropzone';
enum LabelType {
	TOP,
	BOTTOM,
}
function Label({
	error,
	type,
	children,
}: {
	error?: boolean;
	type: LabelType;
	children: ReactNode;
}) {
	const theme = useTheme();
	return (
		<Paper
			sx={{
				backgroundColor: theme.palette.mode === 'dark' ? '#1A2027' : '#fff',
				...theme.typography.body2,
				padding: theme.spacing(0.5),
				textAlign: 'center',
				color: theme.palette.text.secondary,
				borderBottomLeftRadius: type === LabelType.BOTTOM ? 'inherit' : 0,
				borderBottomRightRadius: type === LabelType.BOTTOM ? 'inherit' : 0,
				borderTopLeftRadius: type === LabelType.TOP ? 'inherit' : 0,
				borderTopRightRadius: type === LabelType.TOP ? 'inherit' : 0,
			}}
		>
			<Typography
				variant="body2"
				color={error ? 'error.main' : undefined}
				fontStyle={error ? 'italic' : undefined}
			>
				{children}
			</Typography>
		</Paper>
	);
}

export default function SlideshowPage() {
	const slideshowImages = _.values(useAppDataStore((state) => state.slideshow));
	const [isShowingUploadModal, setIsShowingUploadModal] = useState(false);
	return (
		<Stack
			direction="column"
			justifyContent="center"
			alignItems="center"
			spacing={2}
			width="100%"
		>
			<Typography variant="body1" color="text.secondary">
				This page features many high-resolution images. It may take a while to load.
			</Typography>
			<Button
				variant="contained"
				color="primary"
				onClick={() => setIsShowingUploadModal(true)}
				sx={{ width: '99%' }}
				startIcon={<Upload />}
			>
				Upload Images
			</Button>
			<Masonry columns={3} spacing={2}>
				{slideshowImages
					.sort((a, b) => a.uploaded.seconds - b.uploaded.seconds)
					.reverse()
					.map((item, index) => (
						<Card key={index} elevation={2}>
							<CardMedia component="img" image={item.url} />
							<CardContent>
								{/* Image Date */}
								<Typography
									variant="body2"
									color="text.secondary"
									fontStyle="italic"
								>
									{new Date(item.uploaded.seconds * 1000).toLocaleDateString()}
								</Typography>
								{/* Image Caption */}
								<Typography
									variant="body1"
									color={item.title ? 'text.secondary' : 'error'}
									fontStyle={item.title ? 'normal' : 'italic'}
								>
									{item.title ?? 'No caption provided'}
								</Typography>
								<Button
									variant="outlined"
									fullWidth
									color="error"
									// the icon will go at the end of the button
									endIcon={<Delete />}
									onClick={() => useAppDataStore.getState().deleteSlide(item)}
								>
									Delete Image
								</Button>
							</CardContent>
						</Card>
					))}
			</Masonry>
			{isShowingUploadModal && (
				<SlideshowUploadModal close={() => setIsShowingUploadModal(false)} />
			)}
		</Stack>
	);
}

type SlideshowUploadModalForm = {
	image: File | null;
	title: string | null;
	uploaded: Date | null;
	submitted: boolean;
};
function SlideshowUploadModal({ close }: { close: () => void }) {
	const [formState, setFormState] = useState<SlideshowUploadModalForm[]>([]);
	const addSlideshowImage = useAppDataStore((state) => state.addSlide);
	return (
		<Modal open onClose={close}>
			<Box
				sx={{
					position: 'absolute',
					top: '50%',
					left: '50%',
					transform: 'translate(-50%, -50%)',
					width: 700,
					maxHeight: '80vh',
				}}
			>
				<Card sx={{ padding: 2, maxHeight: '80vh', overflowY: 'scroll' }}>
					<CardHeader title="Upload Images" />
					<CardContent>
						{_.isEmpty(formState) ? (
							<DropzoneArea
								fileObjects={formState.map((slide) => slide.image)}
								// filesLimit={1}
								maxFileSize={256 * 1024 * 1024}
								dropzoneText={`Drop images or click to choose files`}
								acceptedFiles={['image/*']}
								onChange={(files) =>
									files.length === 0
										? setFormState([])
										: setFormState(
												files.map((file) => ({
													image: file,
													title: null,
													uploaded: new Date(),
													submitted: false,
												}))
										  )
								}
							/>
						) : (
							<Stack direction="column" spacing={2} sx={{ overflowY: 'scroll' }}>
								{formState.map((slide, index) => {
									if (slide.submitted) return null;
									return (
										<Card key={index} elevation={2}>
											<CardMedia
												component="img"
												image={URL.createObjectURL(slide.image!)}
											/>
											<CardContent>
												<Stack direction="column" spacing={1}>
													<TextField
														fullWidth
														required
														error={
															slide.title !== null &&
															slide.title?.trim() === ''
														}
														label="Title"
														value={slide.title ?? ''}
														onChange={(e) => {
															setFormState(
																formState.map((item, i) =>
																	i === index
																		? {
																				...item,
																				title: e.target.value.trimStart(),
																		  }
																		: item
																)
															);
														}}
													/>
													<Stack direction="row" spacing={1} width="100%">
														<Button
															fullWidth
															variant="outlined"
															color="error"
															onClick={() => {
																setFormState(
																	formState.filter(
																		(_item, i) => i !== index
																	)
																);
															}}
														>
															Delete
														</Button>
														<Button
															fullWidth
															variant="contained"
															disabled={
																slide.title === null ||
																slide.title.trim() === ''
															}
															color="primary"
															onClick={() => {
																const newFormState = formState.map(
																	(item, i) =>
																		i === index
																			? ({
																					...item,
																					submitted: true,
																			  } as SlideshowUploadModalForm)
																			: item
																);
																addSlideshowImage({
																	image: slide.image!,
																	title: slide.title!,
																	uploaded: slide.uploaded!,
																});
																setFormState(newFormState);
																if (
																	newFormState.every(
																		(item) => item.submitted
																	)
																) {
																	close();
																}
															}}
														>
															Submit
														</Button>
													</Stack>
												</Stack>
											</CardContent>
										</Card>
									);
								})}
							</Stack>
						)}
					</CardContent>
				</Card>
			</Box>
		</Modal>
	);
}
