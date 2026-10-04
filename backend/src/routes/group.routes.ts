import { Router } from 'express';
import { createGroup, getGroups, addParticipants } from '../controllers/group.controller';

const router = Router();

router.post('/', createGroup);
router.get('/', getGroups);
router.post('/:groupId/participants', addParticipants);

export default router;
