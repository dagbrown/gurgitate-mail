#!/opt/bin/ruby -w

#------------------------------------------------------------------------
# 
#------------------------------------------------------------------------

require 'test/unit'
require 'test/unit/ui/console/testrunner'

class TC_Header < Test::Unit::TestCase

    def setup
        require './gurgitate-mail'
    end

    # def teardown
    # end

    def test_simple_header
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(h.name,"From", "Simple header name is From")
        assert_equal(h.contents,"fromheader@example.com", 
            "Contents is fromheader@example.com")
        assert_equal(h.value,"fromheader@example.com", 
            "Contents is fromheader@example.com")
    end

    def test_malcapitalized_header
        h=Gurgitate::Header.new("FROM: fromheader@example.com")
        assert_equal(h.name,"From", "Badly-capitalized header is From")
        assert_equal(h.contents,"fromheader@example.com", 
            "Badly-capitalized header")
        assert_equal(h.value,"fromheader@example.com", 
            "Badly-capitalized header")
    end

    def test_bad_headers
        assert_raises(Gurgitate::IllegalHeader,"Empty name") {
            h=Gurgitate::Header.new(": Hi")
        }
#         assert_raises(Gurgitate::IllegalHeader,"Empty header contents") {
#             h=Gurgitate::Header.new("From: ")
#         }
        assert_raises(Gurgitate::IllegalHeader,"Bad header syntax") {
            h=Gurgitate::Header.new("This is completely wrong")
        }
    end
    def test_extending_header
        h=Gurgitate::Header.new("From: fromheader@example.com")
        h << "  (Dave Brown)"
        assert_equal(h.name,"From","Extended header is From")
        assert_equal(h.contents,"fromheader@example.com\n  (Dave Brown)",
            "Extended header contains all data")
        assert_equal(h.contents,h.value,"Contents same as value")
    end

    def test_conversion_to_String
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(h.to_s,"From: fromheader@example.com", "Conversion to string returns input")
    end

    def test_regex_match
        h=Gurgitate::Header.new("From: fromheader@example.com")
        assert_equal(0,h.matches(/fromheader/),"Matches regex that would match input")
        assert_equal(nil,h.matches(/notininput/),"Does not match regex that would not match input")
    end
end

class TC_Headers < Test::Unit::TestCase
    def setup
        require './gurgitate-mail'
    end

    def test_single_header
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("fromline@example.com",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_fromline_simple_username
        h=Gurgitate::Headers.new(<<'EOF'
From fromline Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("fromline",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_fromline_no_username
        h=Gurgitate::Headers.new(<<'EOF'
From  Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("",h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_missing_toline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_multiple_headers
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_missing_fromline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_multiline_headers
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Oct 25 12:58:31 PDT 2003
From: fromheader@example.com
To: toheader@example.com,
    nexttoheader@example.com
Subject: Subject line
EOF
        )
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com,\n    nexttoheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_multiline_headers_with_extra_colons
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Oct 25 12:58:31 PDT 2003
From: fromheader@example.com
To: toheader@example.com,
    nexttoheader@example.com (The test: header)
Subject: Subject line
EOF
        )
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com,\n    nexttoheader@example.com (The test: header)",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_multiline_headers_with_various_levels_of_indentation
        h=Gurgitate::Headers.new(<<'EOF'
From fromline@example.com Sat Oct 25 12:58:31 PDT 2003
From: fromheader@example.com
To: toheader@example.com,
    nexttoheader@example.com,
        thirdtoheader@example.com,
    fourthtoheader@example.com
Subject: Subject line
EOF
        )
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal("toheader@example.com,\n    nexttoheader@example.com,\n        thirdtoheader@example.com,\n    fourthtoheader@example.com",h["To"][0].contents)
        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Subject line",h["Subject"][0].contents)
    end

    def test_a_header_that_actually_crashed_gurgitate
        h=Gurgitate::Headers.new(<<'EOF'
Return-path: <nifty-bounces@neurotica.com>
Received: from pd8mr3no.prod.shaw.ca
 (pd8mr3no-qfe2.prod.shaw.ca [10.0.144.160]) by l-daemon
 (iPlanet Messaging Server 5.2 HotFix 1.16 (built May 14 2003))
 with ESMTP id <0HO6002FDGPREL@l-daemon> for dagbrown@shaw.ca; Tue,
 11 Nov 2003 00:56:15 -0700 (MST)
Received: from pd7mi4no.prod.shaw.ca ([10.0.149.117])
 by l-daemon (iPlanet Messaging Server 5.2 HotFix 1.18 (built Jul 28 2003))
 with ESMTP id <0HO60055LGPR40@l-daemon> for dagbrown@shaw.ca
 (ORCPT dagbrown@shaw.ca); Tue, 11 Nov 2003 00:56:15 -0700 (MST)
Received: from venom.easydns.com (smtp.easyDNS.com [216.220.40.247])
 by l-daemon (iPlanet Messaging Server 5.2 HotFix 1.18 (built Jul 28 2003))
 with ESMTP id <0HO60079HGPR79@l-daemon> for dagbrown@shaw.ca; Tue,
 11 Nov 2003 00:56:15 -0700 (MST)
Received: from ohno.mrbill.net (ohno.mrbill.net [207.200.6.75])
    by venom.easydns.com (Postfix) with ESMTP id D6493722BB for
 <dagbrown@lart.ca>; Tue, 11 Nov 2003 02:53:50 -0500 (EST)
Received: by ohno.mrbill.net (Postfix)  id ED0AD53380; Tue,
 11 Nov 2003 01:56:13 -0600 (CST)
Received: from mail.neurotica.com (neurotica.com [207.100.203.161])
    by ohno.mrbill.net (Postfix) with ESMTP id 5CD465337F   for
 <dagbrown@dagbrown.com>; Tue, 11 Nov 2003 01:56:13 -0600 (CST)
Received: from mail.neurotica.com (localhost [127.0.0.1])
    by mail.neurotica.com (Postfix) with ESMTP  id CDAA2364C; Tue,
 11 Nov 2003 02:56:03 -0500 (EST)
Received: from smtpzilla5.xs4all.nl (smtpzilla5.xs4all.nl [194.109.127.141])
    by mail.neurotica.com (Postfix) with ESMTP id B6A22361E for
 <nifty@neurotica.com>; Tue, 11 Nov 2003 02:56:00 -0500 (EST)
Received: from xs1.xs4all.nl (xs1.xs4all.nl [194.109.21.2])
    by smtpzilla5.xs4all.nl (8.12.9/8.12.9) with ESMTP id hAB7u5ZZ042116    for
 <nifty@neurotica.com>; Tue, 11 Nov 2003 08:56:05 +0100 (CET)
Received: from xs1.xs4all.nl (wstan@localhost.xs4all.nl [127.0.0.1])
    by xs1.xs4all.nl (8.12.10/8.12.9) with ESMTP id hAB7u5xE048677  for
 <nifty@neurotica.com>; Tue,
 11 Nov 2003 08:56:05 +0100 (CET envelope-from wstan@xs4all.nl)
Received: (from wstan@localhost)    by xs1.xs4all.nl (8.12.10/8.12.9/Submit)
 id hAB7u4sZ048676  for nifty@neurotica.com; Tue,
 11 Nov 2003 08:56:04 +0100 (CET envelope-from wstan)
Date: Tue, 11 Nov 2003 08:56:04 +0100
From: William Staniewicz <wstan@xs4all.nl>
Subject: Re: [nifty] Ping...
In-reply-to: <9636B78C-140B-11D8-9EE6-003065D0C184@nimitzbrood.com>
Sender: nifty-bounces@neurotica.com
To: Nifty <nifty@neurotica.com>
Cc:
Errors-to: nifty-bounces@neurotica.com
Reply-to: Nifty <nifty@neurotica.com>
Message-id: <20031111075604.GE79497@xs4all.nl>
MIME-version: 1.0
Content-type: text/plain; charset=us-ascii
Content-disposition: inline
Precedence: list
X-BeenThere: nifty@mail.neurotica.com
Delivered-to: dagbrown@mrbill.net
Delivered-to: nifty@neurotica.com
User-Agent: Mutt/1.4.1i
X-Original-To: nifty@neurotica.com
References: <9636B78C-140B-11D8-9EE6-003065D0C184@nimitzbrood.com>
X-Mailman-Version: 2.1.2
List-Post: <mailto:nifty@mail.neurotica.com>
List-Subscribe: <http://mail.neurotica.com:8080/mailman/listinfo/nifty>,
    <mailto:nifty-request@mail.neurotica.com?subject=subscribe>
List-Unsubscribe: <http://mail.neurotica.com:8080/mailman/listinfo/nifty>,
    <mailto:nifty-request@mail.neurotica.com?subject=unsubscribe>
List-Help: <mailto:nifty-request@mail.neurotica.com?subject=help>
List-Id: Nifty  <nifty.mail.neurotica.com>
Original-recipient: rfc822;dagbrown@shaw.ca
EOF
        )
        assert_equal(h.from,"nifty-bounces@neurotica.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("William Staniewicz <wstan@xs4all.nl>",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
        assert_equal('Nifty <nifty@neurotica.com>',h["To"][0].contents)

        assert_equal(1,h["Subject"].length)
        assert_equal("Subject",h["Subject"][0].name)
        assert_equal("Re: [nifty] Ping...",h["Subject"][0].contents)
    end
end

def runtests
    Test::Unit::UI::Console::TestRunner.run(TC_Header)
    Test::Unit::UI::Console::TestRunner.run(TC_Headers)
end

if __FILE__ == $0 then
    if(ARGV[0] == '-c')
        require 'coverage'
    end
    runtests
end
