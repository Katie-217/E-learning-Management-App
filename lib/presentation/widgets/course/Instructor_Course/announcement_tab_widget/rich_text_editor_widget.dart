import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Rich-Text Editor với Markdown support
class RichTextEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const RichTextEditorWidget({
    super.key,
    required this.controller,
    this.label = 'Content',
    this.hint,
    this.maxLines = 8,
    this.validator,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  bool _showPreview = false;

  // Markdown formatting helpers
  void _insertMarkdown(String before, String after) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (selection.start == -1) {
      // No selection, insert at end
      widget.controller.text = text + before + after;
      widget.controller.selection = TextSelection.collapsed(
        offset: text.length + before.length,
      );
    } else {
      // Has selection, wrap it
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        before + selectedText + after,
      );
      
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: selection.start + before.length + selectedText.length,
      );
    }
  }

  void _insertBold() => _insertMarkdown('**', '**');
  void _insertItalic() => _insertMarkdown('*', '*');
  void _insertUnderline() => _insertMarkdown('__', '__');
  void _insertStrikethrough() => _insertMarkdown('~~', '~~');
  void _insertCode() => _insertMarkdown('`', '`');
  
  void _insertHeading() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    
    final newText = text.replaceRange(lineStart, lineStart, '# ');
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start + 2,
    );
  }

  void _insertBulletList() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    
    final newText = text.replaceRange(lineStart, lineStart, '- ');
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start + 2,
    );
  }

  void _insertNumberedList() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    
    final newText = text.replaceRange(lineStart, lineStart, '1. ');
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: selection.start + 3,
    );
  }

  void _insertLink() {
    _insertMarkdown('[Link Text](', ')');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  'Preview',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showPreview,
                  onChanged: (value) {
                    setState(() => _showPreview = value);
                  },
                  activeColor: Colors.indigo,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Toolbar
        if (!_showPreview) _buildToolbar(),

        const SizedBox(height: 8),

        // Editor or Preview
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: _showPreview ? _buildPreview() : _buildEditor(),
        ),

        const SizedBox(height: 8),

        // Markdown Help
        if (!_showPreview)
          Text(
            'Tip: Use Markdown formatting. **bold**, *italic*, # heading, - bullet list',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _ToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold (Ctrl+B)',
            onPressed: _insertBold,
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic (Ctrl+I)',
            onPressed: _insertItalic,
          ),
          _ToolbarButton(
            icon: Icons.format_underline,
            tooltip: 'Underline',
            onPressed: _insertUnderline,
          ),
          _ToolbarButton(
            icon: Icons.strikethrough_s,
            tooltip: 'Strikethrough',
            onPressed: _insertStrikethrough,
          ),
          const VerticalDivider(width: 1, color: Colors.grey),
          _ToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading',
            onPressed: _insertHeading,
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet List',
            onPressed: _insertBulletList,
          ),
          _ToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered List',
            onPressed: _insertNumberedList,
          ),
          const VerticalDivider(width: 1, color: Colors.grey),
          _ToolbarButton(
            icon: Icons.code,
            tooltip: 'Code',
            onPressed: _insertCode,
          ),
          _ToolbarButton(
            icon: Icons.link,
            tooltip: 'Link',
            onPressed: _insertLink,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Write your content here...\n\nYou can use Markdown formatting.',
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: widget.validator,
    );
  }

  Widget _buildPreview() {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.maxLines * 24.0,
        maxHeight: 400,
      ),
      padding: const EdgeInsets.all(16),
      child: widget.controller.text.trim().isEmpty
          ? Center(
              child: Text(
                'Nothing to preview yet',
                style: TextStyle(color: Colors.grey[500]),
              ),
            )
          : Markdown(
              data: widget.controller.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 14),
                h1: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                h2: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h3: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                strong: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  color: Colors.amber[300],
                  backgroundColor: Colors.grey[900],
                  fontFamily: 'monospace',
                ),
                listBullet: const TextStyle(color: Colors.white),
              ),
              shrinkWrap: true,
            ),
    );
  }
}

// Toolbar Button Widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}