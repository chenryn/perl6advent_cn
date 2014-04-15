## parrot MIME::Base64 FixedIntegerArray: index out of bounds!

Ronaldxs created the following parrot [ticket #813](https://github.com/parrot/parrot/issues/813) 4 months ago:

_“Was playing with p6 MIME::Base64 and utf8 sampler page when I came across this. It seems that the parrot MIME Base64 library can’t handle some UTF-8 characters as demonstrated below.”_

    
    .sub go :main
        load_bytecode 'MIME/Base64.pbc'
    
        .local pmc enc_sub
        enc_sub = get_global [ "MIME"; "Base64" ], 'encode_base64'
    
        .local string result_encode
        result_encode = enc_sub(utf8:"\x{203e}")
    
        say result_encode
    .end

`FixedIntegerArray: index out of bounds!`

`current instr.: 'parrot;MIME;Base64;encode_base64'

pc 163 (runtime/parrot/library/MIME/Base64.pir:147)`

`called from Sub 'go' pc 11 (die_utf8_base64.pir:8)`

This was interesting, because parrot strings store the encoding information in the string. The user does not need to store the string encoding information somewhere else as in perl5, nor have to do educated guesses about the encoding. parrot supports ascii, latin1, binary, utf-8, ucs-2, utf-16 and ucs-4 string encodings natively.

So we thought we the hell cannot parrot handle simple utf-8 encoded strings?

As it turned out, the parrot implementation of MIME::Base64, which can be shared to all languages which use parrot as VM, stored the character codepoints for each character as array of integers. On multibyte encodings such as UTF-8 this leads to different data held in memory than a normal multibyte string which is encoded as the byte buffer and the additional encoding information.

## Internal string representations

For example an overview of different internal string representations for the utf-8 string **“\x{203e}”**:

perl5 strings:

    
    len=3, utf-8 flag, "\342\200\276" buf=[e2 80 be]

parrot strings:

    
    len=1, bufused=3, encoding=utf-8, buf=[e2 80 be]

The Unicode tables:

    
    U+203E	‾	e2 80 be	OVERLINE

## gdb perl5

Let’s check it out:

    
    $ gdb --args perl -e'print "\x{203e}"'
    (gdb) start
    (gdb) b Perl_pp_print
    (gdb) c
    (gdb) n 
    
    _.. until if (!do_print(*MARK, fp))_
    
    (gdb) p **MARK
    $1 = {sv_any = 0x404280, sv_refcnt = 1, sv_flags = 671106052, sv_u = {
          svu_pv = **0x426dd0 "‾"**, svu_iv = 4353488, svu_uv = 4353488, 
          svu_rv = 0x426dd0, svu_array = 0x426dd0, svu_hash = 0x426dd0, 
          svu_gp = 0x426dd0, svu_fp = 0x426dd0}, ...}
    
    (gdb) p Perl_sv_dump(*MARK)
    ALLOCATED at -e:1 for stringify (parent 0x0); serial 301
    SV = PV(0x404280) at 0x4239a8
      REFCNT = 1
      FLAGS = (POK,READONLY,pPOK,**UTF8**)
      PV = 0x426dd0 "\342\200\276" [UTF8 "\x{203e}"]
      CUR = **3**
      LEN = 16
    $2 = void
    
    (gdb) x/3x 0x426dd0
    0x426dd0:	**0xe2	0x80	0xbe**

We see that perl5 does store the utf-8 flag, but not the length of the string, the utf8 length (=1), only the length of the buffer (=3).

Any other multi-byte encoded string, such as UCS-2 is stored differently. We suppose as utf-8.

We are already in the debugger, so let’s try the different cmdline argument.

    
    (gdb) run -e'use Encode; print encode("UCS-2", "\x{203e}")'
      The program being debugged has been started already.
      Start it from the beginning? (y or n) y
    Breakpoint 2, Perl_pp_print () at pp_hot.c:712
    712	    dVAR; dSP; dMARK; dORIGMARK;
    
    (gdb) p **MARK
    
    $3 = {sv_any = 0x404b30, sv_refcnt = 1, sv_flags = 541700, sv_u = {
        svu_pv = **0x563a50 " >"**, svu_iv = 5651024, svu_uv = 5651024, 
        svu_rv = 0x563a50, svu_array = 0x563a50, svu_hash = 0x563a50, svu_gp = 0x563a50, 
        svu_fp = 0x563a50}, ...}
    
    (gdb) p Perl_sv_dump(*MARK)
    ALLOCATED at -e:1 by return (parent 0x0); serial 9579
    SV = PV(0x404b30) at 0x556fb8
      REFCNT = 1
      FLAGS = (TEMP,POK,pPOK)
      PV = 0x563a50 " >"
      CUR = 2
      LEN = 16
    $4 = void
    
    (gdb) x/2x 0x563a50
    0x563a50:	**0x20	0x3e**

But we don’t see the UTF8 flag in encode(“UCS-2″, “\x{203e}”), just the simple ascii string ” >”, which is the UCS-2 representation of [20 3e].

Because ” >” is perfectly representable as non-utf8 ASCII string.

UCS-2 is much much nicer than UTF-8, is has a fixed size, it is readable, Windows uses it, but it cannot represent all Unicode characters.

[Encode::Unicode](http://perldoc.perl.org/Encode/Unicode.html) contains this nice cheatsheet:

    
    **Quick Reference**
                    Decodes from ord(N)           Encodes chr(N) to...
           octet/char BOM S.P d800-dfff  ord > 0xffff     \x{1abcd} ==
      ---------------+-----------------+------------------------------
      UCS-2BE       2   N   N  is bogus                  Not Available
      UCS-2LE       2   N   N     bogus                  Not Available
      UTF-16      2/4   Y   Y  is   S.P           S.P            BE/LE
      UTF-16BE    2/4   N   Y       S.P           S.P    0xd82a,0xdfcd
      UTF-16LE    2/4   N   Y       S.P           S.P    0x2ad8,0xcddf
      UTF-32        4   Y   -  is bogus         As is            BE/LE
      UTF-32BE      4   N   -     bogus         As is       0x0001abcd
      UTF-32LE      4   N   -     bogus         As is       0xcdab0100
      UTF-8       1-4   -   -     bogus   >= 4 octets   \xf0\x9a\af\8d
      ---------------+-----------------+------------------------------

## gdb parrot

Back to parrot:

If you debug parrot with gdb you get a gdb pretty-printer thanks to Nolan Lum, which displays the string and encoding information automatically.

In perl5 you have to call `Perl_sv_dump` with or without the `my_perl` as first argument, if threaded or not. With a threaded perl, e.g. on Windows you’d need to call `p Perl_sv_dump(my_perl, *MARK)`.

In parrot you just ask for the value and the formatting is done with a gdb pretty-printer plugin.

The string length is called `strlen` (of the encoded string), the buffer size is called `bufused`.

Even in a backtrace the string arguments are displayed abbrevated like this:

    
    #3  0x00007ffff7c29fc4 in utf8_iter_get_and_advance (interp=0x412050, str="utf8:� [1/2]", 
        i=0x7fffffffdd00) at src/string/encoding/utf8.c:551
    #4  0x00007ffff7a440f6 in Parrot_str_escape_truncate (interp=0x412050, src="utf8:� [1/2]",
        limit=20) at src/string/api.c:2492
    #5  0x00007ffff7b02fb3 in trace_op_dump (interp=0x412050, code_start=0x63a1c0, pc=0x63b688)
        at src/runcore/trace.c:450

[1/2] means strlen=1 bufused=2

Each non-ascii or non latin-1 encoded string is printed with the encoding prefix.

Internally the encoding is of course a index or pointer in the table of supported encodings.

You can set a breakpoint to `utf8_iter_get_and_advance` and watch the strings.

    
    (gdb) r t/library/mime_base64u.t
    Breakpoint 1, utf8_iter_get_and_advance (interp=0x412050, str="utf8:\\x{00c7} [8/8]", 
                    i=0x7fffffffcd40) at src/string/encoding/utf8.c:544
    (gdb) p str
    $1 = "utf8:\\x{00c7} [8/8]"
    (gdb) p str->bufused 
    $3 = 8
    (gdb) p str->strlen
    $4 = 8
    (gdb) p str->strstart
    $5 = 0x5102d7 "\\x{00c7}"

This is escaped. Let’s advance to a more interesting utf8 string in this test, i.e. until str=”utf8:Ā [1/2]“

You get the members of a struct with tab-completion, i.e. press **<TAB>** after **p str->**

    
    (gdb) p str->
    **_buflen    _bufstart  bufused    encoding   flags      hashval    strlen     strstart**
    (gdb) p str->strlen
    $9 = 8
    
    (gdb) dis 1
    (gdb) b utf8_iter_get_and_advance if str->strlen == 1
    (gdb) c
    Breakpoint 2, utf8_iter_get_and_advance (interp=0x412050, str="utf8:Ā [1/2]", 
                    i=0x7fffffffcd10) at src/string/encoding/utf8.c:544
    544	    ASSERT_ARGS(utf8_iter_get_and_advance)
    
    (gdb) p str->strlen
    $10 = 1
    (gdb) p str->strstart
    $11 = 0x7ffff7faeb58 "Ā"
    (gdb) x/2x str->strstart
    0x7ffff7faeb58:	**0xc4	0x80**
    (gdb) p str->encoding
    $12 = (const struct _str_vtable *) 0x7ffff7d882e0
    (gdb) p *str->encoding
    
    $13 = {num = 3, name = 0x7ffff7ce333f "utf8", name_str = "utf8", bytes_per_unit = 1,
      max_bytes_per_codepoint = 4, to_encoding = 0x7ffff7c292b0 <utf8_to_encoding>, chr =
      0x7ffff7c275c0 <unicode_chr>, equal = 0x7ffff7c252e0 <encoding_equal>, compare =
      0x7ffff7c254e0 <encoding_compare>, index = 0x7ffff7c25690 <encoding_index>, rindex
      = 0x7ffff7c257a0 <encoding_rindex>, hash = 0x7ffff7c25a20 <encoding_hash>, scan =
      0x7ffff7c29380 <utf8_scan>, partial_scan = 0x7ffff7c29460 <utf8_partial_scan>, ord
      = 0x7ffff7c297e0 <utf8_ord>, substr = 0x7ffff7c25de0 <encoding_substr>, is_cclass =
      0x7ffff7c26000 <encoding_is_cclass>, find_cclass =
      0x7ffff7c260e0 <encoding_find_cclass>, find_not_cclass =
      0x7ffff7c26220 <encoding_find_not_cclass>, get_graphemes =
      0x7ffff7c263d0 <encoding_get_graphemes>, compose =
      0x7ffff7c27680 <unicode_compose>, decompose = 0x7ffff7c26450 <encoding_decompose>,
      upcase = 0x7ffff7c27b20 <unicode_upcase>, downcase =
      0x7ffff7c27be0 <unicode_downcase>, titlecase = 0x7ffff7c27ca0 <unicode_titlecase>,
      upcase_first = 0x7ffff7c27d60 <unicode_upcase_first>, downcase_first =
      0x7ffff7c27dc0 <unicode_downcase_first>, titlecase_first =
      0x7ffff7c27e20 <unicode_titlecase_first>, iter_get =
      0x7ffff7c29c40 <utf8_iter_get>, iter_skip = 0x7ffff7c29d60 <utf8_iter_skip>,
      iter_get_and_advance = 0x7ffff7c29eb0 <utf8_iter_get_and_advance>,
      iter_set_and_advance = 0x7ffff7c29fd0 <utf8_iter_set_and_advance>}

## encode_base64(str)

    
    $ perl -MMIME::Base64 -lE'$x="20e3";$s="\x{20e3}";
      printf "0x%s\t%s=> %s",$x,$s,encode_base64($s)'
    Wide character in subroutine entry at -e line 1.

Oops, I’m clearly a unicode perl5 newbie. Does my term not understand utf-8?

    
    $ echo $TERM
    xterm

No, it should. encode_base64 does not understand unicode.

`perldoc MIME::Base64`

_“The base64 encoding is only defined for single-byte characters. Use the Encode module to select the byte encoding you want.”_

Oh my! But it is just perl5. It just works on byte buffers, not on strings.

perl5 strings can be utf8 and non-utf8. Why on earth an utf8 encoded string is disallowed and only byte buffers of unknown encodings are allowed goes beyond my understanding, but what can you do. Nothing. base64 is a binary only protocol, based on byte buffers. So we decode it manually to byte buffers. The Encode API for decoding is called _encode_.

    
    $ perl -MMIME::Base64 -MEncode -lE'$x="20e3";$s="\x{20e3}";
      printf "0x%s\t%s=> %s",$x,$s,encode_base64(encode('utf8',$s))'
    Wide character in printf at -e line 1.
    0x20e3	=> 4oOj

This is now the term warning I know. We need **-C**

    
    $ **perldoc perluniintro**
    
    $ perl -C -MMIME::Base64 -MEncode -lE'$x="20e3";$s="\x{20e3}";
      printf "0x%s\t%s=> %s",$x,$s,encode_base64(encode('utf8',$s))'
    0x20e3	=> 4oOj

Over to rakudo/perl6 and parrot:

    
    $ cat >m.pir << EOP
    .sub main :main
        load_bytecode 'MIME/Base64.pbc'
        $P1 = get_global [ "MIME"; "Base64" ], 'encode_base64'
        $S1 = utf8:"\x{203e}"
        $S2 = $P1(s1)
        say $S1
        say $S2
    .end
    EOP
    
    $ parrot m.pir
    FixedIntegerArray: index out of bounds!
    current instr.: 'parrot;MIME;Base64;encode_base64'
                    pc 163 (runtime/parrot/library/MIME/Base64.pir:147)

The perl6 test, using the parrot library, from [https://github.com/ronaldxs/perl6-Enc-MIME-Base64/](https://github.com/ronaldxs/perl6-Enc-MIME-Base64/)

    
    $ git clone git://github.com/ronaldxs/perl6-Enc-MIME-Base64.git
    Cloning into 'perl6-Enc-MIME-Base64'...
    
    $ PERL6LIB=perl6-Enc-MIME-Base64/lib perl6 <<EOP
    use Enc::MIME::Base64;
    say encode_base64_str("\x203e");
    EOP
    
    > use Enc::MIME::Base64;
    Nil
    > say encode_base64_str("\x203e");
    FixedIntegerArray: index out of bounds!
    ...

The pure perl6 workaround:

    
    $ PERL6LIB=perl6-Enc-MIME-Base64/lib perl6 <<EOP
    use PP::Enc::MIME::Base64;
    say encode_base64_str("\x203e");
    EOP
    
    > use PP::Enc::MIME::Base64;
    Nil
    > say encode_base64_str("\x203e");
    4oC+

Wait. perl6 creates a different enoding than perl5?

What about coreutils [base64](http://www.gnu.org/software/coreutils/manual/html_node/base64-invocation.html) command.

    
    $ echo -n "‾" > m.raw
    $ od -x m.raw
    0000000 80e2 00be
    0000003
    $ ls -al m.raw
    -rw-r--r-- 1 rurban rurban 3 Dec  6 10:23 m.raw
    $ base64 m.raw
    4oC+

`[80e2 00be]` is the little-endian version of `[e2 80 be]`, 3 bytes, flipped.

Ok, at least base64 agrees with perl6, and I must have made some encoding mistake with perl5.

Back to debugging our parrot problem:

parrot unlike perl6 has no debugger yet. So we have to use `gdb`, and we need to know in which function the error occured. We use the parrot `-t` trace flag, which is like the perl5 debugging `-Dt` flag, but it is always enabled,even in optimized builds.

    
    $ parrot --help
    ...
        -t --trace [flags] 
        --help-debug
    ...
    $ parrot --help-debug
    ...
    --trace -t [Flags] ...
        0001    opcodes
        0002    find_method
        0004    function calls
    
    $ parrot -t7 m.pir
    ...
    009f band I9, I2, 63         I9=0 I2=0 
    00a3 set I10, P0[I5]         I10=0 P0=**FixedIntegerArray**=PMC(0xff7638) I5=[**2063**]
    016c get_results PC2 (1), P2 PC2=FixedIntegerArray=PMC(0xedd178) P2=PMCNULL
    016f finalize P2             P2=Exception=PMC(0x16ed498)
    0171 pop_eh
    _lots of error handling_
    ...
    0248 callmethodcc P0, "print" P0=FileHandle=PMC(0xedcca0) 
    FixedIntegerArray: index out of bounds!

We finally see the problem, which matches the run-time error.

    
    00a3 **set I10, P0[I5]**         I10=0 P0=**FixedIntegerArray**=PMC(0xff7638) I5=[**2063**]

We want to set I10 to the I5=2063′th element in the FixedIntegerArray P0, and the array is not big enough.

After several hours of analyzing I came to the conclusion that the parrot library MIME::Base64 was wrong by using **ord** of every character in the string. It should use a **bytebuffer** instead.

Which was fixed with [commit 3a48e6](https://github.com/parrot/parrot/commit/3a48e6b462d8fff501cb16a2f92a857baee0df53). ord can return integers > 255, but base64 can only handle chars < 255.

The fixed parrot library was now correct:

    
    $ parrot m.pir
    ‾
    4oC+

But then the tests started failing. I spent several weeks trying to understand why the parrot testsuite was wrong with the mime_base64 tests, the testdata came from perl5. I came up with different implementation hacks which would match the testsuite, but finally had to bite the bullet, changing the tests to match the implementation.

And I had to special case the tests for big-endian, as base64 is endian agnostic. You cannot decode a base64 encoded powerpc file on an intel machine, when you use multi-byte characters. And utf-8 is even more multi-byte than ucs-2. I had to accept the fact the big-endian will return a different encoding. Before the results were the same. The tests were written to return the same encoding on little and big-endian.

## Summary

The first reason why I wrote this blog post was to show how to debug into crazy problems like this, when you are not sure if the core implementation, the library, the spec or the tests are wrong. It turned out, that the library and the tests were wrong.

You saw how easily you could use gdb to debug into such problems, as soon as you find out a proper breakpoint.

The internal string representations looked like this:

MIME::Base64 internally:

    
    len=1, encoding=utf-8, buf=[3e20]

and inside the parrot imcc compiler the SREG

    
    len=8, buf="utf-8:\"\x{203e}\""

parrot is a register based runtime, and a SREG is the string representation of the register value. Unfortunately a SREG cannot hold the encoding info yet, so we prefix the encoding in the string, and unquote it back. This is not the reason why parrot is still slower than the perl5 VM. I [benchmarked](https://g ithub.com/parrot/parrot/commit/9c8159314dd2d26365653fbcd8627b0f8fbb0559) it. parrot still uses too much sprintf’s internally and the encoding quote/unquoting counts only for a 4th of the time of the sprintf gyrations.

And parrot function calls are awfully slow and de-optimized.

The second reason is to explain the new decode_base64() API, which only parrot – and therefore all parrot based languages like rakudo – now have got.

## decode_base64(str, ?:encoding)

_“Decode a base64 string by calling the decode_base64() function.

This function takes as first argument the string to decode, as optional second argument the encoding string for the decoded data.

It returns the decoded data._

_Any character not part of the 65-character base64 subset is silently ignored.

Characters occurring after a ‘=’ padding character are never decoded.”_

So decode_base64 got now a second optional encoding argument. The src string for encode_base64 can be any encoding and is automatically decoded to a bytebuffer. You can easily encode an image or unicode string without any trouble, and for the decoder you can define the wanted encoding beforehand. The result can be the encoding **binary** or **utf-8** or any encoding you prefer, no need for additional decoding of the result. The default encoding of the decoded string is either ascii, latin-1 or utf-8. parrot will upgrade the encoding automatically.

You can compare the new examples of [pir](https://github.com/parrot/parrot/blob/master/examples/library/utf8_base64.pir) against the [perl5](https://github.com/parrot/parrot/blob/master/examples/library/utf8_base64.pl) version:

parrot:

    
    .sub main :main
        load_bytecode 'MIME/Base64.pbc'
    
        .local pmc enc_sub
        enc_sub = get_global [ "MIME"; "Base64" ], 'encode_base64'
    
        .local string result_encode
        # GH 814
        result_encode = enc_sub(utf8:"\x{a2}")
        say   "encode:   utf8:\"\\x{a2}\""
        say   "expected: wqI="
        print "result:   "
        say result_encode
    
        # GH 813
        result_encode = enc_sub(utf8:"\x{203e}")
        say   "encode:   utf8:\"\\x{203e}\""
        say   "expected: 4oC+"
        print "result:   "
        say result_encode
    
    .end

perl5:

    
    use MIME::Base64 qw(encode_base64 decode_base64);
    use Encode qw(encode);
    
    my $encoded = encode_base64(encode("UTF-8", "\x{a2}"));
    print  "encode:   utf-8:\"\\x{a2}\"  - ", encode("UTF-8", "\x{a2}"), "\n";
    print  "expected: wqI=\n";
    print  "result:   $encoded\n";
    print  "decode:   ",decode_base64("wqI="),"\n\n"; # 302 242
    
    my $encoded = encode_base64(encode("UTF-8", "\x{203e}"));
    print  "encode:   utf-8:\"\\x{203e}\"  -> ",encode("UTF-8", "\x{203e}"),"\n";
    print  "expected: 4oC+\n";
    print  "result:   $encoded\n"; # 342 200 276
    print  "decode:   ",decode_base64("4oC+"),"\n";
    
    for ([qq(a2)],[qq(c2a2)],[qw(203e)],[qw(3e 20)],[qw(1000)],[qw(00c7)],[qw(00ff 0000)]){
        $s = pack "H*",@{$_};
        printf "0x%s\t=> %s", join("",@{$_}), encode_base64($s);
    }

perl6:

    
    use Enc::MIME::Base64;
    say encode_base64_str("\xa2");
    say encode_base64_str("\x203e");

