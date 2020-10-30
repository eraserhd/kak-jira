# https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .+\.jira %{
    set-option buffer filetype jira
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group jira-highlight global WinSetOption filetype=jira %{
    require-module jira

    add-highlighter window/jira ref jira
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/jira }
}

provide-module jira %{

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/jira regions
add-highlighter shared/jira/inline default-region regions
add-highlighter shared/jira/inline/text default-region group

# Titles and headerss (one-line style)
add-highlighter shared/jira/inline/text/ regex ^h1\.[^\n]*$ 0:title
add-highlighter shared/jira/inline/text/ regex ^h[2-6]\.[^\n]*$ 0:header

# Bulleted and numbered lists
add-highlighter shared/jira/inline/text/ regex ^\h*(?<bullet>[-\*#])\h+[^\n]+$ 0:list bullet:bullet
add-highlighter shared/jira/inline/text/ regex ^\h*(?<bullet>[-\*#]+)\h+[^\n]+(\n\h+[^-\*\n]*)?$ 0:list bullet:bullet

# Code
# ‾‾‾‾‾‾‾‾‾‾‾‾

evaluate-commands %sh{
  languages="
    cpp java
  "
  for lang in $languages; do
    if [ "$lang" = java ]; then
      lang_part="(?::java)?"
    else
      lang_part=":$lang"
    fi
    printf 'add-highlighter shared/jira/%s region -match-capture ^\\{code%s\\}\\h* ^\\{code\\}\h* regions\n' "$lang" "$lang_part"
    printf 'add-highlighter shared/jira/%s/ default-region fill meta\n' "$lang"
    printf 'add-highlighter shared/jira/%s/inner region \A\\{code:.*?\\}\\K (?=\\{code\\}) ref %s\n' "$lang" "$lang"
  done
}

#add-highlighter shared/jira/ regex ^(-{3,})\n[^\n\h].*?\n(-{3,})$ 0:block
#add-highlighter shared/jira/ regex ^(={3,})\n[^\n\h].*?\n(={3,})$ 0:block
#add-highlighter shared/jira/ regex ^(~{3,})\n[^\n\h].*?\n(~{3,})$ 0:block
#add-highlighter shared/jira/ regex ^(\*{3,})\n[^\n\h].*?\n(\*{3,})$ 0:block

# Monospaced
add-highlighter shared/jira/inline/text/ regex \B(?:\{\{(?:[^\\\n]|\\[^\n])*?\}\})\B 0:mono

# Strong
add-highlighter shared/jira/inline/text/ regex \s\*(?:[^\\\n\*]|\\[^\n])+?\*\B 0:+b
add-highlighter shared/jira/inline/text/ regex \h\*(?:[^\\\n\*]|\\[^\n])+?\*\B 0:+b

# Emphasis
add-highlighter shared/jira/inline/text/ regex \b_(?:[^\\\n_]|\\[^\n])+?_\b 0:+i

# Attributes
#add-highlighter shared/jira/ regex ^:(?:(?<neg>!?)[-\w]+|[-\w]+(?<neg>!?)): 0:meta neg:operator
#add-highlighter shared/jira/ regex [^\\](\{[-\w]+\})[^\\]? 1:meta

# Options
#add-highlighter shared/jira/ regex ^\[[^\n]+\]$ 0:operator

# Admonition pargraphs
#add-highlighter shared/jira/ regex ^(NOTE|TIP|IMPORTANT|CAUTION|WARNING): 0:block
#add-highlighter shared/jira/ regex ^\[(NOTE|TIP|IMPORTANT|CAUTION|WARNING)\]$ 0:block

# Links, inline macros
#add-highlighter shared/jira/ regex \b((?:https?|ftp|irc://)[^\h\[]+)\[([^\n]*)?\] 1:link 2:+i
#add-highlighter shared/jira/ regex (link|mailto):([^\n]+)(?:\[([^\n]*)\]) 1:keyword 2:link 3:+i
#add-highlighter shared/jira/ regex (xref):([^\n]+)(?:\[([^\n]*)\]) 1:keyword 2:meta 3:+i
#add-highlighter shared/jira/ regex (<<([^\n><]+)>>) 1:link 2:meta


# Commands
# ‾‾‾‾‾‾‾‾

}
