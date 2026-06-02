import 'package:flutter/material.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';

/// Section card for O&G forms with tinted header.
class ObFormSectionCard extends StatelessWidget {
  const ObFormSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.useTertiaryAccent = false,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final bool useTertiaryAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerBg =
        useTertiaryAccent ? scheme.tertiaryContainer : scheme.primaryContainer;
    final headerFg = useTertiaryAccent
        ? scheme.onTertiaryContainer
        : scheme.onPrimaryContainer;

    return Card(
      elevation: ObstetricsTheme.cardElevation,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: ObstetricsTheme.borderRadius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: headerBg.withValues(alpha: 0.65),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: headerFg),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: headerFg,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(ObstetricsTheme.sectionPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Form screen with gradient app bar, optional context banner, and sticky save bar.
class ObstetricsFormScaffold extends StatelessWidget {
  const ObstetricsFormScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.formKey,
    required this.children,
    this.contextBanner,
    this.onSave,
    this.saveLabel = 'Save',
    this.saving = false,
    this.error,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Widget? contextBanner;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool saving;
  final String? error;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  pinned: true,
                  leading: leading ??
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    background: Container(
                      decoration: ObstetricsTheme.gradientHeader(scheme),
                    ),
                  ),
                ),
                if (subtitle != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                if (error != null)
                  SliverToBoxAdapter(
                    child: Material(
                      color: scheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          error!,
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                if (contextBanner != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: contextBanner!,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(saveLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted context strip for pregnancy/procedure on forms.
class ObFormContextBanner extends StatelessWidget {
  const ObFormContextBanner({
    super.key,
    required this.title,
    this.lines = const [],
    this.icon = Icons.info_outline_rounded,
  });

  final String title;
  final List<String> lines;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.1),
            scheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: ObstetricsTheme.borderRadius,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
