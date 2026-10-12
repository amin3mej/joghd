# Library search verification

JOG-35 adds local title/author filtering through `LibraryStore.searchQuery`
and `filteredEntries`. The query is session-only and is not saved to disk.

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
- Dismiss the keyboard with Search, Done, and an interactive grid scroll;
  confirm that the query and filtered results remain unchanged.
- Scroll a multi-row library to its end with and without the keyboard;
  confirm the last row clears the search bar and the grid scrolls behind it.
- Check bottom safe-area placement on small and large iPhones.
- At accessibility Dynamic Type sizes, confirm the field, clear control,
  header, and final grid row remain usable.
- With VoiceOver, confirm the Search library field and Clear search button
  are announced and reachable, without announcing the decorative search icon.
- Import a matching and a nonmatching book with an active query; confirm
  that the query remains active and only matching entries appear.
