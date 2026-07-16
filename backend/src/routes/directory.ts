import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '@/middleware/auth';
import { 
  handleGetVillages, 
  handleOnboardFamily, 
  handleAddFamilyMember, 
  handleGetFamilyTree,
  handleGetMyFamily,
  handleUpdateFamilyMember,
  handleDeleteFamilyMember,
  handleGetPendingMembers,
  handleApproveMember,
  handleRejectMember,
  handleSearchMembers,
  handleGetBusinessMembers,
  handleAddBusinessMember,
  handleDeleteBusinessMember,
  handleGetMembers
} from '@/controllers/directory.controller';

const directoryRouter = new Hono();

// All directory endpoints require authentication
directoryRouter.use('*', authMiddleware);

directoryRouter.get('/villages', handleGetVillages);
directoryRouter.get('/my-family', handleGetMyFamily);
directoryRouter.post('/onboard-family', handleOnboardFamily);
directoryRouter.post('/member', handleAddFamilyMember);
directoryRouter.get('/family/:familyId/tree', handleGetFamilyTree);
directoryRouter.put('/member/:id', handleUpdateFamilyMember);
directoryRouter.delete('/member/:id', handleDeleteFamilyMember);

// Global member search
directoryRouter.get('/members', handleGetMembers);
directoryRouter.get('/members/search', handleSearchMembers);

// Business member assignments
directoryRouter.get('/business/:businessId/members', handleGetBusinessMembers);
directoryRouter.post('/business/:businessId/member', handleAddBusinessMember);
directoryRouter.delete('/business/:businessId/member/:memberId', handleDeleteBusinessMember);

// Moderation (Coordinator/Admin only)
directoryRouter.get('/moderation/pending', roleGuard(['admin', 'moderator']), handleGetPendingMembers);
directoryRouter.post('/moderation/member/:id/approve', roleGuard(['admin', 'moderator']), handleApproveMember);
directoryRouter.post('/moderation/member/:id/reject', roleGuard(['admin', 'moderator']), handleRejectMember);

export { directoryRouter };
