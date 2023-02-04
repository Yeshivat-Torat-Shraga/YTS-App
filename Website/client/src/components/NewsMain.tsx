import { Box, Grid, Typography } from '@mui/material';
import { useAppDataStore } from '../state';
import Article from '../types/article';

export function NewsMain() {
	const articles = useAppDataStore((state) => state.news.articles);
	return (
		<Box>
			<Grid container>
				{articles.map((article) => (
					<ArticleCard article={article} />
				))}
			</Grid>
		</Box>
	);
}

export function ArticleCard({ article }: { article: Article }) {
	return <Typography key={article.id}>{article.title}</Typography>;
}
