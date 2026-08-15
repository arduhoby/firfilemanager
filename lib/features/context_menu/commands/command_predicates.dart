import '../../../core/commands/command_availability.dart';
import '../../../core/commands/command_context.dart';

abstract final class CommandPredicates {
  static CommandAvailability hasEntry(CommandContext context) =>
      context.clickedEntry == null
      ? const CommandAvailability.disabled('No entry is selected.')
      : const CommandAvailability.available();

  static CommandAvailability hasFile(CommandContext context) {
    final entry = context.clickedEntry;
    return entry == null || entry.isDirectory
        ? const CommandAvailability.hidden('This command requires a file.')
        : const CommandAvailability.available();
  }

  static CommandAvailability hasDirectory(CommandContext context) {
    final entry = context.clickedEntry;
    return entry == null || !entry.isDirectory
        ? const CommandAvailability.hidden('This command requires a folder.')
        : const CommandAvailability.available();
  }

  static CommandAvailability hasEffectiveEntries(CommandContext context) =>
      context.effectiveEntries.isEmpty
      ? const CommandAvailability.disabled('No entry is selected.')
      : const CommandAvailability.available();

  static CommandAvailability canWrite(CommandContext context) =>
      context.supports(CommandCapability.write)
      ? const CommandAvailability.available()
      : const CommandAvailability.disabled('The destination is read-only.');

  static CommandAvailability canDelete(CommandContext context) {
    if (context.effectiveEntries.isEmpty) {
      return const CommandAvailability.disabled('No entry is selected.');
    }
    return context.supports(CommandCapability.delete)
        ? const CommandAvailability.available()
        : const CommandAvailability.disabled('Delete is not supported.');
  }

  static CommandAvailability canArchive(CommandContext context) {
    if (context.effectiveEntries.isEmpty) {
      return const CommandAvailability.disabled('No entry is selected.');
    }
    return context.supports(CommandCapability.archive)
        ? const CommandAvailability.available()
        : const CommandAvailability.disabled('Archive is not supported.');
  }
}
