import 'package:flutter/material.dart';
import '../services/ai_engine.dart';

class ModelScreen extends StatelessWidget {
  const ModelScreen({super.key, required this.engine});
  final AiEngine engine;

  Future<void> _confirmDelete(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove offline AI?'),
        content: const Text(
          'You will need to download or import it again to chat. Your conversations will stay saved.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes == true) await engine.deleteModel();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: engine,
        builder: (context, _) {
          final colors = Theme.of(context).colorScheme;
          final working = engine.loading ||
              engine.downloading ||
              engine.generating ||
              engine.chatting;
          final status = engine.loading
              ? 'Starting'
              : engine.downloading
                  ? 'Downloading'
                  : engine.loaded
                      ? 'Ready'
                      : engine.modelInstalled
                          ? 'Installed'
                          : 'Not set up';
          final accent = engine.loaded
              ? Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF78D9B0)
                  : const Color(0xFF18794E)
              : colors.onSurfaceVariant;

          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        const _SectionLabel('Appearance'),
                        _SettingsGroup(
                            child: SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          secondary:
                              const _SettingIcon(Icons.dark_mode_outlined),
                          title: const Text('Dark mode', style: _rowTitle),
                          subtitle: Text(
                              engine.darkMode
                                  ? 'A softer look for low light'
                                  : 'A clean, bright workspace',
                              style: _subtitle(context)),
                          value: engine.darkMode,
                          onChanged: (_) => engine.toggleTheme(),
                        )),
                        const SizedBox(height: 28),
                        const _SectionLabel('Offline AI'),
                        _SettingsGroup(
                            child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _SettingIcon(
                                          Icons.auto_awesome_outlined),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                          child: Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text('On-device assistant',
                                            style: _rowTitle),
                                      )),
                                    ]),
                                const SizedBox(height: 16),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                    color: accent,
                                                    shape: BoxShape.circle)),
                                            const SizedBox(width: 7),
                                            Text(status,
                                                style: TextStyle(
                                                    color: accent,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ]),
                                    )),
                                const SizedBox(height: 12),
                                Text(
                                  engine.loaded
                                      ? 'Your AI is ready. Return to chat to ask, write, or translate.'
                                      : engine.modelInstalled
                                          ? 'Your AI is installed. Start it to continue chatting.'
                                          : 'Download your AI once to chat, write, and translate without internet.',
                                  style: _subtitle(context),
                                ),
                                if (!engine.modelInstalled &&
                                    !engine.downloading) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                      '563 MB download · Internet needed for setup',
                                      style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: colors.onSurfaceVariant)),
                                ],
                                if (engine.loading || engine.downloading) ...[
                                  const SizedBox(height: 20),
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        minHeight: 5,
                                        backgroundColor: colors.outlineVariant,
                                        value: engine.downloading &&
                                                engine.downloadProgress > 0
                                            ? engine.downloadProgress
                                            : null,
                                      )),
                                  const SizedBox(height: 10),
                                  Text(
                                      engine.loading
                                          ? 'Getting your AI ready…'
                                          : engine.downloadProgress > 0
                                              ? '${(engine.downloadProgress * 100).round()}% downloaded'
                                              : 'Preparing download…',
                                      style: _subtitle(context)),
                                ],
                                if (engine.error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: colors.error
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                              12, 0, 12, 14),
                                      shape: const Border(),
                                      collapsedShape: const Border(),
                                      leading: Icon(Icons.error_outline_rounded,
                                          color: colors.error, size: 20),
                                      title: Text('Could not complete setup',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: colors.error)),
                                      subtitle: const Text('Tap for details',
                                          style: TextStyle(fontSize: 12)),
                                      children: [
                                        SelectableText(engine.error!,
                                            style: _subtitle(context))
                                      ],
                                    ),
                                  ),
                                ],
                                if (!engine.loaded) ...[
                                  const SizedBox(height: 20),
                                  if (!engine.modelInstalled) ...[
                                    FilledButton.icon(
                                      onPressed:
                                          working ? null : engine.downloadModel,
                                      icon: const Icon(Icons.download_rounded,
                                          size: 18),
                                      label: const Text('Download AI'),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed:
                                          working ? null : engine.importModel,
                                      icon: const Icon(
                                          Icons.folder_open_outlined,
                                          size: 18),
                                      label: const Text('Import from device'),
                                    ),
                                  ] else
                                    FilledButton.icon(
                                      onPressed: working ? null : engine.load,
                                      icon: const Icon(Icons.play_arrow_rounded,
                                          size: 20),
                                      label: const Text('Start AI'),
                                    ),
                                  if (engine.downloading)
                                    TextButton(
                                      onPressed: engine.cancelDownload,
                                      child: const Text('Cancel download'),
                                    ),
                                ],
                              ]),
                        )),
                        const SizedBox(height: 28),
                        const _SectionLabel('Preferences'),
                        _SettingsGroup(
                            child: ExpansionTile(
                          key: const PageStorageKey('advanced-settings'),
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: const _SettingIcon(Icons.tune_rounded),
                          title: const Text('Advanced', style: _rowTitle),
                          subtitle: Text('Memory and model storage',
                              style: _subtitle(context)),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          children: [
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: const Text('Use less memory',
                                  style: _rowTitle),
                              subtitle: Text(
                                  'Shorter replies for phones with limited memory. Start AI again after changing this.',
                                  style: _subtitle(context)),
                              value: engine.lowMemoryMode,
                              onChanged: working ? null : engine.setLowMemory,
                            ),
                            if (engine.loaded)
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: const Icon(
                                    Icons.pause_circle_outline_rounded,
                                    size: 22),
                                title: const Text('Pause offline AI',
                                    style: _rowTitle),
                                subtitle: Text(
                                    'Free up memory until your next chat',
                                    style: _subtitle(context)),
                                onTap: working ? null : engine.unload,
                              ),
                            if (engine.modelInstalled) ...[
                              const Divider(
                                  height: 1, indent: 16, endIndent: 16),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                leading: Icon(Icons.delete_outline_rounded,
                                    color: colors.error, size: 22),
                                title: Text('Remove downloaded AI',
                                    style: _rowTitle.copyWith(
                                        color: colors.error)),
                                subtitle: Text('Your saved chats will stay',
                                    style: _subtitle(context)),
                                onTap: working
                                    ? null
                                    : () => _confirmDelete(context),
                              ),
                            ],
                          ],
                        )),
                        const SizedBox(height: 28),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 16, color: colors.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      'Your conversations stay on this device.',
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 12,
                                          height: 1.5))),
                            ]),
                      ],
                    ),
                  ),
                )),
          );
        },
      );

  static const _rowTitle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle _subtitle(BuildContext context) => TextStyle(
        fontSize: 13,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.6),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20),
      );
}
