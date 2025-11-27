import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';

class NoteComposerPage extends StatefulWidget {
  const NoteComposerPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteComposerPage> createState() => _NoteComposerPageState();
}

class _NoteComposerPageState extends State<NoteComposerPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late bool _isEditing;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    // If it's a new note (widget.note is null), start in editing mode.
    // Otherwise, start in view mode.
    _isEditing = widget.note == null;

    _titleController.addListener(_checkForChanges);
    _bodyController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final originalTitle = widget.note?.title ?? '';
    final originalBody = widget.note?.body ?? '';
    final currentTitle = _titleController.text;
    final currentBody = _bodyController.text;

    final hasChanges =
        currentTitle != originalTitle || currentBody != originalBody;

    if (_hasUnsavedChanges != hasChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkForChanges);
    _bodyController.removeListener(_checkForChanges);
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    // If empty, just pop (or maybe we should allow saving empty notes?
    // The original logic popped if empty. Let's keep it safe.)
    if (title.isEmpty && body.isEmpty) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    final appState = context.read<AppState>();
    if (widget.note == null) {
      await appState.addNote(
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
      );
    } else {
      await appState.updateNote(
        widget.note!.copyWith(
          title: title.isEmpty ? 'Untitled' : title,
          body: body,
        ),
      );
    }

    if (mounted) {
      // If it was a new note, we might want to close or switch to view mode.
      // Usually "Save" implies "Done". Let's pop to return to list.
      Navigator.of(context).pop();
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
    if (_isEditing) {
      // Small delay to let UI build before focusing
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _bodyFocusNode.requestFocus();
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.save_as, size: 40, color: Colors.black),
              const SizedBox(height: 12),
              const Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. Do you want to save them?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true), // Discard
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Text(
                          'Discard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(false); // Cancel pop
                        _save(); // Save and then pop manually in _save
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Text(
                          'Save',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.note?.createdAt ?? DateTime.now();
    final dateLabel = DateFormat('MMMM d, yyyy').format(date);
    final timeLabel = DateFormat('h:mm a').format(date);

    // Access the keyboard height to ensure scrolling visibility
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA), // Clean off-white
        body: SafeArea(
          child: Column(
            children: [
              // 1. Custom Navigation Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Back Button
                    _NeuButton(
                      onTap: () async {
                        if (_hasUnsavedChanges) {
                          final shouldPop = await _onWillPop();
                          if (shouldPop && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      _isEditing ? 'Editing' : 'Viewing',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const Spacer(),

                    // Action Button (Edit or Save)
                    _NeuButton(
                      onTap: _isEditing ? _save : _toggleEdit,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Writing Canvas (The "Paper")
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.zero, // Full width
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    // REMOVED BORDER RADIUS & SHADOW as requested
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        bottomPadding + 40,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Sticker
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE0BBE4,
                                  ).withValues(alpha: 0.3), // Subtle Lavender
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$dateLabel • $timeLabel',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Title Area
                          if (_isEditing)
                            TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              enableInteractiveSelection:
                                  true, // Enable copy/paste
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.black,
                                letterSpacing: -1,
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'Title goes here...',
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  fontWeight: FontWeight.w900,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                              ),
                              onSubmitted: (_) => _bodyFocusNode.requestFocus(),
                            )
                          else
                            SelectableText(
                              _titleController.text.isEmpty
                                  ? 'Untitled'
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                color: Colors.black,
                                letterSpacing: -1,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Decorative Divider
                          CustomPaint(
                            painter: _DashedLinePainter(),
                            size: const Size(double.infinity, 2),
                          ),

                          const SizedBox(height: 24),

                          // Body Area
                          if (_isEditing)
                            TextField(
                              controller: _bodyController,
                              focusNode: _bodyFocusNode,
                              enableInteractiveSelection:
                                  true, // Enable copy/paste
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Start typing your masterpiece...',
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                                fillColor: Colors.transparent,
                              ),
                            )
                          else
                            SelectableText(
                              _bodyController.text.isEmpty
                                  ? 'No content...'
                                  : _bodyController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE NEO-BRUTALISM BUTTON ---
class _NeuButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const _NeuButton({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor,
  });

  @override
  State<_NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<_NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        padding: widget.padding,
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: _isPressed
              ? [] // No shadow when pressed (creates physical "press" effect)
              : [
                  const BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR DASHED LINE ---
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 5;
    const dashSpace = 5;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
