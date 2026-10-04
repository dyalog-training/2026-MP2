#!/usr/bin/env bash
# Build the workshop's generated files: an .html page next to every .md file, made with pandoc.
# Usage, from any folder:  ./build.sh
# Needs pandoc 2.19 or later (for --embed-resources), perl, and docs/mkdocs/mkdocs.css.
# The CSS is embedded in each page, so the pages need nothing else to display.
# Skips .git, node_modules, and Source (third-party tools).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
css="$root/docs/mkdocs/mkdocs.css"  # /docs/mkdocs/mkdocs.css, from the repository root

command -v pandoc >/dev/null || { echo "build.sh: pandoc is not installed" >&2; exit 1; }
[ -f "$css" ] || { echo "build.sh: cannot find $css" >&2; exit 1; }

# The CSS is Material for MkDocs', which styles its own page structure, not plain HTML elements.
# This filter wraps each document in that structure (container, grid, content, typeset), and makes links to
# other .md files point at their .html pages.
filter="$(mktemp --suffix=.lua)"
trap 'rm -f "$filter"' EXIT
cat > "$filter" <<'EOF'
-- Links to other Markdown files point at their .html pages instead (web links are left alone)
function Link(link)
  if not link.target:match("^%a[%w+.-]*:") then
    link.target = link.target:gsub("%.md$", ".html"):gsub("%.md#", ".html#")
  end
  return link
end
function Pandoc(doc)
  local function div(classes, blocks) return pandoc.Div(blocks, pandoc.Attr("", classes)) end
  doc.blocks = {div({"md-container"}, {div({"md-main"}, {div({"md-main__inner", "md-grid"},
    {div({"md-content"}, {div({"md-content__inner", "md-typeset"}, doc.blocks)})})})})}
  return doc
end
EOF

count=0
while IFS= read -r -d '' md; do
    html="${md%.md}.html"
    # The page title is the file's first level-1 heading, or its file name if it has none
    title="$(sed -n 's/^# //p' "$md" | head -n 1 | tr -d '\r')"
    [ -n "$title" ] || title="$(basename "$md" .md)"
    # GitHub-flavoured Markdown, as on GitHub: no "smart" typography (which would turn -- into a dash, against the
    # project's rules), and heading ids that match GitHub's, so links such as README.md#3-run-setup work
    pandoc "$md" --from=gfm --standalone --embed-resources --css="$css" --metadata pagetitle="$title" --lua-filter="$filter" -o "$html"
    # pandoc (3.12) embeds the CSS as a data: URL without escaping "#", so a browser reads only the CSS
    # before the first "#" (the rest is taken as a URL fragment). Escape it as %23.
    perl -0pi -e 's{(<link[^>]*href="data:text/css[^"]*)}{($x=$1)=~s/#/%23/g;$x}ge' "$html"
    count=$((count + 1))
done < <(find "$root" \( -name .git -o -name node_modules -o -path "$root/Source" \) -prune -o -name '*.md' -type f -print0)
echo "build.sh: wrote $count .html files"
