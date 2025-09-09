import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/event.dart';
import '../../models/attendee_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateProfileScreen extends StatefulWidget {
  final Event event;
  final AttendeeProfile? existingProfile;

  const CreateProfileScreen({
    super.key,
    required this.event,
    this.existingProfile,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _twitterController = TextEditingController();
  final _websiteController = TextEditingController();

  // Profile Settings
  ProfessionalLevel? _selectedLevel;
  List<String> _interests = [];
  List<String> _skills = [];
  bool _isPublic = true;
  bool _allowNetworking = true;
  bool _allowMessages = true;
  String? _profileImagePath;
  bool _isLoading = false;

  // Predefined options
  final List<String> _commonInterests = [
    'Technology', 'AI/ML', 'Mobile Development', 'Web Development',
    'Data Science', 'Cloud Computing', 'Cybersecurity', 'Blockchain',
    'IoT', 'DevOps', 'UX/UI Design', 'Product Management',
    'Digital Marketing', 'Entrepreneurship', 'Startups', 'Innovation',
    'Sustainability', 'Healthcare', 'Education', 'Finance',
    'Gaming', 'Sports', 'Music', 'Travel', 'Photography', 'Art'
  ];

  final List<String> _commonSkills = [
    'Flutter', 'React', 'Python', 'JavaScript', 'Java', 'Swift',
    'Kotlin', 'Node.js', 'AWS', 'Azure', 'Docker', 'Kubernetes',
    'Machine Learning', 'Data Analysis', 'Project Management',
    'Leadership', 'Public Speaking', 'Team Management',
    'Strategic Planning', 'Business Development', 'Sales',
    'Marketing', 'Content Creation', 'Social Media', 'SEO'
  ];

  bool get _isEditing => widget.existingProfile != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateExistingProfile();
    }
  }

  void _populateExistingProfile() {
    final profile = widget.existingProfile!;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone ?? '';
    _companyController.text = profile.company ?? '';
    _jobTitleController.text = profile.jobTitle ?? '';
    _departmentController.text = profile.department ?? '';
    _industryController.text = profile.industry ?? '';
    _locationController.text = profile.location ?? '';
    _cityController.text = profile.city ?? '';
    _countryController.text = profile.country ?? '';
    _bioController.text = profile.bio ?? '';
    _linkedInController.text = profile.linkedInUrl ?? '';
    _twitterController.text = profile.twitterHandle ?? '';
    _websiteController.text = profile.website ?? '';
    
    _selectedLevel = profile.professionalLevel;
    _interests = List.from(profile.interests);
    _skills = List.from(profile.skills);
    _isPublic = profile.isPublic;
    _allowNetworking = profile.allowNetworking;
    _allowMessages = profile.allowMessages;
    _profileImagePath = profile.profileImage;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = AttendeeProfile(
        id: _isEditing ? widget.existingProfile!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user1', // Get from auth provider in real app
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        profileImage: _profileImagePath,
        company: _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
        jobTitle: _jobTitleController.text.trim().isNotEmpty ? _jobTitleController.text.trim() : null,
        department: _departmentController.text.trim().isNotEmpty ? _departmentController.text.trim() : null,
        professionalLevel: _selectedLevel,
        industry: _industryController.text.trim().isNotEmpty ? _industryController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        interests: _interests,
        skills: _skills,
        linkedInUrl: _linkedInController.text.trim().isNotEmpty ? _linkedInController.text.trim() : null,
        twitterHandle: _twitterController.text.trim().isNotEmpty ? _twitterController.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        isPublic: _isPublic,
        allowNetworking: _allowNetworking,
        allowMessages: _allowMessages,
        createdAt: _isEditing ? widget.existingProfile!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _profileService.updateProfile(profile);
      } else {
        await _profileService.createProfile(profile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Profile updated successfully' : 'Profile created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _showInterestsPicker() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Interests',
        options: _commonInterests,
        selectedOptions: _interests,
        onSelectionChanged: (selected) {
          setState(() {
            _interests = selected;
          });
        },
      ),
    );
  }

  void _showSkillsPicker() {
    showDialog(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Skills',
        options: _commonSkills,
        selectedOptions: _skills,
        onSelectionChanged: (selected) {
          setState(() {
            _skills = selected;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Create Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImageSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildProfessionalInfoSection(),
              const SizedBox(height: 24),
              _buildInterestsAndSkillsSection(),
              const SizedBox(height: 24),
              _buildSocialLinksSection(),
              const SizedBox(height: 24),
              _buildPrivacySettingsSection(),
              const SizedBox(height: 32),
              CustomButton(
                text: _isEditing ? 'Update Profile' : 'Create Profile',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.update : Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: _profileImagePath != null
                  ? ClipOval(
                      child: Image.network(
                        _profileImagePath!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 60, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_camera),
            label: Text(_profileImagePath != null ? 'Change Photo' : 'Add Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                labelText: 'First Name',
                prefixIcon: Icons.person,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                labelText: 'Last Name',
                prefixIcon: Icons.person,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty == true) return 'Required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Invalid email format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          labelText: 'Phone (optional)',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _bioController,
          labelText: 'Bio (optional)',
          hintText: 'Tell others about yourself...',
          prefixIcon: Icons.info,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _companyController,
          labelText: 'Company (optional)',
          prefixIcon: Icons.business,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _jobTitleController,
                labelText: 'Job Title (optional)',
                prefixIcon: Icons.work,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _departmentController,
                labelText: 'Department (optional)',
                prefixIcon: Icons.apartment,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProfessionalLevel>(
          value: _selectedLevel,
          decoration: InputDecoration(
            labelText: 'Professional Level',
            prefixIcon: const Icon(Icons.trending_up),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: ProfessionalLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(_getProfessionalLevelName(level)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedLevel = value),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _industryController,
          labelText: 'Industry (optional)',
          prefixIcon: Icons.domain,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cityController,
                labelText: 'City (optional)',
                prefixIcon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _countryController,
                labelText: 'Country (optional)',
                prefixIcon: Icons.flag,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestsAndSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests & Skills',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Interests (${_interests.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton(
                      onPressed: _showInterestsPicker,
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _interests.isEmpty
                    ? const Text('No interests selected', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            onDeleted: () {
                              setState(() {
                                _interests.remove(interest);
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skills (${_skills.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton(
                      onPressed: _showSkillsPicker,
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _skills.isEmpty
                    ? const Text('No skills selected', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            onDeleted: () {
                              setState(() {
                                _skills.remove(skill);
                              });
                            },
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Links',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _linkedInController,
          labelText: 'LinkedIn URL (optional)',
          prefixIcon: Icons.link,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _twitterController,
          labelText: 'Twitter Handle (optional)',
          hintText: '@username',
          prefixIcon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _websiteController,
          labelText: 'Website (optional)',
          prefixIcon: Icons.language,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildPrivacySettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Public Profile'),
                  subtitle: const Text('Allow others to see your profile'),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
                SwitchListTile(
                  title: const Text('Allow Networking'),
                  subtitle: const Text('Appear in networking recommendations'),
                  value: _allowNetworking,
                  onChanged: (value) => setState(() => _allowNetworking = value),
                ),
                SwitchListTile(
                  title: const Text('Allow Messages'),
                  subtitle: const Text('Let others send you direct messages'),
                  value: _allowMessages,
                  onChanged: (value) => setState(() => _allowMessages = value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getProfessionalLevelName(ProfessionalLevel level) {
    switch (level) {
      case ProfessionalLevel.student:
        return 'Student';
      case ProfessionalLevel.junior:
        return 'Junior';
      case ProfessionalLevel.mid:
        return 'Mid-level';
      case ProfessionalLevel.senior:
        return 'Senior';
      case ProfessionalLevel.executive:
        return 'Executive';
      case ProfessionalLevel.cLevel:
        return 'C-Level';
      case ProfessionalLevel.founder:
        return 'Founder';
    }
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(List<String>) onSelectionChanged;

  const _MultiSelectDialog({
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onSelectionChanged,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selectedOptions;
  final _searchController = TextEditingController();
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.selectedOptions);
    _filteredOptions = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      _filteredOptions = widget.options
          .where((option) => option.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterOptions,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredOptions.length,
                itemBuilder: (context, index) {
                  final option = _filteredOptions[index];
                  return CheckboxListTile(
                    title: Text(option),
                    value: _selectedOptions.contains(option),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedOptions.add(option);
                        } else {
                          _selectedOptions.remove(option);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSelectionChanged(_selectedOptions);
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}