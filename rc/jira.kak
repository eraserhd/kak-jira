# https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .+\.jira %{
    set-option buffer filetype jira
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group jira-load-languages global WinSetOption filetype=jira %{
    hook -group jira-load-languages window NormalIdle .* jira-load-languages
    hook -group jira-load-languages window InsertIdle .* jira-load-languages
}

hook -group jira-highlight global WinSetOption filetype=jira %{
    require-module jira
    try %{ require-module java }
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

# Monospaced
add-highlighter shared/jira/inline/text/ regex \B(?:\{\{(?:[^\\\n]|\\[^\n])*?\}\})\B 0:mono

# Strong
add-highlighter shared/jira/inline/text/ regex \s\*(?:[^\\\n\*]|\\[^\n])+?\*\B 0:+b
add-highlighter shared/jira/inline/text/ regex \h\*(?:[^\\\n\*]|\\[^\n])+?\*\B 0:+b

# Emphasis
add-highlighter shared/jira/inline/text/ regex \b_(?:[^\\\n_]|\\[^\n])+?_\b 0:+i

# Superscript/Subscript
add-highlighter shared/jira/inline/text/ regex \B(\^)((?:[^\\\n^]|\\[^\n])+)(\^)\B 1:comment 2:meta 3:comment
add-highlighter shared/jira/inline/text/ regex \B(~)((?:[^\\\n^]|\\[^\n])+)(~)\B 1:comment 2:string 3:comment

# Added/Deleted (try until Kakoune has had strikethrough for a while)
add-highlighter shared/jira/inline/text/ regex (\+)((?:[^\\\n+]|\\[^\n])+?)(\+) 1:comment 2:+u 3:comment
try %{ add-highlighter -- shared/jira/inline/text/ regex (-)((?:[^\\\n-]|\\[^\n])+?)(-) 1:comment 2:+s 3:comment }

# Links
add-highlighter shared/jira/inline/text/ regex \[[^\]\n]*\] 0:link
add-highlighter shared/jira/inline/text/ regex ^\{anchor:[^}\n]*\} 0:meta

# Images and Attachments
add-highlighter shared/jira/inline/text/ regex ^!(?:[^!\\\n]|\\[^\n])*! 0:meta

# Noformat
add-highlighter shared/jira/noformat region -match-capture ^\{noformat\}\h* ^\{noformat\}\h* regions
add-highlighter shared/jira/noformat/ default-region fill comment
add-highlighter shared/jira/noformat/inner region \A\{noformat\}\K (?=\{noformat\}) fill mono

# Code
# ‾‾‾‾‾‾‾‾‾‾‾‾

# Supported by JIRA, but not supported by Kakoune as of 2020-10-30:
#   ActionScript, Ada, AppleScript, C#, Erlang, Groovy, Nyan, R, VisualBasic.
declare-option -hidden str-to-str-map jira_language_mappings \
  ':c=c' ':cpp=cpp' ':c++=cpp' ':css=css' ':go=go' ':haskell=haskell' ':html=html' \
  '=java' ':java=java' ':javascript=javascript' ':json=json' ':lua=lua' ':objc=objc' \
  ':perl=perl' ':php=php' ':python=python' ':ruby=ruby' \
  ':scala=scala' ':bash=sh' ':sql=sql' ':swift=swift' ':xml=xml'

# For debugging:
#evaluate-commands %sh{
#  eval set -- "$kak_quoted_opt_jira_language_mappings"
#  while [ $# -gt 0 ]; do
#    lang="${1##*=}"
#    shift
#    printf 'try %%{ remove-highlighter shared/jira/%s }\n' "$lang"
#  done
#}
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
