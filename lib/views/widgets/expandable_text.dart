import 'package:flutter/material.dart';
import 'package:paysecure/themes/themes.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';

class ExpandableText extends StatefulWidget {
  final String? text;
  final int? textWidth;
  final TextStyle? style;

  ExpandableText({
    super.key,
    this.text = "",
    this.textWidth = 10,
    this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late String firstHalf;

  @override
  void initState() {
    if (widget.text!.length > widget.textWidth!) {
      firstHalf = widget.text!.substring(0, widget.textWidth);
    } else {
      firstHalf = widget.text!;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: widget.text!.length <= widget.textWidth!
            ? Text(firstHalf,
                style: widget.style ??
                    context.t.displayMedium
                        ?.copyWith(color: AppThemes.getParagraphColor()))
            : Text(firstHalf + "...",
                style: widget.style ??
                    context.t.displayMedium
                        ?.copyWith(color: AppThemes.getParagraphColor())));
  }
}
