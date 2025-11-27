import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';
import 'note_composer_page.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, List<Note>>(
      selector: (_, state) => state.notes,
      builder: (context, notes, _) {
        final filtered = _applyFilters(notes);

        return Scaffold(
          backgroundColor: AppColors.background, // Clean off-white background
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Custom Creative Header
                _buildHeader(filtered.length),

                // 2. Search & Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchField()),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(),
                    ],
                  ),
                ),

                // 3. Manual Masonry Layout
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: EmptyState(
                            title: 'No notes found',
                            message: 'Time to write something brilliant!',
                            icon: Icons.edit_note,
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          child: _buildMasonryGrid(filtered),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- CUSTOM MASONRY IMPLEMENTATION ---
  Widget _buildMasonryGrid(List<Note> notes) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      // Use note ID hash for stable coloring
      final colorIndex = note.noteId.hashCode.abs() % AppColors.pastels.length;
      final color = AppColors.pastels[colorIndex];

      final item = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _CreativeNoteCard(
          note: note,
          color: color,
          onTap: () => _openComposer(note),
          // Pass the edit function here
          onEdit: (n) => _openComposer(n),
          // Pass the delete function here
          onDelete: () => context.read<AppState>().deleteNote(note.noteId),
        ),
      );

      if (i % 2 == 0) {
        leftColumn.add(item);
      } else {
        rightColumn.add(item);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumn)),
        const SizedBox(width: 16),
        Expanded(child: Column(children: rightColumn)),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Notes',
                style: TextStyle(
                  fontSize: 42,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Collection of $count notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      // 1. The Shadow Layer (Outer)
      // We apply the shadow here so it sits BEHIND the border/material
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
            blurRadius: 0, // Hard shadow
          ),
        ],
      ),
      // 2. The Surface Layer (Inner)
      // Material widget handles borders and background clipping much better than Container
      child: Material(
        color: AppColors.cardSurface,
        // This defines the Border AND the Rounded Corners in one smooth shape
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        // 3. The Fix: AntiAlias creates smooth, high-quality curves
        clipBehavior: Clip.antiAlias,
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.shadow,
          ),

          // Centers text vertically relative to the icon
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: AppColors.textMain),
            hintText: 'Search...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),

            // Remove all default internal borders so they don't clash with our custom one
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,

            // Only horizontal padding needed; textAlignVertical handles the rest
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return _FilterDropdown(
      currentFilter: _filter,
      onChanged: (val) => setState(() => _filter = val),
    );
  }

  List<Note> _applyFilters(List<Note> notes) {
    final query = _searchController.text.trim().toLowerCase();
    DateTime? threshold;
    if (_filter == 'recent') {
      threshold = DateTime.now().subtract(const Duration(days: 7));
    } else if (_filter == 'month') {
      threshold = DateTime.now().subtract(const Duration(days: 30));
    }

    return notes.where((note) {
      final matchesSearch =
          query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.body.toLowerCase().contains(query);
      final matchesTime = threshold == null
          ? true
          : note.createdAt.isAfter(threshold);
      return matchesSearch && matchesTime;
    }).toList();
  }

  void _openComposer([Note? note]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteComposerPage(note: note),
        fullscreenDialog: true,
      ),
    );
  }
}

// --- NEW CREATIVE CARD UI ---

class _CreativeNoteCard extends StatelessWidget {
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(Note) onEdit; // Added callback for Edit

  const _CreativeNoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');

    return _BouncingButton(
      onTap: onTap,
      child: Stack(
        children: [
          // The "Hard Shadow" Layer
          Positioned(
            top: 6,
            left: 6,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shadow,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // The Main Card Layer
          Container(
            margin: const EdgeInsets.only(bottom: 6, right: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Date & 3-Dot Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textMain.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatter.format(note.createdAt).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      if (note.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: AppColors.textMain.withValues(alpha: 0.6),
                          ),
                        ),

                      const Spacer(),

                      // --- 3 DOT BUTTON LOGIC ---
                      Builder(
                        builder: (iconContext) {
                          return GestureDetector(
                            onTap: () {
                              // 1. Find the precise position of the icon
                              final RenderBox renderBox =
                                  iconContext.findRenderObject() as RenderBox;
                              final position = renderBox.localToGlobal(
                                Offset.zero,
                              );

                              // 2. Show custom overlay menu
                              _showCustomMenu(
                                context,
                                position,
                                onEdit,
                                onDelete,
                                note,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.more_horiz, size: 20),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Body
                  Text(
                    note.body,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({required this.currentFilter, required this.onChanged});

  String _getLabel(String value) {
    switch (value) {
      case 'recent':
        return 'Week';
      case 'month':
        return 'Month';
      case 'all':
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 48),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      itemBuilder: (context) => [
        _buildMenuItem('all', 'All'),
        _buildMenuItem('recent', 'Week'),
        _buildMenuItem('month', 'Month'),
      ],
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLabel(currentFilter),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.shadow,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.shadow,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label) {
    final isSelected = currentFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isSelected ? AppColors.textMain : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// --- CUSTOM DROPDOWN MENU LOGIC ---

void _showCustomMenu(
  BuildContext context,
  Offset position,
  Function(Note) onEdit,
  VoidCallback onDelete,
  Note note,
) {
  final rootContext = context;
  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx - 140,
      position.dy + 30,
      position.dx,
      position.dy,
    ),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.black, width: 2),
    ),
    items: <PopupMenuEntry<dynamic>>[
      PopupMenuItem(
        onTap: () {
          // Toggle Pin
          context.read<AppState>().toggleNotePin(note.noteId);
        },
        child: Row(
          children: [
            Icon(
              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
              color: AppColors.shadow,
            ),
            const SizedBox(width: 12),
            Text(
              note.isPinned ? 'Unpin' : 'Pin to Top',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.shadow,
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem(
        onTap: () => Future.delayed(Duration.zero, () => onEdit(note)),
        child: Row(
          children: const [
            Icon(Icons.edit, size: 20, color: AppColors.textMain),
            SizedBox(width: 12),
            Text(
              'Edit Note',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.shadow,
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem(
        onTap: () => Future.delayed(
          Duration.zero,
          () => ExportService().downloadPdf(note),
        ),
        child: Row(
          children: const [
            Icon(Icons.download, size: 20, color: AppColors.textMain),
            SizedBox(width: 12),
            Text(
              'Download',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.shadow,
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
      PopupMenuItem(
        onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDeleteDialog(rootContext, onDelete, note);
        }),
        child: Row(
          children: const [
            Icon(Icons.delete_outline, size: 20, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

void _showDeleteDialog(BuildContext context, VoidCallback onDelete, Note note) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever, size: 40, color: AppColors.shadow),
            const SizedBox(height: 12),
            const Text(
              'Delete Note?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.shadow,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove this note?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.textMain,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Text(
                        'Delete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// --- ANIMATION HELPER ---

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncingButton({required this.child, required this.onTap});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
