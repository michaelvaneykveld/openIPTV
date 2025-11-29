# VOD Duration Fix

## Problem
VOD playback (Movies/Series) was showing a "growing buffer" (live stream behavior) instead of a fixed duration. This prevented seeking/scrubbing.

## Root Cause
1. **Importer Limitation**: The `StalkerImporter` was only looking for `time_to_play` in the list response. Many providers use other fields or omit duration in the list response entirely.
2. **Missing Data**: Even with the importer fix, some providers (like the user's) return "N/a" or empty values for duration in the list response (`get_ordered_list`).
3. **Reliable Source**: The reliable source for duration is the `get_info` (for movies) and `get_episode` (for episodes) API actions, which return detailed metadata including `duration` (HH:MM:SS) or `duration_in_seconds`.

## Fix
1. **Importer Update**: Updated `lib/data/import/stalker_importer.dart` to check a prioritized list of fields (`time_to_play`, `duration`, `movie_length`, `runtime`, `time`) during import.
2. **Lazy Fetching**: Updated `lib/src/playback/playable_resolver.dart` to **lazily fetch duration** just before playback if it is missing in the database.
   - For Movies: Calls `action=get_info` with `media_id`.
   - For Episodes: Calls `action=get_episode` with `episode_id` (and falls back to `get_info` if needed).
   - Parses various duration formats (seconds, HH:MM:SS, minutes).

## Instructions
- **No Re-sync Required**: The lazy fetching mechanism works for existing items in the database. You do *not* need to re-sync for this to work, although a re-sync will populate the database for faster start times in the future.
- **Verify**: Play a Movie or Episode. The player should now show the correct total duration and allow seeking.
