with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'r') as f:
    content = f.read()

# find "          ),
#         ),
#       ),
#     );
#   }"
# and add one more ");"
target = """          ),
        ),
      ),
    );
  }"""
replacement = """          ),
        ),
      ),
    );
  }"""

# Actually, I'll just find the exact block and replace it
target_start = content.find("              if (!clipboard.isEmpty) ...[")
target_end = content.find("Widget _buildProgressBar", target_start)

if target_start != -1 and target_end != -1:
    block = content[target_start:target_end]
    print(block)
