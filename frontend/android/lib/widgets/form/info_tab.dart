import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/utils/constants.dart';
import 'package:hi_docs/widgets/common/custom_input.dart';

class InfoTab extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController linkController;
  final TextEditingController? categoryController;
  final List<String> categories;
  final DateTime openDate;
  final DateTime closeDate;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final int timerMinutes;
  final bool isPublic;
  final ValueChanged<bool> onIsPublic;
  final ValueChanged<DateTime> onOpenDate;
  final ValueChanged<DateTime> onCloseDate;
  final ValueChanged<TimeOfDay> onOpenTime;
  final ValueChanged<TimeOfDay> onCloseTime;
  final ValueChanged<int>? onDurationMinutes;

  const InfoTab({
    super.key,
    required this.titleController,
    required this.linkController,
    this.categoryController,
    this.categories = const [],
    required this.openDate,
    required this.closeDate,
    required this.openTime,
    required this.closeTime,
    required this.timerMinutes,
    required this.isPublic,
    required this.onIsPublic,
    required this.onOpenDate,
    required this.onCloseDate,
    required this.onOpenTime,
    required this.onCloseTime,
    this.onDurationMinutes,
  });

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  void _randomizeLink() {
    setState(() {
      widget.linkController.text = generateRandomLink(10);
    });
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> cb) async {
    final l10n = AppLocalizations.of(context);
    // Clamp initialDate to valid range to avoid assertion when stored date is old
    final safeInitial = initial.isBefore(DateTime(2024))
        ? DateTime(2024)
        : initial.isAfter(DateTime(2035))
            ? DateTime(2035)
            : initial;
    final d = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: l10n.selectDate,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: context.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) cb(d);
  }

  Future<void> _pickTime(TimeOfDay initial, ValueChanged<TimeOfDay> cb) async {
    final l10n = AppLocalizations.of(context);
    int selectedHour = initial.hour;
    int selectedMinute = initial.minute;

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? AppTheme.darkCard : Colors.white;
        final txtClr = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final period = selectedHour >= 12 ? 'PM' : 'AM';
            final displayHour = selectedHour % 12 == 0 ? 12 : selectedHour % 12;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.selectTime,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txtClr,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Digital Time Display Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.primaryWith(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.primaryWith(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${displayHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: context.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            period,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hour & Minute Selectors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour adjusters
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
                            onPressed: () {
                              setModalState(() {
                                selectedHour = (selectedHour + 1) % 24;
                              });
                            },
                          ),
                          Text(
                            l10n.hoursLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                            onPressed: () {
                              setModalState(() {
                                selectedHour = (selectedHour - 1 + 24) % 24;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: txtClr,
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Minute adjusters
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
                            onPressed: () {
                              setModalState(() {
                                selectedMinute = (selectedMinute + 5) % 60;
                              });
                            },
                          ),
                          Text(
                            l10n.minutesLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                            onPressed: () {
                              setModalState(() {
                                selectedMinute = (selectedMinute - 5 + 60) % 60;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // AM / PM Toggle
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (selectedHour >= 12) {
                                  selectedHour -= 12;
                                } else {
                                  selectedHour += 12;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                                ),
                              ),
                              child: Text(
                                period,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx, TimeOfDay(hour: selectedHour, minute: selectedMinute));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      cb(result);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hStr:$mStr $p';
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.formInformation, Icons.info_outline_rounded, isDark),
          const SizedBox(height: 16),
          CustomInput(
            controller: widget.titleController,
            label: l10n.formTitleLabel,
            hint: l10n.formTitleHint,
            prefixIcon: Icons.title_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.formTitleRequired;
              if (v.trim().length < 3) return l10n.formTitleMinLength;
              return null;
            },
          ),
          if (widget.categoryController != null) ...[
            const SizedBox(height: 16),
            _CategoryField(
              controller: widget.categoryController!,
              categories: widget.categories,
            ),
          ],
          const SizedBox(height: 24),

          _SectionLabel(l10n.formLinkLabel, Icons.link_rounded, isDark),
          const SizedBox(height: 8),
          Text(
            l10n.formLinkDesc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomInput(
                  controller: widget.linkController,
                  label: l10n.customLinkLabel,
                  hint: l10n.customLinkHint,
                  prefixIcon: Icons.link_rounded,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: l10n.randomizeLinkTooltip,
                child: GestureDetector(
                  onTap: _randomizeLink,
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryWith(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _SectionLabel(l10n.sharingVisibilityLabel, Icons.public_rounded, isDark),
          const SizedBox(height: 8),
          Text(
            l10n.sharingVisibilityDesc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _VisibilityCard(
                  selected: widget.isPublic,
                  icon: Icons.public_rounded,
                  title: l10n.publicLabel,
                  subtitle: l10n.publicSublabel,
                  color: AppTheme.success,
                  isDark: isDark,
                  onTap: () => widget.onIsPublic(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VisibilityCard(
                  selected: !widget.isPublic,
                  icon: Icons.lock_outline_rounded,
                  title: l10n.privateLabel,
                  subtitle: l10n.privateSublabel,
                  color: AppTheme.warning,
                  isDark: isDark,
                  onTap: () => widget.onIsPublic(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _SectionLabel(l10n.scheduleLabel, Icons.schedule_rounded, isDark),
          const SizedBox(height: 8),
          Text(
            l10n.scheduleDesc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: l10n.openLabel,
                  icon: Icons.calendar_today_rounded,
                  value: _fmtDate(widget.openDate),
                  isDark: isDark,
                  onTap: () => _pickDate(widget.openDate, widget.onOpenDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: l10n.timeAtLabel,
                  icon: Icons.access_time_rounded,
                  value: _fmtTime(widget.openTime),
                  isDark: isDark,
                  onTap: () => _pickTime(widget.openTime, widget.onOpenTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: l10n.closeLabel,
                  icon: Icons.calendar_today_rounded,
                  value: _fmtDate(widget.closeDate),
                  isDark: isDark,
                  onTap: () => _pickDate(widget.closeDate, widget.onCloseDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: l10n.timeAtLabel,
                  icon: Icons.access_time_rounded,
                  value: _fmtTime(widget.closeTime),
                  isDark: isDark,
                  onTap: () => _pickTime(widget.closeTime, widget.onCloseTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // 1. Calculated Schedule Window Box
          Builder(
            builder: (context) {
              final openDt = DateTime(
                widget.openDate.year,
                widget.openDate.month,
                widget.openDate.day,
                widget.openTime.hour,
                widget.openTime.minute,
              );
              final closeDt = DateTime(
                widget.closeDate.year,
                widget.closeDate.month,
                widget.closeDate.day,
                widget.closeTime.hour,
                widget.closeTime.minute,
              );
              final diff = closeDt.difference(openDt);
              String windowLabel = l10n.openUnlimited;
              if (diff.inMinutes > 0) {
                if (diff.inHours >= 24) {
                  final days = diff.inDays;
                  final remHours = diff.inHours % 24;
                  windowLabel = remHours > 0
                      ? l10n.accessDurationDaysHours(days, remHours)
                      : l10n.accessDurationDays(days);
                } else if (diff.inHours > 0) {
                  final mins = diff.inMinutes % 60;
                  windowLabel = mins > 0
                      ? l10n.accessDurationHoursMins(diff.inHours, mins)
                      : l10n.accessDurationHours(diff.inHours);
                } else {
                  windowLabel = l10n.accessDurationMins(diff.inMinutes);
                }
              } else if (diff.inMinutes < 0) {
                windowLabel = l10n.closeMustBeAfterOpen;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: diff.inMinutes > 0
                      ? context.primaryWith(0.08)
                      : (isDark ? AppTheme.darkSurface : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: diff.inMinutes > 0
                        ? context.primaryWith(0.35)
                        : (isDark ? AppTheme.darkBorder : AppTheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.primaryWith(0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.timelapse_rounded,
                        size: 20,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.accessRangeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            windowLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: diff.inMinutes > 0
                                  ? context.primary
                                  : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 2. Duration Limit (Maksimal Waktu Pengerjaan Soal - Max 60 Mins)
          if (widget.onDurationMinutes != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.timerMinutes > 0
                    ? AppTheme.warning.withValues(alpha: 0.08)
                    : (isDark ? AppTheme.darkCard : AppTheme.surfaceCard),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.timerMinutes > 0
                      ? AppTheme.warning.withValues(alpha: 0.35)
                      : (isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.examDurationLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              l10n.examDurationHintText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DurationInputField(
                    initialMinutes: widget.timerMinutes,
                    isDark: isDark,
                    onChanged: (minutes) {
                      widget.onDurationMinutes?.call(minutes);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationInputField extends StatefulWidget {
  final int initialMinutes;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _DurationInputField({
    required this.initialMinutes,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_DurationInputField> createState() => _DurationInputFieldState();
}

class _DurationInputFieldState extends State<_DurationInputField> {
  late TextEditingController _controller;
  late bool _isUnlimited;

  @override
  void initState() {
    super.initState();
    _isUnlimited = widget.initialMinutes <= 0;
    _controller = TextEditingController(
      text: widget.initialMinutes > 0 ? '${widget.initialMinutes}' : '',
    );
  }

  @override
  void didUpdateWidget(covariant _DurationInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes) {
      _isUnlimited = widget.initialMinutes <= 0;
      if (!_isUnlimited && _controller.text != '${widget.initialMinutes}') {
        _controller.text = '${widget.initialMinutes}';
      } else if (_isUnlimited) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String val) {
    if (val.isEmpty) {
      widget.onChanged(0);
      return;
    }
    final n = int.tryParse(val) ?? 0;
    if (n > 60) {
      _controller.value = const TextEditingValue(
        text: '60',
        selection: TextSelection.collapsed(offset: 2),
      );
      widget.onChanged(60);
    } else {
      widget.onChanged(n);
    }
  }

  void _toggleUnlimited() {
    setState(() {
      _isUnlimited = !_isUnlimited;
      if (_isUnlimited) {
        _controller.clear();
        widget.onChanged(0);
      } else {
        _controller.text = '30';
        widget.onChanged(30);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isUnlimited ? 0.4 : 1.0,
                child: AbsorbPointer(
                  absorbing: _isUnlimited,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: _handleChanged,
                    decoration: InputDecoration(
                      hintText: _isUnlimited ? l10n.noTimeLimit : '45',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                      ),
                      suffixText: _isUnlimited ? null : '${l10n.minutesLabel} (Max 60)',
                      suffixStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                      filled: true,
                      fillColor: widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isDark ? AppTheme.darkBorder : AppTheme.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.warning, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _toggleUnlimited,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _isUnlimited
                      ? context.primaryWith(0.15)
                      : (widget.isDark ? AppTheme.darkSurface : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isUnlimited
                        ? context.primary
                        : (widget.isDark ? AppTheme.darkBorder : AppTheme.border),
                    width: _isUnlimited ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isUnlimited ? Icons.all_inclusive_rounded : Icons.timer_outlined,
                      size: 18,
                      color: _isUnlimited
                          ? context.primary
                          : (widget.isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.noTimeLimit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _isUnlimited ? FontWeight.w700 : FontWeight.w500,
                        color: _isUnlimited
                            ? context.primary
                            : (widget.isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const _SectionLabel(this.text, this.icon, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? context.primaryWith(0.15)
                : context.primaryFaint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isDark ? const Color(0xFF4A90D9) : context.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.09)
              : (isDark ? AppTheme.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppTheme.darkBorder : AppTheme.border),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected
                    ? color
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {  final String label;
  final IconData icon;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.label,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isDark ? const Color(0xFF4A90D9) : context.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> categories;

  const _CategoryField({
    required this.controller,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoryLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Autocomplete<String>(
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            final uniq = <String>{};
            for (final c in categories) {
              final t = c.trim();
              if (t.isEmpty) continue;
              if (q.isEmpty || t.toLowerCase().contains(q)) uniq.add(t);
            }
            return uniq;
          },
          onSelected: (v) => controller.text = v,
          fieldViewBuilder: (ctx, fieldCtrl, focusNode, onSubmit) {
            if (fieldCtrl.text != controller.text &&
                !focusNode.hasFocus) {
              fieldCtrl.text = controller.text;
            }
            return TextFormField(
              controller: fieldCtrl,
              focusNode: focusNode,
              onChanged: (v) => controller.text = v,
              decoration: InputDecoration(
                hintText: l10n.categoryHint,
                prefixIcon: Icon(
                  Icons.category_outlined,
                  size: 20,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
                filled: true,
                fillColor:
                    isDark ? AppTheme.darkSurface : AppTheme.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}