#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"

Gurgitate::Gurgitate.new(STDIN).process
