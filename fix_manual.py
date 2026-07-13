import re

def r(filepath, old, new):
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)

# File Operations Service
r('lib/features/file_operations/file_operations_service.dart', 'clipboard.isEmpty', '(clipboard == null)')
r('lib/features/file_operations/file_operations_service.dart', 'ref.read(operationProgressProvider.notifier).update', 'ref.read(operationProgressProvider.notifier).setProgress')

# Dual Pane Shell
f = 'lib/features/shell_adaptive/dual_pane_shell.dart'
r(f, 'ref.read(activePanelProvider.notifier).toggle()', 'ref.read(activePanelProvider.notifier).setActive(widget.side == PanelSide.a ? PanelSide.b : PanelSide.a)')
with open(f, 'r') as f_obj: c = f_obj.read()
c = re.sub(r'\b(panelState)\.(providerId|hasSelection|selectionCount|selectedEntries)\b', r'\1.activeTab.\2', c)
with open(f, 'w') as f_obj: f_obj.write(c)

# File Operations Actions
f = 'lib/features/shell_adaptive/file_operations_actions.dart'
with open(f, 'r') as f_obj: c = f_obj.read()
c = re.sub(r'\b(panelState)\.(currentPath|hasSelection|selectionCount|selectedEntries)\b', r'\1.activeTab.\2', c)
with open(f, 'w') as f_obj: f_obj.write(c)

# Panel Drive Bar
f = 'lib/features/shell_adaptive/panel_drive_bar.dart'
with open(f, 'r') as f_obj: c = f_obj.read()
c = re.sub(r'\b(panelState)\.(providerId|currentPath)\b', r'\1.activeTab.\2', c)
with open(f, 'w') as f_obj: f_obj.write(c)

