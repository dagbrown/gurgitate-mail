#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"

# change this on installation to taste
GLOBAL_RULES="/etc/gurgitate-rules"
GLOBAL_RULES_POST="/etc/gurgitate-rules-default"

gurgitate = Gurgitate::Gurgitate.new(STDIN)

gurgitate.add_rules(GLOBAL_RULES, :system => true)
gurgitate.add_rules(:default)
gurgitate.add_rules(GLOBAL_RULES_POST, :system => true)
gurgitate.process
