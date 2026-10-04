import { Router } from 'express';
import { createStory, getStories, viewStory, getStoryViewers, deleteStory } from '../controllers/story.controller';

const router = Router();

router.post('/', createStory);
router.get('/', getStories);
router.post('/:storyId/view', viewStory);
router.get('/:storyId/viewers', getStoryViewers);
router.delete('/:storyId', deleteStory);

export default router;

