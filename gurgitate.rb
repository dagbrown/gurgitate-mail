#------------------------------------------------------------------------
# Mail filter invocation script
#------------------------------------------------------------------------

require "gurgitate-mail"

message=Gurgitate::Gurgitate.new(STDIN);
message.process
