require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'stringio'

builddir = File.join(File.dirname(__FILE__),"..")
unless $:[0] == builddir
    $:.unshift builddir
end

class TC_Headers < Test::Unit::TestCase
    def setup
        $:.unshift File.dirname(__FILE__)
        require "gurgitate/headers"
    end

    def test_single_header
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
EOF
        )
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
        assert_equal("fromline", h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal nil, h["To"]
    end

    def basic_header_test
        h = Gurgitate::Headers.new(<<'EOF', "sender@example.com", "recipient@example.com")
From: fromheader@example.com
To: toheader@example.com
Subject: Subject
EOF
        assert_equal(1,h["From"].length)
        assert_equal("From", h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)

        yield h
    end

    def test_changing_headers
        basic_header_test do |h|
            h["From"].sub! "fromheader", "changedheader"

            assert_equal("changedheader@example.com",h["From"][0].contents)
        end
    end


    def test_altered_headers
        basic_header_test do |h|
            new_header = h["From"].sub "fromheader", "changedheader"

            assert Gurgitate::HeaderBag === new_header
            assert_equal("changedheader@example.com",
                         new_header[0].contents, "sub didn't change contents")
            assert_equal("fromheader@example.com",h["From"][0].contents,
                         "sub is changing in-place")
        end
    end

    def test_matches
        h = Gurgitate::Headers.new(<<'EOF', "sender@example.com", "recipient@example.com")
From: fromheader@example.com
To: toheader@example.com
Subject: Subject
EOF
        assert h.matches(["From", "To"], /example.com/)
        assert !h.matches(["From", "To"], /example.net/)

        assert h.matches("From", /example.com/)
        assert !h.matches("From", /example.net/)
    end


    def test_fromline_no_username
        h=Gurgitate::Headers.new(<<'EOF'
From  Sat Sep 27 12:20:25 PDT 2003
From: fromheader@example.com
EOF
        )
        assert_equal("", h.from)
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_missing_toline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
EOF
        )
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
    end

    def test_sender_and_recipient
        h = Gurgitate::Headers.new(<<'EOF', "sender@example.com", "recipient@example.com")
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        assert_equal('sender@example.com', h.from)
        assert_equal('recipient@example.com', h.to)
    end

    def standard_headers_tests h
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

    def multiple_headers_test
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        standard_headers_tests h
    end

    def test_missing_fromline
        h=Gurgitate::Headers.new(<<'EOF'
From: fromheader@example.com
To: toheader@example.com
Subject: Subject line
EOF
        )
        assert_equal('fromheader@example.com',h.from)
        standard_headers_tests h
    end

    def multiline_default_tests h
        assert_equal(h.from,"fromline@example.com")
        assert_equal(1,h["From"].length)
        assert_equal("From",h["From"][0].name)
        assert_equal("fromheader@example.com",h["From"][0].contents)
        assert_equal(1,h["To"].length)
        assert_equal("To",h["To"][0].name)
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
        multiline_default_tests h

        assert_equal("toheader@example.com,\n    nexttoheader@example.com",h["To"][0].contents)
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
        multiline_default_tests h

        assert_equal("toheader@example.com,\n    nexttoheader@example.com (The test: header)",h["To"][0].contents)
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
        multiline_default_tests h
        assert_equal("toheader@example.com,\n    nexttoheader@example.com,\n        thirdtoheader@example.com,\n    fourthtoheader@example.com",h["To"][0].contents)
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

    def test_another_crashy_set_of_headers
        h=Gurgitate::Headers.new(<<'EOF'
From HEYITBLEWUP Fri Nov 21 14:41:08 PST 2003
Received: from unknown (harley.radius [192.168.0.123]) by yoda.radius with SMTP (Microsoft Exchange Internet Mail Service Version 5.5.2653.13)
	id LYN7YZKG; Wed, 9 Jul 2003 14:36:40 -0700
Subject: IAP password
EOF
        )
        assert_equal(h.from,"HEYITBLEWUP")
        assert_equal(nil,h["From"])
        assert_equal("IAP password",h["Subject"][0].contents)
    end

    def test_fromheader_no_hostname # illegal from header?
        m=<<'EOF'
From HEYITBLEWUP Sat Mar 27 16:02:12 PST 2004
Received: from ohno.mrbill.net (ohno.mrbill.net [207.200.6.75])
        by lart.ca (Postfix) with ESMTP id A485F104CA9
        for <dagbrown@lart.ca>; Sat, 27 Mar 2004 15:58:06 -0800 (PST)
Received: by ohno.mrbill.net (Postfix)
        id 0D3423A289; Sat, 27 Mar 2004 17:58:42 -0600 (CST)
Delivered-To: dagbrown@mrbill.net
Received: from 66-168-59-126.jvl.wi.charter.com (66-168-59-126.jvl.wi.charter.com [66.168.59.126])
        by ohno.mrbill.net (Postfix) with SMTP id 948BD3A288
        for <dagbrown@dagbrown.com>; Sat, 27 Mar 2004 17:58:41 -0600 (CST)
X-Message-Info: HOCBSQX
Message-Id: <20040327235841.948BD3A288@ohno.mrbill.net>
Date: Sat, 27 Mar 2004 17:58:41 -0600 (CST)
From: ""@
To: undisclosed-recipients: ;
EOF
        h=Gurgitate::Headers.new(m)
        assert_equal(%{""@},h["From"][0].contents)
        assert_equal(1,h["From"].length)
    end

    def editing_template
        m = <<'EOF'
From fromline@example.com Sat Oct 25 12:58:31 PDT 2003
From: fromline@example.com
To: toline@example.com
Subject: Subject line
EOF
        return m.clone
    end

    def test_editing_header
        m = editing_template

        h=Gurgitate::Headers.new(m)
        h["From"]="anotherfromline@example.com"
        assert_equal("anotherfromline@example.com",h["From"][0].contents,
            "From line correctly changed")
        assert_match(/^From: anotherfromline@example.com$/,h.to_s,
            "From line correctly turns up in finished product")
    end

    def test_editing_from
        m = editing_template

        h=Gurgitate::Headers.new(m)
        t=Time.new.to_s
        h.from="anotherfromline@example.com"
        assert_equal("anotherfromline@example.com",h.from,
            "Envelope from correctly changed")
        assert_match(/^From anotherfromline@example.com #{Regexp.escape(t)}/,
            h.to_mbox, "Envelope from changed in finished product")
    end

    def test_match_multiple_headers
        m = editing_template

        h=Gurgitate::Headers.new(m)
        assert_equal(true,h["From","To"] =~ /fromline@example.com/,
            "headers contains fromline")
        assert_equal(true,h["From","To"] =~ /toline@example.com/,
            "headers contains toline")
        assert_equal(false,h["From","To"] =~ /nonexistent@example.com/,
            "headers do not contain nonexistent value")
        assert(!(h["Rabbit"] =~ /nonexistent/),
            "Asking for a nonexistent header")
    end

    def test_broken_spam
        m=<<'EOF'
Return-Path: kirstenparsonsry@yahoo.com
Delivery-Date: Fri May 21 19:42:02 PDT 
Return-Path: kirstenparsonsry@yahoo.com
Delivery-Date: Fri May 21 17:39:51 2004
Return-Path: <kirstenparsonsry@yahoo.com>
X-Original-To: dagbrown@lart.ca
Delivered-To: dagbrown@lart.ca
Received: from anest.co.jp (c-24-1-221-189.client.comcast.net [24.1.221.189])
        by lart.ca (Postfix) with ESMTP id 05B7F5704
        for <dagbrown@lart.ca>; Fri, 21 May 2004 17:39:51 -0700 (PDT)
Message-ID: <NKELFLPJDPLDHJCMGFHDFEKLLNAA.kirstenparsonsry@yahoo.com>
From: "Kirsten Parsons" <kirstenparsonsry@yahoo.com>
To: dagbrown@lart.ca
Subject: Congrats!
Date: Fri, 21 May 2004 20:56:27 +0000
MIME-Version: 1.0
Content-Type: text/plain
Content-Transfer-Encoding: base64
EOF
        h=Gurgitate::Headers.new(m)

        assert_equal(Gurgitate::Header.new("To","dagbrown@lart.ca").contents,
                     h["To"][0].contents,"To header is as expected")

        assert_equal(false,h["To","Cc"] =~ /\blunar@lunar-linux.org\b/i,
            "There should be no Lunar Linux mailing list here")

        assert_equal(false,h["To"] =~ /\blunar@lunar-linux.org\b/i,
            "There should be no Lunar Linux mailing list in To line")
        assert(!(h["Cc"] =~ /\blunar@lunar-linux.org\b/i),
            "There should be no Lunar Linux mailing list in Cc line")
    end
end


class TC_Meddling_With_Headers < Test::Unit::TestCase
    def setup
        @message = <<'EOF'
From: fromline@example.com
To: toline@example.com
Subject: Subject Line
EOF

        @sender = "sender@example.com"
        @recipient = "recipient@example.com"

        @headers = Gurgitate::Headers.new @message, @sender, @recipient
    end

    def test_match
        assert @headers.match("From", /example.com/)
    end

    def test_nomatch
        assert !@headers.match("From", /lart.ca/)
    end

    def test_match_regex
        result = nil
        assert_nothing_raised do
            result = @headers.match "From", /example.com/
        end
        assert result
    end

    def test_match_string
        result = nil

        assert_nothing_raised do
            assert result = @headers.match("From", "example.com")
        end

        assert result
        result = nil

        assert_nothing_raised do
            result = @headers.match("From", "e.ample.com")
        end

        assert !result
    end
end


