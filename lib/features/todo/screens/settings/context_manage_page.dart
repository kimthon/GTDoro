import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gtdoro/core/constants/app_sizes.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';

class ContextManagePage extends StatelessWidget {
  final ContextType category;

  const ContextManagePage({super.key, required this.category});

  // Predefined colors for the picker (moved outside for reuse)
  static const List<int> predefinedColors = [
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5,
    0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50,
    0xFF8BC34A, 0xFFCDDC39, 0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800,
    0xFFFB8C00, 0xFF795548, 0xFF9E9E9E, 0xFF607D8B,
  ];

  @override
  Widget build(BuildContext context) {
    final contextProvider = context.watch<ContextProvider>();

    // Filter items by category only
    final categoryItems = contextProvider.availableContexts
        .where((c) => c.typeCategory == category)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('${category.name.toUpperCase()} Management')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          ...categoryItems.map((ctx) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                      radius: AppSizes.r8,
                      backgroundColor: Color(ctx.colorValue)),
                  title: Text(ContextProvider.formatContextName(ctx)),
                  onTap: () => _showEditDialog(context, contextProvider, ctx), // Make ListTile tappable for edit
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      // Show confirmation dialog before deleting
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('컨텍스트 삭제'),
                          content: Text(
                              '\'${ContextProvider.formatContextName(ctx)}\' 컨텍스트를 삭제하시겠습니까?\n이 컨텍스트를 사용하는 모든 할 일에서 해당 컨텍스트가 제거됩니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Only call the context provider's method.
                                // It will handle calling the action provider internally.
                                dialogContext.read<ContextProvider>().removeContext(ctx.id);
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, contextProvider),
        child: const Icon(Icons.add),
      ),
    );
  }


  void _showAddDialog(BuildContext context, ContextProvider provider) {
    final nameController = TextEditingController();
    int selectedColorValue = predefinedColors[0]; // Default to first color

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New ${category.name}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: '컨텍스트를 입력하세요', labelText: '컨텍스트 *'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('색상 선택',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: predefinedColors.map((colorValue) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColorValue = colorValue;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColorValue == colorValue
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selectedColorValue == colorValue
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  provider.addContext(
                    name: nameController.text.trim(),
                    category: null, // category 필드는 사용하지 않음, typeCategory만 사용
                    type: category,
                    colorValue: selectedColorValue,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, ContextProvider provider, Context contextToEdit) {
    final nameController = TextEditingController(text: contextToEdit.name);
    int selectedColorValue = contextToEdit.colorValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${ContextProvider.formatContextName(contextToEdit)}'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: '컨텍스트를 입력하세요', labelText: '컨텍스트 *'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('색상 선택',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: predefinedColors.map((colorValue) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColorValue = colorValue;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColorValue == colorValue
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: selectedColorValue == colorValue
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  provider.updateContext(
                    contextToEdit.id,
                    name: nameController.text.trim(),
                    category: null, // category 필드는 사용하지 않음, typeCategory만 사용
                    colorValue: selectedColorValue,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}