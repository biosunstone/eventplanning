import 'package:flutter/material.dart' hide BorderRadius;
import 'package:flutter/material.dart' as material;
import '../../models/event.dart';
import '../../models/website.dart';
import '../../services/website_service.dart';

class TemplateSelectorScreen extends StatefulWidget {
  final Event event;

  const TemplateSelectorScreen({super.key, required this.event});

  @override
  State<TemplateSelectorScreen> createState() => _TemplateSelectorScreenState();
}

class _TemplateSelectorScreenState extends State<TemplateSelectorScreen>
    with SingleTickerProviderStateMixin {
  final WebsiteService _websiteService = WebsiteService();
  
  List<WebsiteTemplate> _templates = [];
  List<WebsiteTemplate> _filteredTemplates = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  late TabController _tabController;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All Templates', 'icon': Icons.apps},
    {'id': 'conference', 'name': 'Conference', 'icon': Icons.business_center},
    {'id': 'workshop', 'name': 'Workshop', 'icon': Icons.build},
    {'id': 'tech', 'name': 'Tech', 'icon': Icons.computer},
    {'id': 'creative', 'name': 'Creative', 'icon': Icons.palette},
    {'id': 'corporate', 'name': 'Corporate', 'icon': Icons.corporate_fare},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      _templates = await _websiteService.getTemplates();
      _filterTemplates();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _filterTemplates() {
    if (_selectedCategory == 'all') {
      _filteredTemplates = _templates;
    } else {
      _filteredTemplates = _templates.where((template) => 
        template.category == _selectedCategory).toList();
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterTemplates();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Template'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Templates', icon: Icon(Icons.web)),
            Tab(text: 'Blank', icon: Icon(Icons.add_box)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildBlankTab(),
              ],
            ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _filteredTemplates.isEmpty
              ? _buildEmptyState()
              : _buildTemplateGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onCategoryChanged(category['id']),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[100],
                  borderRadius: material.BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(_filteredTemplates[index]);
      },
    );
  }

  Widget _buildTemplateCard(WebsiteTemplate template) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: material.BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _previewTemplate(template),
        borderRadius: material.BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const material.BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCategoryColor(template.category).withOpacity(0.1),
                      _getCategoryColor(template.category).withOpacity(0.3),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (template.preview.isNotEmpty)
                      ClipRRect(
                        borderRadius: const material.BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          template.preview,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _buildPreviewPlaceholder(template),
                        ),
                      )
                    else
                      _buildPreviewPlaceholder(template),
                    if (template.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: material.BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(template.category).withOpacity(0.1),
                            borderRadius: material.BorderRadius.circular(8),
                          ),
                          child: Text(
                            template.category.toUpperCase(),
                            style: TextStyle(
                              color: _getCategoryColor(template.category),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (template.isPremium)
                          Text(
                            '\$${template.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPlaceholder(WebsiteTemplate template) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              size: 40,
              color: _getCategoryColor(template.category),
            ),
            const SizedBox(height: 8),
            Text(
              'Preview',
              style: TextStyle(
                color: _getCategoryColor(template.category),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: material.BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
            ),
            child: const Icon(
              Icons.add,
              size: 60,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start from Scratch',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a custom website with complete creative control. Perfect for unique designs.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createBlankWebsite,
            icon: const Icon(Icons.create),
            label: const Text('Create Blank Website'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web_asset_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No templates found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'conference':
        return Colors.blue;
      case 'workshop':
        return Colors.orange;
      case 'tech':
        return Colors.purple;
      case 'creative':
        return Colors.pink;
      case 'corporate':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _previewTemplate(WebsiteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: material.BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getCategoryColor(template.category).withOpacity(0.1),
                  borderRadius: const material.BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: material.BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.web, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Template Preview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Interactive preview would be shown here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _selectTemplate(template),
                              child: Text(template.isPremium ? 'Purchase & Use' : 'Use Template'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTemplate(WebsiteTemplate template) async {
    Navigator.of(context).pop(); // Close preview dialog
    
    if (template.isPremium) {
      // Show purchase dialog for premium templates
      _showPurchaseDialog(template);
      return;
    }

    await _createWebsiteFromTemplate(template);
  }

  void _showPurchaseDialog(WebsiteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${template.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This is a premium template that costs \$${template.price.toStringAsFixed(0)}.'),
            const SizedBox(height: 16),
            const Text('Premium features include:'),
            const SizedBox(height: 8),
            ...template.tags.map((tag) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(tag),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPurchase(template);
            },
            child: Text('Purchase \$${template.price.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(WebsiteTemplate template) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing purchase...'),
          ],
        ),
      ),
    );

    // Simulate purchase processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful! Creating website...')),
      );

      await _createWebsiteFromTemplate(template);
    }
  }

  Future<void> _createWebsiteFromTemplate(WebsiteTemplate template) async {
    try {
      // Show domain selection dialog
      final domain = await _showDomainDialog();
      if (domain == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating website...'),
            ],
          ),
        ),
      );

      await _websiteService.createWebsiteFromTemplate(
        widget.event.id,
        template.id,
        domain,
        widget.event.title,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Go back to website builder
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating website: $e')),
        );
      }
    }
  }

  Future<void> _createBlankWebsite() async {
    try {
      // Show domain selection dialog
      final domain = await _showDomainDialog();
      if (domain == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating blank website...'),
            ],
          ),
        ),
      );

      // Create blank website with minimal template
      final template = _templates.first; // Use first template as base
      await _websiteService.createWebsiteFromTemplate(
        widget.event.id,
        template.id,
        domain,
        widget.event.title,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Go back to website builder
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blank website created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating website: $e')),
        );
      }
    }
  }

  Future<String?> _showDomainDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Domain'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your website will be available at:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Subdomain',
                  suffix: Text('.eventapp.com'),
                  hintText: 'my-event',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subdomain';
                  }
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                    return 'Only lowercase letters, numbers, and hyphens allowed';
                  }
                  return null;
                },
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
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.toLowerCase());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}