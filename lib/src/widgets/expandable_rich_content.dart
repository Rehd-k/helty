import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:helty/src/helper/quill_content_helper.dart';

/// Collapsed preview with ellipsis, inline read more/less, and modal on tap.
class ExpandableRichContent extends StatefulWidget {
  const ExpandableRichContent({
    super.key,
    required this.content,
    this.modalTitle = 'Nursing Report',
    this.previewMaxLines = 3,
    this.style,
  });

  final String content;
  final String modalTitle;
  final int previewMaxLines;
  final TextStyle? style;

  @override
  State<ExpandableRichContent> createState() => _ExpandableRichContentState();
}

class _ExpandableRichContentState extends State<ExpandableRichContent> {
  bool _expanded = false;

  String get _plainPreview => plainTextFromStoredContent(widget.content);

  bool get _hasContent => _plainPreview.isNotEmpty;

  bool get _isRich => isQuillDeltaJson(widget.content);

  bool get _needsTruncation {
    if (!_hasContent) return false;
    final lines = _plainPreview.split('\n');
    return lines.length > widget.previewMaxLines ||
        _plainPreview.length > widget.previewMaxLines * 48;
  }

  void _openModal() {
    if (!_hasContent) return;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.7,
              maxHeight: size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.modalTitle,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _FullContentBody(
                      content: widget.content,
                      style: widget.style,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) {
      return Text(
        '—',
        style: widget.style ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _needsTruncation || _isRich ? _openModal : null,
          borderRadius: BorderRadius.circular(4),
          child: _expanded
              ? _FullContentBody(
                  content: widget.content,
                  style: widget.style,
                )
              : Text(
                  _plainPreview,
                  maxLines: widget.previewMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
                ),
        ),
        if (_needsTruncation)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_expanded ? 'Read less' : 'Read more'),
          ),
      ],
    );
  }
}

class _FullContentBody extends StatefulWidget {
  const _FullContentBody({
    required this.content,
    this.style,
  });

  final String content;
  final TextStyle? style;

  @override
  State<_FullContentBody> createState() => _FullContentBodyState();
}

class _FullContentBodyState extends State<_FullContentBody> {
  QuillController? _controller;

  @override
  void initState() {
    super.initState();
    if (isQuillDeltaJson(widget.content)) {
      _controller = quillControllerFromStoredContent(widget.content);
      _controller!.readOnly = true;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      return QuillEditor.basic(
        controller: _controller!,
        config: const QuillEditorConfig(
          showCursor: false,
          padding: EdgeInsets.zero,
        ),
      );
    }

    return Text(
      plainTextFromStoredContent(widget.content),
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
