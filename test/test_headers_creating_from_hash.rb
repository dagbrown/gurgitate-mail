# -*- encoding : utf-8 -*-
builddir = File.join(File.dirname(__FILE__),"..")

unless $:[0] == builddir
    $:.unshift builddir
end

require "test/test_headers_meddling_with_headers"

class TC_Headers_creating_from_hash < TC_Headers_meddling_with_headers
    def setup
        $:.unshift File.dirname(__FILE__)
        require "gurgitate/headers"

        @headers = Gurgitate::Headers.new :from => "fromline@example.com",
            :to => "toline@example.com",
            :subject => "Subject line"
    end
end

