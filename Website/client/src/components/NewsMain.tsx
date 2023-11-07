import {
	Accordion,
	AccordionDetails,
	AccordionSummary,
	Box,
	Button,
	Card,
	CardActions,
	CardContent,
	CardHeader,
	Modal,
	Stack,
	TextField,
	Typography,
} from '@mui/material';
import { Optional, useAppDataStore } from '../state';
import Article from '../types/article';
import _ from 'lodash';
import { Clear, CloudUpload, Edit, ExpandMore, Save } from '@mui/icons-material';
import Markdown from 'react-markdown';
import MDEditor from '@uiw/react-md-editor';
import { useState } from 'react';
import { Timestamp } from 'firebase/firestore';
export function NewsMain() {
	const [articles, deleteArticle] = useAppDataStore((state) => [
		state.articles,
		state.deleteArticle,
	]);
	const [articleToEdit, setArticleToEdit] = useState<Optional<Article, 'id'> | null>(null);
	return (
		<Box>
			<Button
				onClick={() =>
					setArticleToEdit({
						id: undefined,
						title: '',
						author: '',
						body: '',
						date: new Timestamp(Date.now() / 1000, 0),
						imageURLs: [''],
					})
				}
			>
				New Article
			</Button>
			{_.map(articles, (article) => (
				<Accordion key={article.id}>
					<AccordionSummary expandIcon={<ExpandMore />}>
						<Stack
							direction="row"
							justifyContent="space-between"
							alignItems="center"
							spacing={1}
							width="100%"
							marginX={1}
						>
							<Typography>{article.title}</Typography>
							<Typography>{article.author}</Typography>
							<Stack direction="row" spacing={1}>
								<Button
									variant="outlined"
									sx={{
										borderRadius: 8,
										// textTransform: 'none',
										paddingY: 0.2,
										paddingX: 1,
										fontWeight: 'bold',
									}}
									color="primary"
									onClick={(e) => {
										e.stopPropagation();
										setArticleToEdit(article);
									}}
									endIcon={<Edit />}
								>
									Edit
								</Button>
								<Button
									variant="outlined"
									sx={{
										borderRadius: 8,
										// textTransform: 'none',
										paddingY: 0.2,
										paddingX: 1,
										fontWeight: 'bold',
									}}
									color="error"
									onClick={(e) => {
										e.stopPropagation();
										deleteArticle(article);
										// Delete article
									}}
									endIcon={<Clear />}
								>
									Delete
								</Button>
							</Stack>
						</Stack>
					</AccordionSummary>
					<AccordionDetails>
						<Markdown>{article.body}</Markdown>
					</AccordionDetails>
				</Accordion>
			))}
			{articleToEdit && (
				<ArticleEditModal
					article={articleToEdit}
					closeEditor={() => setArticleToEdit(null)}
				/>
			)}
		</Box>
	);
}

function ArticleEditModal({
	article,
	closeEditor,
}: {
	article: Partial<Article>;
	closeEditor: () => void;
}) {
	const [formState, setFormState] = useState(article);
	const updateArticle = useAppDataStore((state) => state.updateArticle);
	return (
		<Modal open={!!article} onClose={closeEditor}>
			<Box
				sx={{
					position: 'absolute',
					top: '50%',
					left: '50%',
					transform: 'translate(-50%, -50%)',
					width: '65vw',
				}}
			>
				<Card sx={{ padding: 4 }}>
					<CardHeader
						title={
							<TextField
								fullWidth
								required
								label="Title"
								value={formState.title}
								onChange={(e) => {
									setFormState({
										...formState,
										title: e.target.value.trimStart(),
									});
								}}
							/>
						}
					/>

					<CardContent>
						<Stack direction="column" spacing={2}>
							<TextField
								fullWidth
								required
								label="Author"
								value={formState.author}
								onChange={(e) => {
									setFormState({
										...formState,
										author: e.target.value.trimStart(),
									});
								}}
							/>
							<OutlinedDiv label="Body">
								<MDEditor
									height="50vh"
									value={formState.body}
									onChange={(value) => {
										setFormState({
											...formState,
											body: value ?? '',
										});
									}}
								/>
							</OutlinedDiv>
						</Stack>
					</CardContent>
					<CardActions>
						<Button
							variant="outlined"
							color="error"
							onClick={() => {
								closeEditor();
							}}
							endIcon={<Clear />}
							fullWidth
						>
							Cancel
						</Button>
						<Button
							variant="contained"
							color="primary"
							disabled={
								!formState.title ||
								formState.title.trim() === '' ||
								!formState.author ||
								formState.author.trim() === '' ||
								!formState.body ||
								formState.body.trim() === '' ||
								(!!formState.id && _.isEqual(formState, article))
							}
							onClick={() => {
								if (_.values(_.omit(formState, 'id')).some((value) => !value))
									return;
								updateArticle(formState as Optional<Article, 'id'>);
								// Make sure all fields are filled out

								// save(article);
								closeEditor();
							}}
							endIcon={article.id ? <Save /> : <CloudUpload />}
							fullWidth
						>
							{article.id ? 'Save' : 'Publish'}
						</Button>
					</CardActions>
				</Card>
			</Box>
		</Modal>
	);
}

const InputComponent = ({ inputRef, ...props }: any) => <div ref={inputRef} {...props} />;

const OutlinedDiv = ({ children, label }: { children: JSX.Element; label: string }) => {
	return (
		<TextField
			variant="outlined"
			label={label}
			multiline
			InputLabelProps={{ shrink: true }}
			InputProps={{
				inputComponent: InputComponent,
			}}
			inputProps={{ children: children }}
		/>
	);
};
export default OutlinedDiv;
