#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s PACKAGE_DIR ARCHIVE_PATH\n' "$0" >&2
  exit 2
fi

package_dir=$1
archive_path=$2

if [[ ! -d $package_dir ]]; then
  printf 'Review-package directory does not exist: %s\n' "$package_dir" >&2
  exit 1
fi
if [[ ! -d $(dirname -- "$archive_path") ]]; then
  printf 'Archive parent directory does not exist: %s\n' "$(dirname -- "$archive_path")" >&2
  exit 1
fi

package_parent=$(CDPATH='' cd -- "$(dirname -- "$package_dir")" && pwd)
package_name=$(basename -- "$package_dir")
archive_parent=$(CDPATH='' cd -- "$(dirname -- "$archive_path")" && pwd)
archive_name=$(basename -- "$archive_path")
archive="$archive_parent/$archive_name"

temporary_base=$(mktemp "$archive.tmp.XXXXXX")
temporary="$temporary_base.zip"
rm -f -- "$temporary_base"
trap 'rm -f -- "$temporary_base" "$temporary"' EXIT

(
  cd -- "$package_parent"
  zip -qr "$temporary" "$package_name"
)
mv -f -- "$temporary" "$archive"
trap - EXIT

printf 'Built review package archive: %s\n' "$archive"
