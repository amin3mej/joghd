# Library search verification

JOG-35 adds local title/author filtering through `LibraryStore.searchQuery`
and `filteredEntries`. The query is session-only and is not saved to disk.

JOG-39 replaces the search keyboard's floating "Done" control with a
magnifying-glass button that applies the entered query and closes the keyboard.
The dismissal button now occupies a separate, minimum-44-point slot beside the
search field while focused, instead of using a floating keyboard toolbar.

The library content now sits inside a stable `ZStack`, with the header and
search insets attached outside it. Switching between the grid, no matches,
empty library, and load errors changes only the container's content, not the
search inset's parent. Query and focus are not reset by those transitions.

## Automated coverage

`LibraryStoreTests` covers substring matching, case and accents, optional
authors, no matches, clearing, relative ordering, reload/import updates,
failed reloads, and deletion while a query is active. UI automation is outside
the agreed test seam.

## Manual UI checklist

Run on iOS 26+ (native glass) and an older supported iOS version (material).
These checks remain pending until performed on a simulator or device:

- Search by title and author, clear the field, and distinguish no matches
  from an empty library and a load error.
- With Protocols and bedroom in the library, focus search and enter `bed`,
  clear, then enter `z`. Confirm No matching books appears without losing
  focus or hiding the keyboard; continue typing, delete back to matches, and
  clear again without refocusing.
- Dismiss the keyboard with Search, the keyboard magnifier, and an interactive
  grid scroll; confirm that no Done control appears, that the query and
  filtered results remain unchanged, and that the magnifier closes the keyboard.
- With empty and nonempty queries, including the largest accessibility text
  size, confirm the adjacent magnifier never covers the field or clear control.
- Scroll a multi-row library to its end with and without the keyboard;
  confirm the last row clears the search bar and the grid scrolls behind it.
- Check bottom safe-area placement on small and large iPhones.
- At accessibility Dynamic Type sizes, confirm the field, clear control,
  header, and final grid row remain usable.
- With VoiceOver, confirm the Search library field, the keyboard Search button,
  and Clear search button are announced and reachable, without announcing the
  decorative search icon.
- Import a matching and a nonmatching book with an active query; confirm
  that the query remains active and only matching entries appear.

## Review follow-up verification

All 173 tests pass on both iOS 27.0 and iOS 18.4. The focused
`LibraryStoreTests` run also passes. No UI test seam was added.

Runtime visual checks remain pending: this environment can boot headless iOS
simulators, but the selected Xcode installation is missing `Simulator.app`.
The structural focus fix and adjacent dismissal-control layout have not been
visually verified here. Do not treat the checklist above as passed.
