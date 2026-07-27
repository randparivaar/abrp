import { Hono } from 'hono';
import { authMiddleware, roleGuard } from '../middleware/auth.js';
import { 
  handleGetVillages, 
  handleGetRegions,
  handleOnboardFamily, 
  handleAddFamilyMember, 
  handleGetFamilyTree,
  handleGetMyFamily,
  handleUpdateFamilyMember,
  handleDeleteFamilyMember,
  handleGetPendingMembers,
  handleApproveMember,
  handleRejectMember,
  handleGetPendingBusinesses,
  handleApproveBusiness,
  handleRejectBusiness,
  handleSearchMembers,
  handleGetBusinessMembers,
  handleAddBusinessMember,
  handleDeleteBusinessMember,
  handleGetMembers,
  handleGetBusinesses
} from '../controllers/directory.controller.js';

const directoryRouter = new Hono();

// All directory endpoints require authentication
directoryRouter.use('*', authMiddleware);

directoryRouter.get('/villages', handleGetVillages);
directoryRouter.get('/regions', handleGetRegions);
directoryRouter.get('/my-family', handleGetMyFamily);
directoryRouter.post('/onboard-family', handleOnboardFamily);
directoryRouter.post('/member', handleAddFamilyMember);
directoryRouter.get('/family/:familyId/tree', handleGetFamilyTree);
directoryRouter.put('/member/:id', handleUpdateFamilyMember);
directoryRouter.delete('/member/:id', handleDeleteFamilyMember);

// Global member & business directory search
directoryRouter.get('/members', handleGetMembers);
directoryRouter.get('/members/search', handleSearchMembers);
directoryRouter.get('/businesses', handleGetBusinesses);

// Business member assignments
directoryRouter.get('/business/:businessId/members', handleGetBusinessMembers);
directoryRouter.post('/business/:businessId/member', handleAddBusinessMember);
directoryRouter.delete('/business/:businessId/member/:memberId', handleDeleteBusinessMember);

// Moderation (Coordinator/Admin only)
directoryRouter.get('/moderation/pending', roleGuard(['admin', 'moderator']), handleGetPendingMembers);
directoryRouter.post('/moderation/member/:id/approve', roleGuard(['admin', 'moderator']), handleApproveMember);
directoryRouter.post('/moderation/member/:id/reject', roleGuard(['admin', 'moderator']), handleRejectMember);

directoryRouter.get('/moderation/pending-businesses', roleGuard(['admin', 'moderator']), handleGetPendingBusinesses);
directoryRouter.post('/moderation/business/:id/approve', roleGuard(['admin', 'moderator']), handleApproveBusiness);
directoryRouter.post('/moderation/business/:id/reject', roleGuard(['admin', 'moderator']), handleRejectBusiness);

export { directoryRouter };
