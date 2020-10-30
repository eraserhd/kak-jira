# https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .+\.jira %{
    set-option buffer filetype jira
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group jira-load-languages global WinSetOption filetype=markdown %{
    hook -group jira-load-languages window NormalIdle .* jira-load-languages
    hook -group jira-load-languages window InsertIdle .* jira-load-languages
}

hook -group jira-highlight global WinSetOption filetype=jira %{
    require-module jira
    try %{ require-module java }
    add-highlighter window/jira ref jira
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/jira }
}

declare-option -hidden str-to-str-map jira_language_mappings
  # ActionScript, Ada, AppleScript, C#, Erlang, Go, Groovy, Haskell,
  # HTML, JavaScript, JSON, Lua, Nyan, Objc, Perl, PHP, Python, R, Ruby, Scala,
  # SQL, Swift, VisualBasic.
set-option -add global jira_language_mappings \
  ':c=c' ':cpp=cpp' ':c++=cpp' ':css=css' ':go=go' '=java' ':java=java' ':bash=sh' \
  ':sql=sql' ':xml=xml'

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

#FIXME:
evaluate-commands %sh{
  eval set -- "$kak_quoted_opt_jira_language_mappings"
  while [ $# -gt 0 ]; do
    lang="${1##*=}"
    shift
    printf 'try %%{ remove-highlighter shared/jira/%s }\n' "$lang"
  done
}
evaluate-commands %sh{
  eval set -- "$kak_quoted_opt_jira_language_mappings"
  langs=' '
  while [ $# -gt 0 ]; do
    pattern="${1%=*}"
    lang="${1##*=}"
    shift
    case "$langs" in
      *" $lang "*) ;;
                *) langs="$langs $lang ";;
    esac
    eval 'lang_'"$lang"'_patterns="${lang_'"$lang"'_patterns}|\Q${pattern}\E"'
  done
  for lang in $langs; do
    eval 'pattern="${lang_'"$lang"'_patterns#|}"'
    printf 'add-highlighter shared/jira/%s region -match-capture ^\\{code(?i)(?:%s)(?I)\\}\\h* ^\\{code\\}\\h* regions\n' "$lang" "$pattern"
    printf 'add-highlighter shared/jira/%s/ default-region fill comment\n' "$lang"
    printf 'add-highlighter shared/jira/%s/inner region \A\\{code.*?\\}\\K (?=\\{code\\}) ref %s\n' "$lang" "$lang"
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

define-command -hidden jira-load-languages %{
    evaluate-commands -draft %{
        try %{
            execute-keys 'gtGbGls\{code:\K[^\}]+<ret>'
            evaluate-commands %sh{
              module_names=''
              add_module_name() {
                case " $module_names " in
                  *" $1 "*) ;;
                         *) module_names="${module_names} $1";;
                esac
              }
              find_module_name() {
                specified=`printf %s "$1" |tr 'A-Z' 'a-z'`
                eval set -- "$kak_quoted_opt_jira_language_mappings"
                while [ $# -gt 0 ]; do
                  if [ "${1%=*}" = ":$specified" ]; then
                    add_module_name "${1##*=}"
                    break
                  fi
                  shift
                done
              }
              eval set -- "$kak_quoted_selections"
              while [ $# -gt 0 ]; do
                find_module_name "$1"
                shift
              done
              for module_name in $module_names; do
                printf 'try %%{ require-module %s }\n' "$module_name"
              done
            }
        }
    }
}

}
