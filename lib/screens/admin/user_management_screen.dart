import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_user.dart';
import '../../services/admin_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  List<AdminUser> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdmins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() => _isLoading = true);
    
    try {
      final admins = await _adminService.getAllAdmins();
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admins: $e')),
        );
      }
    }
  }

  void _showCreateAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateAdminDialog(
        onCreated: () {
          _loadAdmins();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditAdminDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => EditAdminDialog(
        admin: admin,
        onUpdated: () {
          _loadAdmins();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _confirmDeleteAdmin(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete ${admin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteAdmin(admin.username);
                _loadAdmins();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting admin: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final canManageAdmins = adminProvider.currentAdmin?.hasPermission(AdminPermissions.createAdmins) ?? false;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Admin Users', icon: Icon(Icons.admin_panel_settings)),
                Tab(text: 'App Users', icon: Icon(Icons.people)),
                Tab(text: 'User Analytics', icon: Icon(Icons.analytics)),
              ],
            ),
            actions: [
              if (canManageAdmins)
                IconButton(
                  onPressed: _showCreateAdminDialog,
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Admin',
                ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAdminUsersTab(canManageAdmins),
              _buildAppUsersTab(),
              _buildUserAnalyticsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminUsersTab(bool canManageAdmins) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAdmins,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _admins.length,
        itemBuilder: (context, index) {
          final admin = _admins[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: admin.role == AdminRole.owner 
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                child: Icon(
                  admin.role == AdminRole.owner 
                      ? Icons.star 
                      : Icons.admin_panel_settings,
                  color: admin.role == AdminRole.owner 
                      ? Colors.purple 
                      : Colors.blue,
                ),
              ),
              title: Text(
                admin.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(admin.email),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: admin.role == AdminRole.owner 
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      admin.roleDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: admin.role == AdminRole.owner 
                            ? Colors.purple[700]
                            : Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: canManageAdmins ? PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => Future.delayed(
                      const Duration(milliseconds: 100),
                      () => _showEditAdminDialog(admin),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      dense: true,
                    ),
                  ),
                  if (admin.username != 'admin') // Prevent deleting main admin
                    PopupMenuItem(
                      onTap: () => Future.delayed(
                        const Duration(milliseconds: 100),
                        () => _confirmDeleteAdmin(admin),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        dense: true,
                      ),
                    ),
                ],
              ) : null,
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppUsersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('App User Management'),
          SizedBox(height: 8),
          Text(
            'Feature coming soon - manage regular app users',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('User Analytics'),
          SizedBox(height: 8),
          Text(
            'Feature coming soon - user behavior analytics',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class CreateAdminDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateAdminDialog({super.key, required this.onCreated});

  @override
  State<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  AdminRole _selectedRole = AdminRole.user;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminService().createAdmin(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin created successfully')),
        );
        widget.onCreated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating admin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Admin User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _usernameController,
                labelText: 'Username',
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6 ? 'Minimum 6 characters' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.contains('@') != true ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdminRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: AdminRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role == AdminRole.owner ? 'Owner Admin' : 'User Admin'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Create Admin',
          isLoading: _isLoading,
          onPressed: _createAdmin,
        ),
      ],
    );
  }
}

class EditAdminDialog extends StatefulWidget {
  final AdminUser admin;
  final VoidCallback onUpdated;

  const EditAdminDialog({super.key, required this.admin, required this.onUpdated});

  @override
  State<EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends State<EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late AdminRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.admin.email);
    _nameController = TextEditingController(text: widget.admin.name);
    _selectedRole = widget.admin.role;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedAdmin = widget.admin.copyWith(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        permissions: _selectedRole == AdminRole.owner 
            ? AdminPermissions.ownerPermissions 
            : AdminPermissions.userAdminPermissions,
      );

      await AdminService().updateAdmin(updatedAdmin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin updated successfully')),
        );
        widget.onUpdated();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating admin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.admin.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value?.contains('@') != true ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (widget.admin.username != 'admin') // Don't allow changing main admin role
                DropdownButtonFormField<AdminRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: AdminRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role == AdminRole.owner ? 'Owner Admin' : 'User Admin'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Update Admin',
          isLoading: _isLoading,
          onPressed: _updateAdmin,
        ),
      ],
    );
  }
}