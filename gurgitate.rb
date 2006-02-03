#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"

# change this on installation to taste
GLOBAL_RULES="/etc/gurgitate-rules"

Gurgitate::Gurgitate.new(STDIN) .
    process(GLOBAL_RULES,:chain => true, :system => true) .
    process
