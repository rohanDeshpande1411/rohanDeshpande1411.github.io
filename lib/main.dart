import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (icon) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      Colors.primaries[icon.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(icon, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A dock-like widget for displaying and reordering items.
///
/// This widget allows users to drag and reorder items within it.
class Dock<T extends Object> extends StatefulWidget {
  /// Creates a [Dock].
  ///
  /// - [items] specifies the list of items to display.
  /// - [builder] is a function that builds the widget for each item.
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// The list of items displayed in the dock.
  final List<T> items;

  /// Builds a widget for each item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

class _DockState<T extends Object> extends State<Dock<T>>
    with TickerProviderStateMixin {
  late List<T> _items;
  late List<GlobalKey> _keys;
  bool _isDragging = false;
  late AnimationController _animationController;
  T? _draggedItem;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    _keys = List.generate(_items.length, (index) => GlobalKey());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Handles reordering of items when drag-and-drop occurs.
  void onDragReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_items.length, (index) {
              final T item = _items[index];
              return Draggable<T>(
                data: item,
                key: _keys[index],
                feedback: Material(
                  color: Colors.transparent,
                  child: widget.builder(item),
                ),
                childWhenDragging: const SizedBox.shrink(),
                onDragStarted: () {
                  setState(() {
                    _isDragging = true;
                    _draggedItem = item;
                  });
                },
                onDragEnd: (details) {
                  setState(() {
                    _isDragging = false;
                    _draggedItem = null;
                    if (details.wasAccepted) {
                      _animationController.forward();
                    }
                  });
                },
                onDraggableCanceled: (_, __) {
                  setState(() {
                    _isDragging = false;
                    _draggedItem = null;
                    _animationController.reverse();
                  });
                },
                child: DragTarget<T>(
                  onWillAcceptWithDetails: (details) {
                    return !_isDragging;
                  },
                  onAcceptWithDetails: (details) {
                    final int fromIndex = _items.indexOf(details.data);
                    if (fromIndex != index) {
                      onDragReorder(fromIndex, index);
                    }
                  },
                  builder: (context, candidateItems, rejectedItems) {
                    return AnimatedOpacity(
                      opacity: _isDragging && _draggedItem != item ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: widget.builder(item),
                    );
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
