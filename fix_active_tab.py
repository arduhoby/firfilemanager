import os
import re

files_to_fix = [
    'lib/features/shell_adaptive/panel_controller.dart',
    'lib/features/shell_adaptive/panel_drive_bar.dart',
    'lib/features/shell_adaptive/panel_path_bar.dart',
    'lib/features/shell_adaptive/file_panel.dart',
    'lib/features/shell_adaptive/file_operations_actions.dart',
    'lib/features/shell_adaptive/dual_pane_shell.dart',
]

props = [
    'currentPath', 'providerId', 'entries', 'selectedPaths', 'selectedEntries', 
    'sortField', 'sortDirection', 'showHidden', 'isLoading', 'error', 
    'hasSelection', 'selectionCount'
]

# We want to replace things like `panelState.currentPath` with `panelState.activeTab.currentPath`
# and `next.currentPath` with `next.activeTab.currentPath`
# and `previous?.currentPath` with `previous?.activeTab.currentPath`

prefixes = ['panelState', 'next', 'previous\?', 'leftState', 'rightState', 'state', 'ref\.watch\(panelAProvider\)', 'ref\.watch\(panelBProvider\)', 'ref\.read\(panelAProvider\)', 'ref\.read\(panelBProvider\)']

def fix_file(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()

    for prop in props:
        for prefix in prefixes:
            pattern = r'(' + prefix + r')\.' + prop + r'\b'
            # Be careful not to replace if it's already activeTab
            # so we use negative lookbehind if possible or just replace safely
            replacement = r'\1.activeTab.' + prop
            # To avoid replacing .activeTab.activeTab
            content = re.sub(r'(?<!activeTab\.)' + pattern, replacement, content)

    # Some variables like `panelState` might actually be of type `PanelState`.
    # Let's write it out.
    with open(filepath, 'w') as f:
        f.write(content)

for file in files_to_fix:
    fix_file(file)

print("Done")
