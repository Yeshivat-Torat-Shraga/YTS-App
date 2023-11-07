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
	Collapse,
	IconButton,
	Modal,
	Paper,
	Stack,
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableRow,
	TextField,
	Typography,
} from '@mui/material';
import { Optional, useAppDataStore } from '../state';
import Article from '../types/article';
import _ from 'lodash';
import {
	Clear,
	CloudUpload,
	Edit,
	ExpandMore,
	KeyboardArrowDown,
	KeyboardArrowUp,
	PostAdd,
	Save,
} from '@mui/icons-material';
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
				sx={{ mb: 2 }}
				variant="contained"
				fullWidth
				startIcon={<PostAdd />}
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
			<Paper elevation={3}>
				<Table>
					<TableHead>
						<TableRow>
							<TableCell />
							<TableCell>Title</TableCell>
							<TableCell>Author</TableCell>
							<TableCell align="right">Actions</TableCell>
						</TableRow>
					</TableHead>
					<TableBody>
						{_.map(articles, (article) => (
							<Row
								key={article.id}
								row={article}
								deleteArticle={() => deleteArticle(article)}
								editArticle={() => setArticleToEdit(article)}
							/>
						))}
					</TableBody>
				</Table>
			</Paper>
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

function Row(props: { row: Article; deleteArticle: () => void; editArticle: () => void }) {
	const { row, deleteArticle, editArticle } = props;
	const [open, setOpen] = useState(false);

	return (
		<>
			<TableRow sx={{ '& > *': { borderBottom: 'unset' } }}>
				<TableCell>
					<IconButton aria-label="expand row" size="small" onClick={() => setOpen(!open)}>
						{open ? <KeyboardArrowUp /> : <KeyboardArrowDown />}
					</IconButton>
				</TableCell>
				<TableCell component="th" scope="row">
					{row.title}
				</TableCell>
				<TableCell>{row.author}</TableCell>
				<TableCell>
					<Stack direction="row" spacing={1} justifyContent="flex-end">
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
								editArticle();
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
								deleteArticle();
							}}
							endIcon={<Clear />}
						>
							Delete
						</Button>
					</Stack>
				</TableCell>
			</TableRow>
			<TableRow>
				<TableCell style={{ paddingBottom: 0, paddingTop: 0 }} colSpan={6}>
					<Collapse in={open} timeout="auto" unmountOnExit>
						<Box sx={{ margin: 1 }}>
							<Markdown>{row.body}</Markdown>
						</Box>
					</Collapse>
				</TableCell>
			</TableRow>
		</>
	);
}
