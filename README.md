# Pixiv Bookmark Downloader

## Table of Contents

- [Pixiv Bookmark Downloader](#pixiv-bookmark-downloader)
  - [Table of Contents](#table-of-contents)
  - [Goal](#goal)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
  - [Where Files Are Saved](#where-files-are-saved)
  - [Configuration](#configuration)
  - [Skipping Already-Downloaded Images](#skipping-already-downloaded-images)
  - [Deleting Unwanted Images Without Re-Downloading](#deleting-unwanted-images-without-re-downloading)
  - [Why `favorite` Needs Special Configuration](#why-favorite-needs-special-configuration)
  - [Known Limitations](#known-limitations)
  - [Troubleshooting](#troubleshooting)

---

## Goal

Download all bookmarked artworks from a Pixiv account using [gallery-dl](https://github.com/mikf/gallery-dl), while:
- **not re-downloading** images that have already been downloaded (whether via the bookmarks URL or directly by artwork/user URL), and
- **not re-downloading** images that were intentionally deleted locally (e.g. filler or promotional pages from multi-image posts).

---

## Prerequisites

- [uv](https://github.com/astral-sh/uv) — used to run gallery-dl in a virtual environment via `uvsh` (see [pyproject.toml](pyproject.toml)).
- A Pixiv account with an active OAuth token. Authenticate by running:
  ```
  gallery-dl oauth:pixiv
  ```
  Follow the prompts. The token is stored in the gallery-dl configuration file and used automatically. Note that Pixiv uses this approach *instead of* the `--username`/`--password` options.

---

## Usage

1. Create a text file named `pixiv_user_id.txt` in the same directory as the script, and put your Pixiv user ID in it. This is the numeric ID that appears in your profile URL, e.g. for `https://www.pixiv.net/en/users/123456789` the user ID is `123456789`:
   ```
   123456789
   ```
   `pixiv_user_id.txt` is listed in `.gitignore` and will never be committed.

2. Run the script:
   ```powershell
   .\download_pixiv.ps1
   ```

You can re-run this script at any time to download newly bookmarked images. Already-downloaded (or intentionally deleted) images will be skipped.

---

## Where Files Are Saved

All images are saved under `gallery-dl\pixiv\` relative to the script directory, organised by artist:

```
gallery-dl
└── pixiv
    ├── {artist_id} {artist_name}
    │   ├── {artwork_id}_p0.png
    │   └── {artwork_id}_p1.png
    └── {artist_id} {artist_name}
        ├── {artwork_id}_p0.png
        └── {artwork_id}_p1.png
```

The filename format is `{artwork_id}_p{page_number}.{extension}`, where the page number refers to the specific image within a multi-image post (starting at 0).

---

## Configuration

The configuration file [gallery-dl.conf](gallery-dl.conf) is set up to meet the goals outlined above. Setting names and values used there are explained in the next sections.

For more documentation on all configuration options, see the [gallery-dl config help page](https://github.com/mikf/gallery-dl/blob/master/docs/configuration.rst).

---

## Skipping Already-Downloaded Images

gallery-dl maintains a SQLite "archive" database at `~/.archives/pixiv.sqlite3`. Every image that is downloaded or skipped gets a row inserted with a unique ID derived from its `archive-format`. On subsequent runs, gallery-dl checks the archive **before** doing anything — if the ID is present the file is skipped, even if it no longer exists on disk.

This means the archive is the single source of truth for what has been downloaded, *not* the filesystem.

**Why `archive-event` includes `"skip"`:** By default (`"file"` only), gallery-dl writes to the archive only on a successful download — not when a file is skipped because it already exists on disk. Without `"skip"`, any run where all files are already present leaves the archive completely empty, meaning deleting a file locally *would* cause a re-download. Including `"skip"` ensures that files skipped due to already being on disk are also recorded, keeping the archive accurate.

---

## Deleting Unwanted Images Without Re-Downloading

Because the archive tracks individual pages within a multi-image post separately (using `{id}{suffix}.{extension}`, where suffix is e.g. `_p0`, `_p1`, …), you can safely delete any subset of pages from a post using any tool (e.g. Windows Photos) and those specific pages will not be re-downloaded on the next run.

Example: if a post has pages `p0`–`p6` and you delete `p3` and `p5`, the remaining pages (`p0`, `p1`, `p2`, `p4`, `p6`) stay on disk and all seven pages remain in the archive — so none of them will be re-downloaded.

If you ever *want* to force a re-download of a deleted image, remove its row from the archive database using a tool such as [DBeaver](https://dbeaver.io/).

---

## Why `favorite` Needs Special Configuration

gallery-dl has three relevant Pixiv subcategory extractors. Their defaults, as reported by `gallery-dl --extractor-info <url>`, are:

| URL type | Subcategory | Default directory | Default archive format |
|---|---|---|---|
| `/bookmarks/artworks` | `favorite` | `pixiv/bookmarks/{user_bookmark[id]} {user_bookmark[account]}` | `f_{user_bookmark[id]}_{id}{num}.{extension}` |
| `/en/artworks/<id>` | `work` | `pixiv/{user[id]} {user[account]}` | `{id}{suffix}.{extension}` |
| `/en/users/<id>` | `user` | `pixiv/{user[id]} {user[account]}` | `{id}{suffix}.{extension}` |

Without configuration, the `favorite` extractor saves files to a completely different directory and uses a different archive ID format than `work`/`user`. This means that an image downloaded via bookmarks and the same image downloaded directly would be treated as two different files — both by the filesystem  (different path) and by the archive (different ID) — causing double downloads.

The [gallery-dl.conf](gallery-dl.conf) fixes this by overriding `favorite` to use the same directory and archive-format as `work`/`user`:

```json
"favorite": {
    "directory": ["{category}", "{user[id]} {user[account]}"],
    "archive-format": "{id}{suffix}.{extension}"
}
```

Now all three subcategories produce identical paths and archive IDs for the same artwork, so whichever URL you use to download, duplicates are correctly detected and skipped.

---

## Known Limitations

- **No concurrent/parallel downloading.** gallery-dl downloads images sequentially (one at a time). This is a known missing feature; see [issue #31](https://github.com/mikf/gallery-dl/issues/31). Expect roughly 1 image per second.

---

## Troubleshooting

**`gallery-dl failed to canonicalize script path`**

Your version of gallery-dl is outdated. Update it with:
```
uv sync --upgrade-package gallery-dl
```

**Authentication errors**

Re-authenticate using:
```
gallery-dl oauth:pixiv
```
