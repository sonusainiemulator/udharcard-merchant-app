library custom_searchable_dropdown;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:paysecure/views/widgets/text_theme_extension.dart';
import '../../config/app_colors.dart';

// ignore: must_be_immutable
class CustomSearchableDropDown extends StatefulWidget {
  List items = [];
  List? initialValue;
  double? searchBarHeight;
  Color? primaryColor;
  Color? backgroundColor;
  Color? dropdownBackgroundColor;
  EdgeInsetsGeometry? padding;
  EdgeInsetsGeometry? menuPadding;
  String? label;
  String? dropdownHintText;
  TextStyle? labelStyle;
  TextStyle? dropdownItemStyle;
  String? hint = '';
  String? multiSelectTag;
  int? initialIndex;
  Widget? prefixIcon;
  Widget? suffixIcon;
  bool? hideSearch;
  bool? enabled;
  bool? showClearButton;
  bool? menuMode;
  double? menuHeight;
  bool? multiSelect;
  bool? multiSelectValuesAsWidget;
  bool? showLabelInMenu;
  String? itemOnDialogueBox;
  Decoration? decoration;
  List dropDownMenuItems = [];
  final TextAlign? labelAlign;
  final ValueChanged onChanged;
  TextStyle? textStyle;
  TextStyle? hintStyle;

  CustomSearchableDropDown({
    required this.items,
    required this.label,
    required this.onChanged,
    this.hint,
    this.initialValue,
    this.labelAlign,
    this.searchBarHeight,
    this.primaryColor,
    this.padding,
    this.menuPadding,
    this.labelStyle,
    this.enabled,
    this.showClearButton,
    this.itemOnDialogueBox,
    required this.dropDownMenuItems,
    this.prefixIcon,
    this.suffixIcon,
    this.menuMode,
    this.menuHeight,
    this.initialIndex,
    this.multiSelect,
    this.multiSelectTag,
    this.multiSelectValuesAsWidget,
    this.hideSearch,
    this.decoration,
    this.showLabelInMenu,
    this.dropdownItemStyle,
    this.backgroundColor,
    this.dropdownBackgroundColor,
    this.dropdownHintText,
    this.textStyle,
    this.hintStyle,
  });

  @override
  _CustomSearchableDropDownState createState() =>
      _CustomSearchableDropDownState();
}

class _CustomSearchableDropDownState extends State<CustomSearchableDropDown>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  String onSelectLabel = '';
  final searchC = TextEditingController();
  List menuData = [];
  List mainDataListGroup = [];
  List newDataList = [];

  List selectedValues = [];

  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialIndex != null && widget.dropDownMenuItems.isNotEmpty) {
      onSelectLabel = widget.dropDownMenuItems[widget.initialIndex!].toString();
    }

    if (widget.multiSelect ?? false) {
      if (selectedValues.isEmpty) {
        if (widget.initialValue != null && widget.items.isNotEmpty) {
          if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
            selectedValues.clear();
          }

          for (int i = 0; i < widget.items.length; i++) {
            for (int j = 0; j < widget.initialValue!.length; j++) {
              if (widget.initialValue != null &&
                  widget.initialValue!.isNotEmpty) {
                if (widget.initialValue![j]['value'] ==
                    widget.items[i][widget.initialValue![j]['parameter']]) {
                  selectedValues.add(widget.dropDownMenuItems[i].toString() +
                      '-_-' +
                      i.toString());
                  setState(() {});
                }
              }
            }
          }
        }
      }
    } else {
      if (onSelectLabel == '') {
        if (widget.initialValue != null && widget.items.isNotEmpty) {
          for (int i = 0; i < widget.items.length; i++) {
            if (widget.initialValue != null &&
                widget.initialValue!.isNotEmpty) {
              if (widget.initialValue![0]['value'] ==
                  widget.items[i][widget.initialValue![0]['parameter']]) {
                onSelectLabel = widget.dropDownMenuItems[i].toString();
                setState(() {});
              }
            }
          }
        }
      }
    }

    if (widget.items.isEmpty) {
      onSelectLabel = '';
      selectedValues.clear();
      widget.onChanged(null);
      setState(() {});
    }
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 48.h,
              decoration: widget.decoration,
              child: TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: widget.backgroundColor,
                    foregroundColor: widget.primaryColor ?? Colors.black,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Padding(
                  padding: widget.padding ?? EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      widget.prefixIcon ?? Container(),
                      ((widget.multiSelect == true &&
                                  widget.multiSelect != null) &&
                              selectedValues.isNotEmpty)
                          ? Expanded(
                              child: (widget.multiSelectValuesAsWidget ==
                                          true &&
                                      widget.multiSelectValuesAsWidget != null)
                                  ? Wrap(
                                      children: List.generate(
                                        selectedValues.length,
                                        (index) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 3, 5, 3),
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                  color: widget.primaryColor ??
                                                      Colors.green,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(5.0),
                                                  )),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        5, 2, 5, 2),
                                                child: Text(
                                                  selectedValues[index]
                                                      .split('-_-')[0]
                                                      .toString(),
                                                  style: widget.labelStyle ??
                                                      TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Text(
                                      selectedValues.length == 1
                                          ? widget.multiSelectTag == null
                                              ? selectedValues.length
                                                      .toString() +
                                                  ' values selected'
                                              : selectedValues.length
                                                      .toString() +
                                                  ' ' +
                                                  widget.multiSelectTag! +
                                                  ' selected'
                                          : widget.multiSelectTag == null
                                              ? selectedValues.length
                                                      .toString() +
                                                  ' values selected'
                                              : selectedValues.length
                                                      .toString() +
                                                  ' ' +
                                                  widget.multiSelectTag! +
                                                  ' selected',
                                      style: widget.labelStyle ??
                                          TextStyle(color: Colors.grey),
                                    ))
                          : Expanded(
                              child: Text(
                              onSelectLabel == ''
                                  ? widget.label == null
                                      ? 'Select Value'
                                      : widget.label!
                                  : onSelectLabel,
                              textAlign: widget.labelAlign ?? TextAlign.start,
                              style: widget.labelStyle != null
                                  ? widget.labelStyle!.copyWith(
                                      color: onSelectLabel == ''
                                          ? Colors.grey[600]
                                          : null,
                                    )
                                  : TextStyle(
                                      color: onSelectLabel == ''
                                          ? Colors.grey[600]
                                          : Colors.grey[800],
                                    ),
                            )),
                      Visibility(
                          visible: (widget.showClearButton != null &&
                              widget.showClearButton == true),
                          child: TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor:
                                    widget.primaryColor ?? Colors.black),
                            child: Icon(
                              Icons.clear,
                            ),
                            onPressed: () {
                              widget.onChanged(null);
                              onSelectLabel = '';
                              setState(() {});
                            },
                          )),
                      widget.suffixIcon ??
                          Icon(
                            Icons.arrow_drop_down,
                            color: widget.primaryColor ?? Colors.black,
                          )
                    ],
                  ),
                ),
                onPressed: () {
                  if (widget.enabled == null || widget.enabled == true) {
                    menuData.clear();
                    if (widget.items.isNotEmpty) {
                      for (int i = 0;
                          i < widget.dropDownMenuItems.length;
                          i++) {
                        menuData.add(widget.dropDownMenuItems[i].toString() +
                            '-_-' +
                            i.toString());
                      }
                      mainDataListGroup = menuData;
                      newDataList = mainDataListGroup;
                      searchC.clear();
                      if (widget.menuMode != null && widget.menuMode == true) {
                        if (_menuController.value != 1) {
                          _menuController.forward();
                        } else {
                          _menuController.reverse();
                        }
                      } else {
                        showDialogueBox(context);
                      }
                    }
                  }
                  setState(() {});
                },
              ),
            ),
            SizeTransition(
              sizeFactor: _menuController,
              child: searchBox(setState),
            )
          ],
        ),
        Visibility(visible: (widget.menuMode ?? false), child: _shoeMenuMode()),
      ],
    );
  }

  Widget _shoeMenuMode() {
    return SizeTransition(
      sizeFactor: _menuController,
      child: mainScreen(setState),
    );
  }

  Future<void> showDialogueBox(context) async {
    await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Padding(
            padding: widget.menuPadding ?? EdgeInsets.all(15),
            child: StatefulBuilder(builder: (context, setState) {
              return Material(
                color: Colors.transparent,
                child: mainScreen(setState),
              );
            }),
          );
        }).then((valueFromDialog) {
      // use the value as you wish
      setState(() {});
    });
  }

  mainScreen(setState) {
    return Padding(
      padding: widget.menuPadding ?? EdgeInsets.all(0),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Visibility(
                visible:
                    ((widget.showLabelInMenu ?? false) && widget.label != null),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.label.toString(),
                    style: widget.labelStyle != null
                        ? widget.labelStyle!.copyWith(
                            color: widget.primaryColor ?? Colors.blue,
                          )
                        : TextStyle(
                            color: widget.primaryColor ?? Colors.blue,
                          ),
                  ),
                )),
            Visibility(
                visible: widget.multiSelect ?? false,
                child: Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: widget.primaryColor ?? Colors.black,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        'Select All',
                        style: widget.labelStyle != null
                            ? widget.labelStyle!.copyWith(
                                color: widget.primaryColor ?? Colors.blue,
                              )
                            : TextStyle(
                                color: widget.primaryColor ?? Colors.blue,
                              ),
                      ),
                      onPressed: () {
                        selectedValues.clear();
                        for (int i = 0; i < newDataList.length; i++) {
                          selectedValues.add(newDataList[i]);
                        }
                        setState(() {});
                      },
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: widget.primaryColor ?? Colors.black,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        'Clear All',
                        style: widget.labelStyle != null
                            ? widget.labelStyle!.copyWith(
                                color: widget.primaryColor ?? Colors.blue,
                              )
                            : TextStyle(
                                color: widget.primaryColor ?? Colors.blue,
                              ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedValues.clear();
                        });
                      },
                    ),
                  ],
                )),
            Visibility(
              visible: !(widget.menuMode ?? false),
              child: searchBox(setState),
            ),
            (widget.menuMode ?? false)
                ? SizedBox(
                    height: widget.menuHeight ?? 150,
                    child: mainList(setState),
                  )
                : Expanded(
                    child: mainList(setState),
                  ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: widget.primaryColor ?? Colors.black,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(
                    'Close',
                    style: widget.labelStyle != null
                        ? widget.labelStyle!.copyWith(
                            color: widget.primaryColor ?? Colors.blue,
                          )
                        : TextStyle(
                            color: widget.primaryColor ?? Colors.blue,
                          ),
                  ),
                  onPressed: () {
                    if (widget.menuMode ?? false) {
                      _menuController.reverse();
                    } else {
                      Navigator.pop(context);
                    }
                    setState(() {});
                  },
                ),
                Visibility(
                  visible: (widget.multiSelect ?? false),
                  child: TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor: widget.primaryColor ?? Colors.black,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(
                      'Done',
                      style: widget.labelStyle != null
                          ? widget.labelStyle!.copyWith(
                              color: widget.primaryColor ?? Colors.blue,
                            )
                          : TextStyle(
                              color: widget.primaryColor ?? Colors.blue,
                            ),
                    ),
                    onPressed: () {
                      var sendList = [];
                      for (int i = 0; i < menuData.length; i++) {
                        if (selectedValues.contains(menuData[i])) {
                          sendList.add(widget.items[i]);
                        }
                      }
                      widget.onChanged(jsonEncode(sendList));
                      if (widget.menuMode ?? false) {
                        _menuController.reverse();
                      } else {
                        Navigator.pop(context);
                      }
                      setState(() {});
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  searchBox(setState) {
    return Visibility(
      visible: widget.hideSearch == null ? true : !widget.hideSearch!,
      child: SizedBox(
        height: widget.searchBarHeight ?? 55.h,
        child: Padding(
          padding: EdgeInsets.all((widget.menuMode ?? false) ? 0.0 : 8.0),
          child: TextField(
            controller: searchC,
            style: widget.textStyle ??
                context.t.displayMedium?.copyWith(color: AppColors.blackColor),
            decoration: InputDecoration(
              fillColor: Colors.white,
              hintStyle: widget.hintStyle ??
                  context.t.displayMedium
                      ?.copyWith(color: AppColors.textFieldHintColor),
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                    color: widget.primaryColor ?? Colors.grey, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                    color: widget.primaryColor ?? Colors.grey, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                    color: widget.primaryColor ?? Colors.grey, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                    color: widget.primaryColor ?? Colors.grey, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                borderSide: BorderSide(
                    color: widget.primaryColor ?? Colors.grey, width: 2),
              ),
              suffixIcon: Icon(
                Icons.search,
                color: widget.primaryColor ?? Colors.black,
              ),
              contentPadding: EdgeInsets.all(8),
              hintText: widget.dropdownHintText ?? 'Search Here...',
              isDense: true,
            ),
            onChanged: (v) {
              onItemChanged(v);
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  mainList(setState) {
    return Scrollbar(
      child: Container(
        color: widget.dropdownBackgroundColor,
        child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: newDataList.length,
            itemBuilder: (BuildContext context, int index) {
              return TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: widget.primaryColor ?? Colors.black,
                    padding: EdgeInsets.all(8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Row(
                    children: [
                      Visibility(
                        visible: widget.multiSelect ?? false,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              0,
                              8,
                              0,
                            ),
                            child: Checkbox(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                value:
                                    selectedValues.contains(newDataList[index])
                                        ? true
                                        : false,
                                activeColor: Colors.green,
                                onChanged: (newValue) {
                                  if (selectedValues
                                      .contains(newDataList[index])) {
                                    setState(() {
                                      selectedValues.remove(newDataList[index]);
                                    });
                                  } else {
                                    setState(() {
                                      selectedValues.add(newDataList[index]);
                                    });
                                  }
                                }),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          newDataList[index].split('-_-')[0].toString(),
                          style: widget.dropdownItemStyle ??
                              TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                onPressed: () {
                  if (widget.multiSelect ?? false) {
                    if (selectedValues.contains(newDataList[index])) {
                      setState(() {
                        selectedValues.remove(newDataList[index]);
                      });
                    } else {
                      setState(() {
                        selectedValues.add(newDataList[index]);
                      });
                    }
                  } else {
                    for (int i = 0; i < menuData.length; i++) {
                      if (menuData[i] == newDataList[index]) {
                        onSelectLabel = menuData[i].split('-_-')[0].toString();
                        widget.onChanged(widget.items[i]);
                      }
                    }
                    if (widget.menuMode ?? false) {
                      _menuController.reverse();
                    } else {
                      Navigator.pop(context);
                    }
                  }
                  setState(() {});
                },
              );
            }),
      ),
    );
  }

  onItemChanged(String value) {
    setState(() {
      newDataList = mainDataListGroup
          .where((string) => string.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }
}
