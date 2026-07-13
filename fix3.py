with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'r') as f:
    content = f.read()

target_start = content.find("              if (!clipboard.isEmpty) ...[")
target_end = content.find("Widget _buildProgressBar", target_start)

if target_start != -1 and target_end != -1:
    old_block = content[target_start:target_end]
    new_block = old_block.replace(
        "            ],\n          ),\n        ),\n      ),\n    );\n  }",
        "            ],\n          ),\n        ),\n      ),\n      ),\n    );\n  }"
    )
    new_content = content[:target_start] + new_block + content[target_end:]
    with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'w') as f:
        f.write(new_content)
    print("Fixed!")
