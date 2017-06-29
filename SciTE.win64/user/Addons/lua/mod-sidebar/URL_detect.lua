--[[
URL_detect.lua
Authors: Tymur Gubayev
Version: 1.1.0
------------------------------------------------------
Description:	a (simple) URI recognizer as Lua module
	detects URI's very close to standart (rfc3986)
	to avoid false positives, schemes are restricted to
	https, http, ftp, file, mailto. Feel free to amend
	this list (search for `scheme        <-`)
------------------------------------------------------
Requires:	lpeg>=0.10 (with `re` module)
--]]

--[[ http://tools.ietf.org/html/rfc3986#appendix-A
Appendix A. Collected ABNF for URI

   URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]

   hier-part     = "//" authority path-abempty
                 / path-absolute
                 / path-rootless
                 / path-empty

   URI-reference = URI / relative-ref

   absolute-URI  = scheme ":" hier-part [ "?" query ]

   relative-ref  = relative-part [ "?" query ] [ "#" fragment ]

   relative-part = "//" authority path-abempty
                 / path-absolute
                 / path-noscheme
                 / path-empty

   scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )

   authority     = [ userinfo "@" ] host [ ":" port ]
   userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
   host          = IP-literal / IPv4address / reg-name
   port          = *DIGIT

   IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"

   IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )

   IPv6address   =                            6( h16 ":" ) ls32
                 /                       "::" 5( h16 ":" ) ls32
                 / [               h16 ] "::" 4( h16 ":" ) ls32
                 / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
                 / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
                 / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
                 / [ *4( h16 ":" ) h16 ] "::"              ls32
                 / [ *5( h16 ":" ) h16 ] "::"              h16
                 / [ *6( h16 ":" ) h16 ] "::"

   h16           = 1*4HEXDIG
   ls32          = ( h16 ":" h16 ) / IPv4address
   IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
   dec-octet     = DIGIT                 ; 0-9
                 / %x31-39 DIGIT         ; 10-99
                 / "1" 2DIGIT            ; 100-199
                 / "2" %x30-34 DIGIT     ; 200-249
                 / "25" %x30-35          ; 250-255

   reg-name      = *( unreserved / pct-encoded / sub-delims )

   path          = path-abempty    ; begins with "/" or is empty
                 / path-absolute   ; begins with "/" but not "//"
                 / path-noscheme   ; begins with a non-colon segment
                 / path-rootless   ; begins with a segment
                 / path-empty      ; zero characters

   path-abempty  = *( "/" segment )
   path-absolute = "/" [ segment-nz *( "/" segment ) ]
   path-noscheme = segment-nz-nc *( "/" segment )
   path-rootless = segment-nz *( "/" segment )
   path-empty    = 0<pchar>

   segment       = *pchar
   segment-nz    = 1*pchar
   segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
                 ; non-zero-length segment without any colon ":"

   pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"

   query         = *( pchar / "/" / "?" )

   fragment      = *( pchar / "/" / "?" )

   pct-encoded   = "%" HEXDIG HEXDIG

   unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
   reserved      = gen-delims / sub-delims
   gen-delims    = ":" / "/" / "?" / "#" / "[" / "]" / "@"
   sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
                 / "*" / "+" / "," / ";" / "="

]] -- ABNF rfc: http://tools.ietf.org/html/rfc5234

-- ensure we have LPEG version >=0.10
assert(tonumber(require'lpeg'.version())>=0.10, 'LPEG 0.10 or newer needed')
local re = require're'

local URI_re = [[ --@ mostly autogenerated
    URI           <- scheme ":" hier_part ( "?" query )? ( "#" fragment )?
    hier_part     <- "//" authority path_abempty
              / path_absolute
              / path_rootless
              / path_empty
    URI_reference <- URI / relative_ref
    absolute_URI  <- scheme ":" hier_part ( "?" query )?
    relative_ref  <- relative_part ( "?" query )? ( "#" fragment )?
    relative_part <- "//" authority path_abempty
              / path_absolute
              / path_noscheme
              / path_empty
    --@ we don't want anything looking like a scheme being accepted
    --scheme        <- ALPHA ( ALPHA / DIGIT / "+" / "-" / "." )*
    scheme        <- "https"/"http"/"ftp"/"file"/"mailto"
    authority     <- ( userinfo "@" )? host ( ":" port )?
    userinfo      <- ( unreserved / pct_encoded / sub_delims / ":" )*
    host          <- IP_literal / IPv4address / reg_name
    port          <- DIGIT*
    IP_literal    <- "[" ( IPv6address / IPvFuture  ) "]"
    IPvFuture     <- "v" HEXDIG+ "." ( unreserved / sub_delims / ":" )+
    IPv6address   <-                         ( h16 ":" )^6 ls32
              /                         "::" ( h16 ":" )^5 ls32
              / (                h16 )? "::" ( h16 ":" )^4 ls32
              / ( ( h16 ":" )?   h16 )? "::" ( h16 ":" )^3 ls32
              / ( ( h16 ":" )^-2 h16 )? "::" ( h16 ":" )^2 ls32
              / ( ( h16 ":" )^-3 h16 )? "::"   h16 ":"     ls32
              / ( ( h16 ":" )^-4 h16 )? "::"               ls32
              / ( ( h16 ":" )^-5 h16 )? "::"   h16
              / ( ( h16 ":" )^-6 h16 )? "::"
    h16           <- HEXDIG HEXDIG^3
    ls32          <- ( h16 ":" h16 ) / IPv4address
    IPv4address   <- dec_octet "." dec_octet "." dec_octet "." dec_octet
    dec_octet     <- DIGIT              --; 0-9
                     / [1-9] DIGIT      --; 10-99
                     / "1" DIGIT^2      --; 100-199
                     / "2" [0-4] DIGIT  --; 200-249
                     / "25" [0-5]       --; 250-255
    reg_name      <- ( unreserved / pct_encoded / sub_delims )*
    path          <- path_abempty    --; begins with "/" or is empty
              / path_absolute   --; begins with "/" but not "//"
              / path_noscheme   --; begins with a non-colon segment
              / path_rootless   --; begins with a segment
              / path_empty      --; zero characters
    path_abempty  <- ( "/" segment )*
    path_absolute <- "/" ( segment_nz ( "/" segment )* )?
    path_noscheme <- segment_nz_nc ( "/" segment )*
    path_rootless <- segment_nz ( "/" segment )*
    path_empty    <- ''    --<pchar>^0
    segment       <- pchar*
    segment_nz    <- pchar+
    segment_nz_nc <- ( unreserved / pct_encoded / sub_delims / "@" )+
    pchar         <- unreserved / pct_encoded / sub_delims / ":" / "@"
    query         <- ( pchar / "/" / "?" )*
    fragment      <- ( pchar / "/" / "?" )*
    pct_encoded   <- "%" HEXDIG HEXDIG
    unreserved    <- ALPHA / DIGIT / [-._~]    --"-" / "." / "_" / "~"
    reserved      <- gen_delims / sub_delims
    gen_delims    <- [][:/?#@]    --":" / "/" / "?" / "#" / "[" / "]" / "@"
    --@ amended sub_delims: there's no good possibility to distinguish between ")" as part of URL, and ")" as close bracket AFTER the URL.
    --sub_delims    <- [!$&'()*+,;=]
    sub_delims    <- [$&'*+=]
]]
-- common defs
 .. '	ALPHA     <-  [\65-\90\97-\122]    \n' -- A-Z / a-z
-- .. '	BIT       <-  [01]                 \n' -- "0" / "1"
-- .. '	CHAR      <-  [\1-\127]            \n'
 .. '	CR        <-  "\13"                \n'
 ..'	CRLF      <-  CR? LF               \n'
-- .. '	CTL       <-  [\0-\31\127]         \n'
 .. '	DIGIT     <-  [0-9]                \n' -- \48-\57
-- .. '	DQUOTE    <-  [\34]                \n'
 .. '	HEXDIG    <-  [0-9A-F]             \n' -- DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
-- .. '	HTAB      <-  "\9"                 \n'
 .. '	LF        <-  "\10"                \n'
-- .. '	LWSP      <-  (WSP / CRLF WSP)*    \n'
-- .. '	OCTET     <-  [\0-\255]            \n'
-- .. '	SP        <-  "\32"                \n'
-- .. '	VCHAR     <-  [\33-\126]           \n'
-- .. '	WSP       <-  SP / HTAB            \n'

local mailto_patch = [[
    -- mailto needs some special rules
    mailtoURI     <- "mailto:"? userinfo "@" (mailunres / IPv4address) / URI
    mailunres     <- unreserved mailunres / (ALPHA / DIGIT) -- searcher
]]

local url = re.compile(mailto_patch .. URI_re)

function IsURI(s)
	local n = url:match(s)
	return n and n-1 -- the `-1` is indeed needed
end

dofile(myHome..'\\Addons\\lua\\mod-sidebar\\sidebar.lua')
dofile(myHome..'\\Addons\\lua\\mod-sidebar\\ctagsd.lua')