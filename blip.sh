#!/bin/sh
#
# ISC License
#
# Copyright (c) 2020-2021 Paul W. Rankin <pwr@bydasein.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

program=$(basename "$0")
version=0.1.0
blip_file="${BLIP_FILE:-${HOME}/.blip/bookmarks.tsv}"

fail() { echo "$1"; exit 1; }
int_p() { expr "$1" : '[0-9][0-9]*$' >/dev/null; }

usage() {
	cat <<EOF
$program v$version usage:
  blip [COMMAND] QUERY
    QUERY can be a match string or a bookmark number
commands:
  $program init [DIR]
    initialize an empty bookmarks repository in
    $PREFIX or DIR
  $program add URL [TAG TAG ...]
    add URL to bookmarks file
  $program list|find [-t -u] QUERY
    list bookmarks matching QUERY
  $program open|browse QUERY
    open bookmarks matching QUERY in ${BLIP_BROWSER:-\$BLIP_BROWSER}
  $program tag QUERY TAG [TAG ...]
    add TAGs to bookmarks matching QUERY
  $program edit QUERY
    edit bookmarks matching QUERY in \$EDITOR
  $program fetchtitles
    fetch all bookmark titles from the web
  $program help
    print this help message
  $program version
    print version info
  $program STRING
    identical to $program list QUERY
  $program NUMBER
    identical to $program open NUMBER
  most commands can be used in unambiguous diminutive form, e.g.
    blip a URL
    blip ls QUERY
    blip b QUERY
EOF
}

# init()
# create $blip_file
# returns: 0
init() {
	if [ -f "$blip_file" ]; then
		fail "$blip_file already exists"
	else
		mkdir -p $(dirname "$blip_file")
		touch "$blip_file"
	fi
}

tbc() { echo "$1 not yet implemented"; }

add() {
	tbc "add"
}

tag() {
	tbc "tag"
}

edit() {
	tbc "edit"
}

fetchtitles() {
	tbc "fetchtitles"
}

# collect()
# returns: list of non-blank lines in $blip_file
collect() {
	[ -r "$blip_file" ] || fail "$blip_file not found"
	awk '$0 !~ /^ *$/' < "$blip_file"
}

# list(print_fields, print_linenum, search_scope, query)
# returns: printed list of matching bookmarks
list() {
	print_fields="$1"
	[ -n "$2" ] && print_linenum='FNR,'
	search_scope="$3"
	query="$4"
	urls=$(collect)
	if $(int_p "$query"); then
		urls=$(echo "$urls" | awk -F "\t" "FNR == $query { print $print_linenum $print_fields }")
	elif [ -n "$query" ]; then
		urls=$(echo "$urls" | awk -F "\t" "$search_scope ~ /$query/ { print $print_linenum $print_fields }")
	else
		urls=$(echo "$urls" | awk -F "\t" "{ print $print_linenum $print_fields }")
	fi
	[ -n "$urls" ] && echo "$urls" | column -ts $'\t'
}

# browse(search_scope, query)
# open bookmarks matching QUERY with $BLIP_BROWSER
# returns: 0
browse() {
	search_scope="$1"
	query="$2"
	browse_limit="${BLIP_BROWSE_LIMIT:-12}"
	[ -n "$BLIP_BROWSER" ] || fail "\$BLIP_BROWSER not set"
	urls=$(collect)
	if $(int_p "$query"); then
		urls=$(echo "$urls" | awk -F "\t" "FNR == $query { print \$1 }")
	elif [ -n "$query" ]; then
		urls=$(echo "$urls" | awk -F "\t" "$search_scope ~ /$query/ { print \$1 }")
	fi
	url_count=$(echo "$urls" | wc -l)
	if [ "$url_count" -gt "$browse_limit" ]; then
		cat <<-EOF
			Attempted to open $url_count bookmarks at once but limit is $browse_limit
			Try opening fewer bookmarks or set a higher $BLIP_BROWSE_LIMIT
		EOF
		exit 1
	else
		for url in $urls
		do
			"$BLIP_BROWSER" "$url"
		done
	fi
}

main() {
	print_linenum=1
	print_fields='$1'
	search_scope='$0'
	case "$1" in
		(init)				init ;;
		(ls|list|find)		shift; list "$print_fields" "$print_linenum" "$search_scope" "$@" ;;
		(a|add)				shift; add "$@" ;;
		(o|open|b|browse)	shift; browse "$search_scope" "$@" ;;
		(t|tag)				shift; tag "$@" ;;
		(e|edit)			shift; edit "$@" ;;
		(fetchtitles)		shift; fetchtitles ;;
		(-v|v|version)		echo "$program v$version" ;;
		(-h|--help|help|*)	usage ;;
	esac
}

main "$@"
