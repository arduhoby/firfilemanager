import re

with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'r') as f:
    content = f.read()

# The bug is that between "child: Row(" and the end of _buildFunctionBar, the actionButtons got duplicated.
# We just need to extract everything from actionButton(icon: Icons.create_new_folder_outlined down to the end of _buildFunctionBar.
# Actually, let's just find "child: SingleChildScrollView(" and replace the whole block until "Widget _buildProgressBar"

start_idx = content.find("child: SingleChildScrollView(")
end_idx = content.find("Widget _buildProgressBar")

if start_idx != -1 and end_idx != -1:
    correct_block = """child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
              actionButton(
                icon: Icons.create_new_folder_outlined,
                label: l10n.actionNewFolder,
                onPressed: () => actions.showNewFolderDialog(context, activeSide),
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.copy_outlined,
                label: 'F5 ${l10n.actionCopy}',
                onPressed: hasSelection ? () => actions.copyToOtherPanel(context, activeSide) : null,
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.drive_file_move_outline,
                label: 'F6 ${l10n.actionMove}',
                onPressed: hasSelection ? () => actions.moveToOtherPanel(context, activeSide) : null,
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.edit_outlined,
                label: l10n.actionRename,
                onPressed: hasSelection && activeState.selectionCount == 1
                    ? () => actions.showRenameDialog(context, activeSide, activeState.selectedEntries.first)
                    : null,
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.delete_outline,
                label: 'F8 ${l10n.actionDelete}',
                onPressed: hasSelection
                    ? () => actions.showDeleteDialog(context, activeSide, activeState.selectedEntries)
                    : null,
                color: hasSelection ? Colors.red.withValues(alpha: 0.8) : null,
              ),
              const _FnDivider(),
              actionButton(
                icon: Icons.content_copy,
                label: l10n.actionCopy,
                onPressed: hasSelection
                    ? () => actions.copyToClipboard(activeSide, activeState.selectedEntries)
                    : null,
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.content_cut,
                label: l10n.actionMove,
                onPressed: hasSelection
                    ? () => actions.cutToClipboard(activeSide, activeState.selectedEntries)
                    : null,
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.content_paste,
                label: l10n.actionPaste,
                onPressed: clipboard.isEmpty ? null : () => actions.paste(activeSide),
              ),
              const _FnDivider(),
              actionButton(
                icon: Icons.select_all_outlined,
                label: l10n.actionSelectAll,
                onPressed: () {
                  if (activeSide == PanelSide.a) {
                    ref.read(panelAProvider.notifier).selectAll();
                  } else {
                    ref.read(panelBProvider.notifier).selectAll();
                  }
                },
              ),
              const SizedBox(width: 2),
              actionButton(
                icon: Icons.refresh,
                label: l10n.actionRefresh,
                onPressed: () =>
                    ref.read(panelControllerProvider.notifier).refresh(activeSide),
              ),
              const Spacer(),
              if (!clipboard.isEmpty) ...[
                Icon(Icons.paste, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${clipboard.sourcePaths.length} ${clipboard.operation == ClipboardOperation.copy ? l10n.actionCopy : l10n.actionMove}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  """
    new_content = content[:start_idx] + correct_block + content[end_idx:]
    with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'w') as f:
        f.write(new_content)
    print("Fixed dual_pane_shell.dart")
else:
    print("Indices not found")
