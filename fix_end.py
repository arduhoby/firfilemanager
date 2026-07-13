import re

with open('lib/features/file_operations/file_operations_state.dart', 'r') as f:
    c = f.read()

c = c.replace("""
  void clear() {
    state = null;
  }
}


  void clear() {
    state = null;
  }
}
""", """
  void clear() {
    state = null;
  }
}
""")

with open('lib/features/file_operations/file_operations_state.dart', 'w') as f:
    f.write(c)
