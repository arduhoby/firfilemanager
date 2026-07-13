import re

def replace_props(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    props = ['currentPath', 'providerId', 'entries', 'selectedPaths', 'selectedEntries', 'sortField', 'sortDirection', 'showHidden', 'isLoading', 'error', 'hasSelection', 'selectionCount']
    
    # We replace things like `leftState.currentPath` with `leftState.activeTab.currentPath`
    # Also `rightState.currentPath` with `rightState.activeTab.currentPath`
    # Also `state.currentPath` -> `state.activeTab.currentPath` (careful not to break `TabState state` if it exists)

    prefixes = [r'panelState', r'next', r'previous\?', r'leftState', r'rightState', r'ref\.watch\(panelAProvider\)', r'ref\.watch\(panelBProvider\)', r'ref\.read\(panelAProvider\)', r'ref\.read\(panelBProvider\)']

    for prop in props:
        for prefix in prefixes:
            pattern = r'(' + prefix + r')\.' + prop + r'\b'
            replacement = r'\1.activeTab.' + prop
            content = re.sub(r'(?<!activeTab\.)' + pattern, replacement, content)
            
    with open(filepath, 'w') as f:
        f.write(content)

replace_props('lib/features/shell_adaptive/dual_pane_shell.dart')
replace_props('lib/features/shell_adaptive/file_operations_actions.dart')
replace_props('lib/features/shell_adaptive/panel_drive_bar.dart')
replace_props('lib/features/shell_adaptive/panel_path_bar.dart')

