/// Max camera view_range we support for chunk membership / AABB updates.
/// Must be >= the highest camera view_range in the codebase (laser_cam uses 12).
#define MAX_CAMERA_RANGE 12

/// We only want chunk sizes that are to the power of 2. E.g: 2, 4, 8, 16, etc..
/// Halved from 16 (tgstation#94530): more chunks, but cheaper per-chunk updates when AI eyes move.
#define CHUNK_SIZE 8

/// Takes a position, transforms it into a chunk bounded position. Indexes at 1 so it'll land on actual turfs always
#define GET_CHUNK_COORD(v) max((FLOOR((v), CHUNK_SIZE)), 1)

/// Default delay before a watched/unwatched chunk rebuilds static
#define UPDATE_BUFFER_TIME (2.5 SECONDS)
