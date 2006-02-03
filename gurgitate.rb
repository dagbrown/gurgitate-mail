#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"

# change this on installation to taste
GLOBAL_RULES="/etc/gurgitate-rules"
GLOBAL_RULES_POST="/etc/gurgitate-rules-default"

Gurgitate::Gurgitate.new(STDIN) .
    process(GLOBAL_RULES,:chain => true, :system => true) .
    process(:default, :chain => true) .
    process(GLOBAL_RULES_POST, :system => true)
