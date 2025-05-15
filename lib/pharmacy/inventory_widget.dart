// inventory_widgets.dart
import 'package:doctordesktop/pharmacy/getInventoryModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// A reusable card for displaying inventory items
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InventoryItemCard({
    Key? key,
    required this.item,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExpiringSoon =
        item.expiryDate.difference(DateTime.now()).inDays < 30;
    final expiryColor = isExpiringSoon ? Colors.red : Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.medicine.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Manufacturer',
                    item.medicine.manufacturer,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Category',
                    item.medicine.category,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Batch',
                    item.batchNumber,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Expiry',
                    DateFormat('dd/MM/yyyy').format(item.expiryDate),
                    valueColor: expiryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Quantity',
                    item.quantity.toString(),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Price',
                    '₹${item.medicine.mrp}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              'Distributor',
              item.distributor.name,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// A custom text form field with consistent styling
class CustomTextFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const CustomTextFormField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// A date picker form field
class DatePickerFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerFormField({
    Key? key,
    required this.label,
    required this.controller,
    this.validator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      label: label,
      controller: controller,
      validator: validator,
      readOnly: true,
      suffixIcon: const Icon(Icons.calendar_today),
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime initialDateTime = initialDate ?? now;
        final DateTime firstDateTime = firstDate ?? now;
        final DateTime lastDateTime = lastDate ?? DateTime(now.year + 5);

        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDateTime,
          firstDate: firstDateTime,
          lastDate: lastDateTime,
        );

        if (pickedDate != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      },
    );
  }
}

// A dropdown for selecting predefined options
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String? hint;

  const CustomDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          isExpanded: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Custom button with loading state
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.onActionPressed,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Error state widget
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Responsive grid layout
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;

  const ResponsiveGridView({
    Key? key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minItemWidth = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemsPerRow = (width / (minItemWidth + spacing)).floor();
        final crossAxisCount = itemsPerRow > 0 ? itemsPerRow : 1;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
          ),
          itemCount: children.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

// Search bar with clear button
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final String hintText;
  final bool showClearButton;
  final FocusNode? focusNode;

  const SearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
    this.showClearButton = true,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClearButton && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear();
                },
              )
            : null,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Confirmation dialog
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color? confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: confirmColor,
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return result ?? false;
}

// Show a snackbar
void showSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: duration,
    ),
  );
}

// Status badge
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;

  const StatusBadge({
    Key? key,
    required this.text,
    required this.color,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Custom data table
class ResponsiveDataTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> data;
  final List<Widget> Function(T item, int index) cellBuilder;
  final void Function(T item)? onRowTap;
  final bool showHeader;
  final bool isLoading;

  const ResponsiveDataTable({
    Key? key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.onRowTap,
    this.showHeader = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          // Card-style list for mobile
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final cells = cellBuilder(item, index);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: onRowTap != null ? () => onRowTap!(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < columns.length; i++)
                          if (i < cells.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      columns[i],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: cells[i]),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          // Table-style for tablet/desktop
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns
                  .map((column) => DataColumn(
                        label: Text(
                          column,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
              rows: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final cells = cellBuilder(item, index);

                return DataRow(
                  onSelectChanged:
                      onRowTap != null ? (_) => onRowTap!(item) : null,
                  cells: cells.map((cell) => DataCell(cell)).toList(),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
}

// Mobile responsive scaffold
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final bool showBackButton;
  final Widget? leading;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBarBottom;

  const ResponsiveScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.showBackButton = false,
    this.leading,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.appBarBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: showBackButton
            ? leading ??
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
            : leading,
        bottom: appBarBottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

// Shortcut key helper
class ShortcutHelper {
  static Map<ShortcutActivator, Intent> createShortcuts(
      Map<ShortcutActivator, VoidCallback> shortcuts) {
    final Map<ShortcutActivator, Intent> result = {};

    for (final entry in shortcuts.entries) {
      result[entry.key] = VoidCallbackIntent(entry.value);
    }

    return result;
  }
}

// Custom Intent for callbacks
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;

  const VoidCallbackIntent(this.callback);
}

// Helper function to add keyboard shortcuts
void addKeyboardShortcuts(
    BuildContext context, Map<ShortcutActivator, VoidCallback> shortcuts) {
// Helper function to wrap a widget with keyboard shortcuts
  Widget addKeyboardShortcuts(BuildContext context, Widget child,
      Map<ShortcutActivator, VoidCallback> shortcuts) {
    final Map<ShortcutActivator, Intent> shortcutMap = {};

    for (final entry in shortcuts.entries) {
      shortcutMap[entry.key] = VoidCallbackIntent(entry.value);
    }

    return Shortcuts(
      shortcuts: shortcutMap,
      child: Actions(
        actions: <Type, Action<Intent>>{
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: child,
      ),
    );
  }
}
