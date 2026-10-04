import { Router } from 'express';
import { 
  getContacts, 
  getAllUsers, 
  searchContactByPhone,
  addContact, 
  getUserProfile, 
  syncContacts,
  getFriendRequests,
  acceptFriendRequest,
  rejectFriendRequest,
  resetContacts,
  getConversationMessages,
} from '../controllers/contact.controller';

const router = Router();

router.get('/', getContacts);
router.post('/reset', resetContacts);
router.get('/requests', getFriendRequests);
router.post('/accept', acceptFriendRequest);
router.post('/reject', rejectFriendRequest);
router.get('/messages/:conversationId', getConversationMessages);
router.get('/search', searchContactByPhone);
router.get('/all-users', getAllUsers);
router.post('/add', addContact);
router.get('/profile/:userId', getUserProfile);
router.post('/sync', syncContacts);

export default router;
