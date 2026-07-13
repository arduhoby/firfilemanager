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

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Generic replace: word_boundary + var_name + . + prop 
    # where var_name is one of the known states.
    # It's safer to just replace .prop with .activeTab.prop IF it's on a PanelState variable.
    # But wait, we can just replace all `.prop` if it's not preceded by `activeTab` or `entry` or `file` or `state` if `state` is TabState.
    # Let's do it manually for the variables we know are PanelState:
    vars_list = ['leftState', 'rightState', 'panelState', 'next', 'previous\?', 'state']
    for var in vars_list:
        for prop in props:
            content = re.sub(r'(?<!activeTab\.)\b(' + var + r')\.' + prop + r'\b', r'\1.activeTab.' + prop, content)
            
    # Also for ref.watch/read
    for prop in props:
        content = re.sub(r'(ref\.(watch|read)\(panel[AB]Provider\))\.' + prop + r'\b', r'\1.activeTab.' + prop, content)

    # Fix specific errors from compilation output:
    content = content.replace('clipboard.isEmpty', '(clipboard == null)')
    content = content.replace('.set(widget.side)', '.setActive(widget.side)')
    
    with open(filepath, 'w') as f:
        f.write(content)

for file in files_to_fix:
    fix_file(file)

print("Done")
