import 'package:flutter/material.dart';

class NavigationSidebar extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientSelected;
  final List<Map<String, dynamic>> patients;
  final Map<String, dynamic> currentPatient;
  final Function(String) onSearch;
  final TextEditingController searchController;

  const NavigationSidebar({
    Key? key,
    required this.onPatientSelected,
    required this.patients,
    required this.currentPatient,
    required this.onSearch,
    required this.searchController,
  }) : super(key: key);

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      color: colorScheme.surface,
      child: Column(
        children: [
          // App Logo and Title
          Container(
            padding: const EdgeInsets.all(16),
            height: 80,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'MediTrack',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: widget.searchController,
              onChanged: widget.onSearch,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Navigation Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main Menu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.people, 'Patients', 1),
                _buildNavItem(Icons.event_note, 'Appointments', 2),
                _buildNavItem(Icons.medication, 'Prescriptions', 3),
                _buildNavItem(Icons.analytics, 'Analytics', 4),
                const SizedBox(height: 24),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNavItem(Icons.settings, 'Preferences', 5),
                _buildNavItem(Icons.help, 'Help Center', 6),
              ],
            ),
          ),

          const Spacer(),

          // Patient List
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Patients',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.patients.length,
                      itemBuilder: (context, index) {
                        final patient = widget.patients[index];
                        final isSelected =
                            patient['id'] == widget.currentPatient['id'];

                        return InkWell(
                          onTap: () => widget.onPatientSelected(patient),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: patient['gender'] == 'Male'
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.pink.withOpacity(0.2),
                                  child: Text(
                                    '${patient['name'].split(' ')[0][0]}${patient['name'].split(' ')[1][0]}',
                                    style: TextStyle(
                                      color: patient['gender'] == 'Male'
                                          ? Colors.blue
                                          : Colors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${patient['age']} yrs • ${patient['condition']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                                .withOpacity(0.7)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/doctor_profile.jpg'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Emma Wilson',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Endocrinologist',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, size: 20),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientSummaryPanel extends StatelessWidget {
  final Map<String, dynamic> patient;

  const PatientSummaryPanel({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 300,
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      child: Column(
        children: [
          // Patient header with actions
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'Patient Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_note),
                  tooltip: 'Edit Patient',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More Options',
                ),
              ],
            ),
          ),

          // Patient info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient profile
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: patient['gender'] == 'Male'
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.pink.withOpacity(0.2),
                          child: Text(
                            '${patient['name'].split(' ')[0][0]}${patient['name'].split(' ')[1][0]}',
                            style: TextStyle(
                              fontSize: 24,
                              color: patient['gender'] == 'Male'
                                  ? Colors.blue
                                  : Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          patient['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${patient['condition']} • ${patient['status']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.message, size: 16),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.videocam, size: 16),
                              label: const Text('Video Call'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outline.withOpacity(0.2)),
                  const SizedBox(height: 16),

                  // Patient details section
                  Text(
                    'Patient Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow(context, 'Gender', patient['gender']),
                  _buildInfoRow(context, 'Age', '${patient['age']} years'),
                  _buildInfoRow(context, 'Blood Type', patient['bloodType']),
                  _buildInfoRow(context, 'Height', '${patient['height']} cm'),
                  _buildInfoRow(context, 'Weight', '${patient['weight']} kg'),
                  _buildInfoRow(context, 'Phone', patient['phone']),
                  _buildInfoRow(context, 'Email', patient['email']),
                  _buildInfoRow(context, 'Address', patient['address']),

                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outline.withOpacity(0.2)),
                  const SizedBox(height: 16),

                  // Medical history
                  Text(
                    'Medical History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Allergies',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              (patient['allergies'] as List).map((allergy) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                allergy,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chronic conditions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_information,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chronic Conditions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...(patient['conditions'] as List).map((condition) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  condition,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Current medications
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medication,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Medications',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...(patient['medications'] as List).map((medication) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.medication_liquid,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medication['name'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        medication['dosage'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        medication['frequency'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: colorScheme.outline.withOpacity(0.2)),
                  const SizedBox(height: 16),

                  // Upcoming appointments
                  Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Follow-up Appointment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Mar 25, 2025 • 10:30 AM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Dr. Emma Wilson',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
