import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_management_provider.dart';
import '../theme/admin_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _tabs = ['All', 'Customers', 'Cooks', 'Riders', 'Admins'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> allUsers) {
    return allUsers.where((u) {
      final role = (u['role'] as String? ?? '').toLowerCase();
      final currentTab = _tabs[_tabController.index].toLowerCase();

      bool matchesTab = true;
      if (currentTab == 'customers') matchesTab = role == 'customer';
      if (currentTab == 'cooks') matchesTab = role == 'cook';
      if (currentTab == 'riders') matchesTab = role == 'rider';
      if (currentTab == 'admins') matchesTab = role == 'admin';

      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty || name.contains(query) || email.contains(query);

      return matchesTab && matchesSearch;
    }).toList();
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final isBlocked = user['isBlocked'] as bool? ?? false;
    final role = user['role'] as String? ?? 'user';
    final id = user['_id'] as String? ?? user['id'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AdminTheme.primaryLight,
                  child: Text(
                    (user['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] as String? ?? 'User',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                      ),
                      Text(
                        user['email'] as String? ?? '',
                        style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBlocked ? AdminTheme.statusRejectedBg : AdminTheme.statusApprovedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isBlocked ? 'Blocked' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _detailRow('User ID', id),
            _detailRow('Role', role.toUpperCase()),
            _detailRow('Phone', user['phone'] as String? ?? 'Not provided'),
            _detailRow('Address', user['address'] as String? ?? 'Not specified'),
            if (role == 'cook') _detailRow('Kitchen Name', user['kitchenName'] as String? ?? 'Not specified'),
            if (role == 'rider' && user['vehicleDetails'] != null)
              _detailRow('Vehicle', '${user['vehicleDetails']['type']} (${user['vehicleDetails']['plateNumber']})'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isBlocked ? AdminTheme.statusApproved : AdminTheme.statusPending,
                      side: BorderSide(color: isBlocked ? AdminTheme.statusApproved : AdminTheme.statusPending),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (isBlocked) {
                        await ref.read(userManagementProvider.notifier).unblockUser(id);
                      } else {
                        await ref.read(userManagementProvider.notifier).blockUser(id);
                      }
                    },
                    icon: Icon(isBlocked ? Icons.check_circle_outline : Icons.block, size: 18),
                    label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.statusRejected,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Delete User Account'),
                          content: Text('Are you sure you want to permanently delete "${user['name']}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.statusRejected),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(userManagementProvider.notifier).deleteUser(id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AdminTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final filteredUsers = _filterUsers(state.users);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Management',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminTheme.textPrimary),
            onPressed: () => ref.read(userManagementProvider.notifier).loadAllUsers(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AdminTheme.primary,
            indicatorWeight: 3,
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AdminTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.border)),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && state.users.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primary))
                : filteredUsers.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No users matching "$_searchQuery"' : 'No users found in this section',
                          style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final id = user['_id'] as String? ?? user['id'] as String? ?? '';
                          final isBlocked = user['isBlocked'] as bool? ?? false;
                          final role = user['role'] as String? ?? 'customer';

                          Color roleColor = AdminTheme.primary;
                          if (role == 'rider') roleColor = const Color(0xFF5E35B1);
                          if (role == 'cook') roleColor = const Color(0xFFE65100);
                          if (role == 'admin') roleColor = const Color(0xFFD81B60);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: AdminTheme.cardDecoration(),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: roleColor.withValues(alpha: 0.15),
                                  child: Text(
                                    (user['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: roleColor, fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user['name'] as String? ?? 'User',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminTheme.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: roleColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              role.toUpperCase(),
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user['email'] as String? ?? '',
                                        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isBlocked ? 'Blocked' : 'Active Account',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isBlocked ? AdminTheme.statusRejected : AdminTheme.statusApproved,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AdminTheme.textSecondary),
                                  onSelected: (choice) async {
                                    if (choice == 'view') {
                                      _showUserDetails(user);
                                    } else if (choice == 'block') {
                                      await ref.read(userManagementProvider.notifier).blockUser(id);
                                    } else if (choice == 'unblock') {
                                      await ref.read(userManagementProvider.notifier).unblockUser(id);
                                    } else if (choice == 'delete') {
                                      await ref.read(userManagementProvider.notifier).deleteUser(id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: isBlocked ? 'unblock' : 'block',
                                      child: Row(
                                        children: [
                                          Icon(isBlocked ? Icons.check_circle_outline : Icons.block, size: 18),
                                          SizedBox(width: 8),
                                          Text(isBlocked ? 'Unblock User' : 'Block User'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: AdminTheme.statusRejected),
                                          SizedBox(width: 8),
                                          Text('Delete User', style: TextStyle(color: AdminTheme.statusRejected)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
