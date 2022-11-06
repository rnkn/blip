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
blip_file="${BLIP_FILE:-${HOME}/.bookmarks/bookmarks.tsv}"

fail() { echo "$1"; exit 1; }
int_p() { expr "$1" : '[0-9][0-9]*$' > /dev/null; }
tbc() { echo "$1 not yet implemented"; }

# usage()
# returns: usage string
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
		touch "$blip_file"
	fi
	return 0
}

# get_linenum()
get_linenum() {
	awk -v url="$url" '$1 == url { print NR }' < "$blip_file"
}

# add(url)
# append $url too $blip_file
# returns: 0
add() {
	[ -n "$1" ] || fail "Missing argument"
	url="$1"
	exists=$(awk -v url="$url" '$1 == url' < "$blip_file")
	if [ -n "$exists" ]; then
		fail "Bookmark $url already exists"
	else
		printf "%s\n" "$url" >> "$blip_file"
	fi
	return 0
}

# tag(query, tag, [tag ...])
# returns 0
tag() {
	tbc "tag"
}

# edit(query)
# returns: 0
edit() {
	tbc "edit"
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
	fields="$1"
	[ "$2" -gt 0 ] && linenum='FNR,'
	search_scope="$3"
	query="$4"
	urls=$(collect)
	if $(int_p "$query"); then
		urls=$(echo "$urls" | awk -F "\t" "FNR == $query { print $linenum $fields }")
	elif [ -n "$query" ]; then
		urls=$(echo "$urls" | awk -F "\t" "$search_scope ~ /$query/ { print $linenum $fields }")
	else
		urls=$(echo "$urls" | awk -F "\t" "{ print $linenum $fields }")
	fi
	[ -n "$urls" ] && echo "$urls" | column -t
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
	url_count=$(echo "$urls" | wc -l | xargs)
	if [ "$url_count" -gt "$browse_limit" ]; then
		cat <<-EOF
			Attempted to open $url_count bookmarks at once but limit is $browse_limit
			Try opening fewer bookmarks or set a higher \$BLIP_BROWSE_LIMIT
		EOF
		exit 1
	else
		for url in $urls
		do
			"$BLIP_BROWSER" "$url"
		done
	fi
	return 0
}

# main(arg, [arg ...])
# returns: 0
main() {
	print_linenum=1
	print_fields='$1'
	search_scope='$0'
	while getopts 'htcnv' option; do
		case "$option" in
			(h)		usage; return 0 ;;
			(v)		echo "$program v$version"; return 0 ;;
			(t)		include_tags=1 ;;
			(c)		include_comment=1 ;;
			(n)		print_linenum=0 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	case "$1" in
		(init)			init ;;
		(ls|list|find)		shift; list "$print_fields" "$print_linenum" "$search_scope" "$@" ;;
		(a|add)			shift; add "$@" ;;
		(o|open|b|browse)	shift; browse "$search_scope" "$@" ;;
		(t|tag)			shift; tag "$@" ;;
		(e|edit)		shift; edit "$@" ;;
		(v|version)		echo "$program v$version"; return 0 ;;
		(--help|help|*)		usage; return 0 ;;
	esac
	return 0
}

main "$@"
