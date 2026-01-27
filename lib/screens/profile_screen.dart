import 'package:flutter/material.dart';
import 'package:finflow/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = null;
      if (_isEditing) {
        // When entering edit mode, populate the controller with current name
        _fetchUserData().then((userData) {
          if (userData != null) {
            _nameController.text = userData['name'] ?? '';
          }
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': _nameController.text.trim()});

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Circle Avatar at the top
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            // Card with user information
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Error loading user data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'User data not found',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppTheme.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final userData = snapshot.data!;
                  final name = userData['name'] ?? 'No name';
                  final email = userData['email'] ?? 'No email';
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          if (_isEditing) ...[
                            // Edit Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Name cannot be empty';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (_errorMessage != null)
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : _saveProfile,
                                          child: _isSaving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text('Save'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _toggleEditMode,
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Display Mode
                            // Display Name
                            Text(
                              name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            // Email
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryLight,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Edit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _toggleEditMode,
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
