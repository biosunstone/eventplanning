const express = require('express');
const { body } = require('express-validator');
const adminController = require('../controllers/admin.controller');
const { protect, adminOnly, ownerOnly, requirePermission } = require('../middleware/auth');

const router = express.Router();

// All admin routes require authentication and admin privileges
router.use(protect);
router.use(adminOnly);

// Dashboard and Analytics
router.get('/dashboard/stats', adminController.getDashboardStats);
router.get('/dashboard/system-health', adminController.getSystemHealth);
router.get('/analytics/overview', adminController.getAnalyticsOverview);
router.get('/analytics/events', adminController.getEventAnalytics);
router.get('/analytics/users', adminController.getUserAnalytics);
router.get('/analytics/revenue', adminController.getRevenueAnalytics);

// Admin User Management (Owner only)
router.get('/admins', requirePermission('createAdmins'), adminController.getAllAdmins);
router.post('/admins', 
  requirePermission('createAdmins'),
  [
    body('username').trim().isLength({ min: 3 }),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('name').trim().isLength({ min: 2 }),
    body('role').isIn(['owner', 'user']),
  ],
  adminController.createAdmin
);
router.get('/admins/:id', requirePermission('createAdmins'), adminController.getAdminById);
router.put('/admins/:id', 
  requirePermission('createAdmins'),
  [
    body('email').optional().isEmail().normalizeEmail(),
    body('name').optional().trim().isLength({ min: 2 }),
    body('role').optional().isIn(['owner', 'user']),
  ],
  adminController.updateAdmin
);
router.delete('/admins/:id', requirePermission('createAdmins'), adminController.deleteAdmin);

// User Management
router.get('/users', requirePermission('manageUsers'), adminController.getAllUsers);
router.get('/users/:id', requirePermission('manageUsers'), adminController.getUserById);
router.put('/users/:id', requirePermission('manageUsers'), adminController.updateUser);
router.delete('/users/:id', requirePermission('deleteData'), adminController.deleteUser);
router.put('/users/:id/activate', requirePermission('manageUsers'), adminController.activateUser);
router.put('/users/:id/deactivate', requirePermission('manageUsers'), adminController.deactivateUser);

// Event Management
router.get('/events', requirePermission('manageEvents'), adminController.getAllEvents);
router.get('/events/:id', requirePermission('manageEvents'), adminController.getEventById);
router.put('/events/:id', requirePermission('manageEvents'), adminController.updateEvent);
router.delete('/events/:id', requirePermission('deleteData'), adminController.deleteEvent);
router.put('/events/:id/approve', requirePermission('manageEvents'), adminController.approveEvent);
router.put('/events/:id/reject', requirePermission('manageEvents'), adminController.rejectEvent);
router.get('/events/:id/attendees', requirePermission('manageEvents'), adminController.getEventAttendees);

// Content Moderation
router.get('/moderation/posts', requirePermission('moderateContent'), adminController.getPendingPosts);
router.put('/moderation/posts/:id/approve', requirePermission('moderateContent'), adminController.approvePost);
router.put('/moderation/posts/:id/reject', requirePermission('moderateContent'), adminController.rejectPost);
router.get('/moderation/reports', requirePermission('moderateContent'), adminController.getReports);
router.put('/moderation/reports/:id/resolve', requirePermission('moderateContent'), adminController.resolveReport);

// System Settings (Owner only)
router.get('/settings', ownerOnly, adminController.getSystemSettings);
router.put('/settings', ownerOnly, adminController.updateSystemSettings);

// Backup and Maintenance (Owner only)
router.post('/backup/create', ownerOnly, adminController.createBackup);
router.get('/backup/list', ownerOnly, adminController.listBackups);
router.post('/backup/restore/:id', ownerOnly, adminController.restoreBackup);

// System Logs (Owner only)
router.get('/logs', ownerOnly, adminController.getSystemLogs);

module.exports = router;