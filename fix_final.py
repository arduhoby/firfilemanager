import re

def r_regex(filepath, vars_list, props):
    with open(filepath, 'r') as f:
        c = f.read()
    
    for var in vars_list:
        for prop in props:
            # We want to replace `var.prop` with `var.activeTab.prop`
            # For `next` and `previous?` we just match them
            pattern = r'\b(' + var + r')\.' + prop + r'\b'
            c = re.sub(pattern, r'\1.activeTab.' + prop, c)
            
            # For ref.watch / ref.read
            pattern2 = r'(ref\.(watch|read)\(panel[AB]Provider\))\.' + prop + r'\b'
            c = re.sub(pattern2, r'\1.activeTab.' + prop, c)

    with open(filepath, 'w') as f:
        f.write(c)

vars_list = ['leftState', 'rightState', 'panelState', 'state', 'next']
props = ['currentPath', 'providerId', 'hasSelection', 'selectionCount', 'selectedEntries']

r_regex('lib/features/shell_adaptive/dual_pane_shell.dart', vars_list, props)
r_regex('lib/features/shell_adaptive/file_operations_actions.dart', vars_list, props)
r_regex('lib/features/shell_adaptive/panel_drive_bar.dart', vars_list, props)

# Also fix DualPaneShell 'side' error: 'widget.side' -> 'PanelSide.a' (DualPaneShell doesn't have side, activePanelProvider toggle need to know current active panel)
with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'r') as f:
    c = f.read()
# Replace `widget.side == PanelSide.a` which I added earlier by mistake.
# DualPaneShell doesn't have `widget.side`. Wait, how to toggle active panel?
c = c.replace('ref.read(activePanelProvider.notifier).setActive(widget.side == PanelSide.a ? PanelSide.b : PanelSide.a)', 
              'final active = ref.read(activePanelProvider); ref.read(activePanelProvider.notifier).setActive(active == PanelSide.a ? PanelSide.b : PanelSide.a)')
with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'w') as f:
    f.write(c)

