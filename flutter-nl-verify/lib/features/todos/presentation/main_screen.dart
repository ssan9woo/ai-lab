import 'package:flutter/material.dart';

import '../data/default_todos.dart';
import '../domain/todo_item.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.email});

  final String email;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<TodoItem> _items = createDefaultTodos();

  void _toggleTodo(int index, bool? value) {
    setState(() => _items[index].isCompleted = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할 일 목록')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '환영합니다, ${widget.email}',
              key: const Key('welcome_message'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              key: const Key('todo_list'),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  key: Key('todo_item_$index'),
                  leading: Checkbox(
                    key: Key('todo_checkbox_$index'),
                    value: item.isCompleted,
                    onChanged: (value) => _toggleTodo(index, value),
                  ),
                  title: Text(
                    item.title,
                    key: Key('todo_title_$index'),
                    style: TextStyle(
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  onTap: () => _toggleTodo(index, !item.isCompleted),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
