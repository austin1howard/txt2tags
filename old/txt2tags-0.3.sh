#!/bin/sh
# txt2tags - a generic tagged language text generator
#
# 20010726 <verde@verde666.org> ** debut
# TODO || moincel ||, TABcel1TABcel2, --- forget table for now.
# TODO allow lists inside quotes? (mgp TAB problems)
# TODO =title=[label] for "local" links (HTML)
# TODO mgp: subquote (increase prefix) ----mmmm, maybe not (big letters, few hspace)
# TODO pm6 : check quote
# TODO moin: list should have leading spaces
#
# BUG: sgml: title after quote left a blank line before </quote>
#
#i pm6: paragraph == 1 line
#
# 20010727 <verde@...> ++mgp: prefix "  " for all lines
#                      ++mgp: ^% scape with prefix
# 20010730 <verde@...> ++comments MUST be at ^
# 20010928 <verde@...> ++man target, ++shell wrapper & py together
# 20011109 <verde@...> ++["label" url] tag, ++%%date(fmt)

Usage(){
  local ver types name=${0##*/}
    ver=`sed "/^#my_version = '/!d;s///" $0`
  types=`sed "/^#tags = /!d;s///;s/[][']//g" $0`
  echo "\
$name version ${ver%?} <http://txt2tags.sf.net>

usage: $name -t <type> [--stdout] file.txt
       $name -t html -s <split level> -l <lang> file.txt

  -t, --type    target document type. actually supported:
                $types
      --stdout  by default, the output is written to file.<type>
                with this option, STDOUT is used (no files written)

extra options for HTML target (needs sgml-tools):
  -s, --split   split documents. values: 0, 1, 2 (default 0)
  -l, --lang    document language (default english)

"
  exit 1
}

# defaults
stdout=0
split=0
lang=english


while [ "$2" ]; do
  case "$1" in
    -t|--type)  [ "$2" ] || Usage; shift; doctype=$1;;
    -s|--split) [ "$2" ] || Usage; shift; split=$1;;
    -l|--lang)  [ "$2" ] || Usage; shift; lang=$1;;
	--stdout) stdout=1 ;;
    *) Usage;;
  esac
  shift
done

[ "$1" ] || Usage
TXT="$1"

[ -f "$TXT" ] || {
  echo "file $TXT not found! aborting..."
  exit 1
}

name=`basename $TXT .txt`
D=$PWD
TXT="$D/$TXT"

letsdoit(){ sed "1,/^##@##/d;s/^#//" $0 | python - "$@"; }  # cool huh? &:)
fecho(){ echo -e "\033[1m--- $*...\033[m" ; }               # fancyness
checkdoc(){ [ ! -f "$D/$name.$1" -o "$D/$name.$1" -ot "$TXT" ] && doAll $1; }

dodoc(){ 
  local type=$1
  if [ $stdout -eq 1 ]; then
    letsdoit --type $type $TXT
  elif [ "$type" == "txt" ]; then
    echo 'hey, --type txt requires --stdout!'
    echo '"shoot on the foot" does mean something to you? &:)'
	# yes, i've got my sample.txt file deleted, then i did this safety test...
  else
    fecho $type; letsdoit --type $type $TXT > $D/$name.$type
    echo "wrote $D/$name.$type"
  fi
}

doAll(){
  case "$1" in
  txt|sgml|pm6|mgp|moin|man)
        dodoc $1
        ;;
  html)
        [ $split -eq 0 ] && { dodoc $1; return; }
        
        ### for splitted html, sgml2html does the job
		
        # html target dir
        [ -d "$D/$name" ] || mkdir "$D/$name"
        # we have to have an updated .sgml
        checkdoc sgml
        # let's go!
        fecho splitted html
        cd $D/$name ; rm -f $name{,-[0-9]*}.html
        sgml2html --language=$lang --split=$split $D/$name.sgml
        ln -sf $name.html index.html
        ;;
  ps)
        fecho $1
        checkdoc sgml
        sgml2latex -o $1 --language=$lang $D/$name.sgml
        ;;
  pdf)
        fecho $1
        checkdoc ps
        ps2pdf $D/$name.ps
        ;;
  *)
        Usage
  esac
}

doAll $doctype


  

##@##
#import re, string, os, sys
#from time import strftime,time,localtime
#
#my_url = 'http://txt2tags.sourceforge.net'
#my_email = 'aurelio@verde666.org'
#my_version = '0.3'
#
#usage = 'usage: %s --type <type> file.txt\n'%(sys.argv[0])
#
## soon i'll use getopts &:)
#if len(sys.argv) != 4:
#	print usage
#	sys.exit(1)
#
#doctype = sys.argv[2]
#file = sys.argv[3]
#
#tags = ['txt', 'sgml', 'html', 'pm6', 'mgp', 'moin', 'man']
#try: T = tags.index(doctype)
#except ValueError:
#	print "invalid type '%s'"%(doctype)
#	print usage
#	sys.exit(1)
#
#if not os.path.isfile(file):
#	print 'file not found: '+file
#	sys.exit(1)
#
#### all the registered tags
#TAGparagraph = ['', '<p>', '<P>', '<@Normal:>', '%font "normal", size 5\n', '', '.P']
#TAGtitle1 = ['  \a'      , '<sect>\a<p>' , '<H1>\a</H1>', '\n<@Title1:>\a', '%page\n\n\a', '= \a =', '.SH \a']
#TAGtitle2 = ['\t\a'      , '<sect1>\a<p>', '<H2>\a</H2>', '\n<@Title2:>\a', '%page\n\n\a', '== \a ==', '.SS \a']
#TAGtitle3 = ['\t\t\a'    , '<sect2>\a<p>', '<H3>\a</H3>', '\n<@Title3:>\a', '%page\n\n\a', '=== \a ===', '.SS \a']
#TAGtitle4 = ['\t\t\t\a'  , '<sect3>\a<p>', '<H4>\a</H4>', '\n<@Title4:>\a', '%page\n\n\a', '==== \a ====', '.SS \a']
#TAGtitle5 = ['\t\t\t\t\a', '<sect4>\a<p>', '<H5>\a</H5>', '\n<@Title5:>\a', '%page\n\n\a', '===== \a =====', '.SS \a']
#TAGareaPreOpen = ['',  '<tscreen><verb>',   '<PRE>', '<@PreFormat:>', '\n%font "mono"', '{{{', '\n']
#TAGareaPreClose = ['', '</verb></tscreen>', '</PRE>', '', '%font "normal"', '}}}', '\n']
#TAGareaQuoteOpen = ['    ',   '<quote>', '<BLOCKQUOTE>', '<@Quote:>', '%prefix "       "', ' ', '\n']
#TAGareaQuoteClose = ['', '</quote>', '</BLOCKQUOTE>', '', '%prefix "  "', '', '\n']
#TAGfontMonoOpen  = ['',  '<tt>',  '<CODE>', '<FONT "Lucida Console"><SIZE 9>', '\n%cont, font "mono"\n', '{{{', '']
#TAGfontMonoClose = ['', '</tt>', '</CODE>', '<SIZE$><FONT$>', '\n%cont, font "normal"\n', '}}}', '']
#TAGfontBoldOpen  = ['',  '<bf>',  '<B>', '<B>', '\n%cont, font "normal-b"\n', "'''", '\n.B ']
#TAGfontBoldClose = ['', '</bf>', '</B>', '<P>', '\n%cont, font "normal"\n', "'''", '\n\\&']
#TAGfontItalicOpen  = ['',  '<em>',  '<I>', '<I>', '\n%cont, font "normal-i"\n', "''", '\n.I ']
#TAGfontItalicClose = ['', '</em>', '</I>', '<P>', '\n%cont, font "normal"\n', "''", '\n\\&']
#TAGfontBoldItalicOpen  = ['',  '<bf><em>',   '<B><I>', '<B><I>', '\n%cont, font "normal-bi"\n', "'''''", '\n.BI ']
#TAGfontBoldItalicClose = ['', '</em></bf>', '</I></B>', '<P>',   '\n%cont, font "normal"\n', "'''''", '\n\\&']
#TAGfontUnderlineOpen = ['', TAGfontBoldItalicOpen[1], '<U>', '<U>', '\n%cont, fore "cyan"\n', TAGfontBoldItalicOpen[5], '']
#TAGfontUnderlineClose = ['', TAGfontBoldItalicClose[1], '</U>', '<P>', '\n%cont, fore "white"\n', TAGfontBoldItalicClose[5], '']
#TAGlistOpen = ['', '<itemize>', '<UL>', '<@Bullet:>', '', '', '\n']
#TAGlistClose = ['', '</itemize>', '</UL>', '', '', '', '']
#TAGlistItem = ['- ', '<item>', '<LI>', '•	', '', ' * ', '* ']
#TAGbar1 = ['\a', '<!-- \a -->', '<HR NOSHADE SIZE=1>', '\a', '%bar "white" 5', '----', '\n\a\n']
#TAGbar2 = ['\a', '<!-- \a -->', '<HR NOSHADE SIZE=5>', '\a', '%pause', '----', '\n\a\n']
#TAGurl = ['\a', '<htmlurl url="\a" name="\a">', '<A HREF="\a">\a</A>', TAGfontUnderlineOpen[3]+'\a'+TAGfontUnderlineClose[3], '\n%cont, fore "cyan"\n\a\n%cont, fore "white"\n', '[\a]', '\a']
#TAGurlMark = ['\a (\a)', TAGurl[1], TAGurl[2], '\a '+TAGurl[3], '\a '+TAGurl[4], '[\a \a]', '\a (\a)']
#TAGemail = ['\a', '<htmlurl url="mailto:\a" name="\a">', '<A HREF="mailto:\a">\a</A>', '\a', TAGurl[4], '[\a]', '\a']
#TAGemailMark = ['\a (\a)', TAGemail[1], TAGemail[2], '\a '+TAGemail[3], '\a '+TAGemail[4], '[\a \a]', '\a (\a)']
#TAGemail = ['\a', '<htmlurl url="mailto:\a" name="\a">', '<A HREF="mailto:\a">\a</A>', '\a', TAGurl[4], '[\a]', '\a']
#TAGimg = ['[\a]', '<figure><ph vspace=""><img src="\a"></figure>', '<P ALIGN=CENTER><IMG SRC="\a"></P>', '\a', '\n%center\n%newimage -yscrzoom 50"\a", left\n', '[\a]', '\a']
#TAGEOD = ['', '</article>', '</BODY></HTML>', '', '%%EOD', '', '']
#
#
#### the cool regexes
#re_title = re.compile(r'^\s*(?P<tag>={1,5})(?P<txt>[^=].*[^=])\1(\[(?P<label>\w+)\])?$')
#re_areaPreOpen = re_areaPreClose = re.compile(r'^---$')
#re_quote = re.compile(r'^\t+')
#re_1linePreOld = re.compile(r'^ {4}([^\s-])')
#re_1linePre = re.compile(r'^---([^-])')
#re_mono = re.compile(r'`([^`]+)`')
#re_bold = re.compile(r'\*\*([^\s*].*?)\*\*')
#re_italic = re.compile(r'(^|[^:])//([^ /].*?)//')
#re_underline = re.compile(r'__([^_].*?)__')
#re_bolditalic = re.compile(r'\*/([^/].*?)/\*')
#re_list = re.compile(r'^( *)- ([^ ])')
#re_bar =re.compile(r'^\s*([_=-]{20,})\s*$')
#re_url = re.compile(r'((https?|ftp|news)://|(www[23]?\.|ftp\.))[A-Za-z0-9._/~%:,-]+',re.I)
#re_urlmark = re.compile(r'\["([^"]*)" ([A-Za-z0-9._/~:,-]+)\]')
#re_email = re.compile(r'[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]{4,}')
#re_emailmark = re.compile(r'\["([^"]*)" ([A-Za-z0-9_.-]+@[A-Za-z0-9_.-]{4,})\]')
#
#re_x = re.compile('\a')
#re_blankline = re.compile(r'^\s*$')
#re_comment = re.compile(r'^//')
#re_date = re.compile(r'%%date\b(\((?P<fmt>.*?)\))?', re.I)
#re_img = re.compile(r'\[([\w_,.+%$#@!?+~/-][\w_,.+%$#@!?+~/ -]+\.(png|jpe?g|gif|eps|bmp))\]', re.L+re.I)
#
## the defaults
#title = 'document title'
#author = 'author name'
#currdate = strftime('%Y%m%d',localtime(time()))    # ISO current date
#date = currdate
#f_tt = 0
#listident = []
#f_header = 0
#f_lastblank = 0
#holdspace = ''
#listholdspace = ''
#quotedepth = 0
#skip_continue = 0
#
#
#def printHeader(title, author, date):
#	if doctype == 'sgml':
#		print "<!doctype linuxdoc system>\n<article>"
#		print "<title>%s\n<author>%s\n<date>%s\n" %(title,author,date)
#	elif doctype == 'html':
#		print '<HTML>\n<HEAD><TITLE>%s</TITLE></HEAD>'%title
#		print '<BODY BGCOLOR="white" TEXT="black">'
#		print '<P ALIGN="center"><CENTER><H1>%s</H1>'%title
#		print '<FONT SIZE=4><I>%s</I><BR>\n%s</FONT></CENTER>\n'%(author,date)
#	elif doctype == 'man':
#		# TODO man section 1 is hardcoded...
#		print '.TH "%s" 1 %s "%s"'%(title,date,author)
#	elif doctype == 'pm6':
#		# TODO style to <HR>
#		# TODO unix2dos before apply
#		print """\
#<PMTags1.0 win><C-COLORTABLE ("Preto" 1 0 0 0)
#><@Normal=
#  <FONT "Times New Roman"><CCOLOR "Preto"><SIZE 11>
#  <HORIZONTAL 100><LETTERSPACE 0><CTRACK 127><CSSIZE 70><C+SIZE 58.3>
#  <C-POSITION 33.3><C+POSITION 33.3><P><CBASELINE 0><CNOBREAK 0><CLEADING -0.05>
#  <GGRID 0><GLEFT 7.2><GRIGHT 0><GFIRST 0><G+BEFORE 7.2><G+AFTER 0>
#  <GALIGNMENT "justify"><GMETHOD "proportional"><G& "ENGLISH">
#  <GPAIRS 12><G% 120><GKNEXT 0><GKWIDOW 0><GKORPHAN 0><GTABS $>
#  <GHYPHENATION 2 34 0><GWORDSPACE 75 100 150><GSPACE -5 0 25>
#><@Bullet=<@-PARENT "Normal"><FONT "Abadi MT Condensed Light">
#  <GLEFT 14.4><G+BEFORE 2.15><G% 110><GTABS(25.2 l "")>
#><@PreFormat=<@-PARENT "Normal"><FONT "Lucida Console"><SIZE 8><CTRACK 0>
#  <GLEFT 0><G+BEFORE 0><GALIGNMENT "left"><GWORDSPACE 100 100 100><GSPACE 0 0 0>
#><@Title1=<@-PARENT "Normal"><FONT "Arial"><SIZE 14><B>
#  <GCONTENTS><GLEFT 0><G+BEFORE 0><GALIGNMENT "left">
#><@Title2=<@-PARENT "Title1"><SIZE 12><G+BEFORE 3.6>
#><@Title3=<@-PARENT "Title1"><SIZE 10><GLEFT 7.2><G+BEFORE 7.2>
#><@Title4=<@-PARENT "Title3">
#><@Title5=<@-PARENT "Title3">
#><@Quote=<@-PARENT "Normal"><SIZE 10><I>>
#"""
#	elif doctype == 'mgp':
#		print """\
##!/usr/X11R6/bin/mgp -t 90
#%deffont "normal"    xfont "utopia-medium-r", charset "iso8859-1"
#%deffont "normal-i"  xfont "utopia-medium-i", charset "iso8859-1"
#%deffont "normal-b"  xfont "utopia-bold-r",   charset "iso8859-1"
#%deffont "normal-bi" xfont "utopia-bold-i",   charset "iso8859-1"
#%deffont "mono"     xfont "courier-medium-r", charset "iso8859-1"
#%default 1 size 5
#%default 2 size 8, fore "yellow", font "normal-b", center
#%default 3 size 5, fore "white",  font "normal", left, prefix "  "
#%tab 1 size 4, vgap 30, prefix "     ", icon arc "red" 40, leftfill
#%tab 2 prefix "            ", icon arc "orange" 40, leftfill
#%tab 3 prefix "                   ", icon arc "brown" 40, leftfill
#%tab 4 prefix "                          ", icon arc "darkmagenta" 40, leftfill
#%tab 5 prefix "                                ", icon arc "magenta" 40, leftfill
#%%%%%%%%%%%%%%%%%%%%%%%%%% end of headers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#%page
#"""
#		# 1st title page
#		print '\n\n\n\n%%size 10, center, fore "yellow"\n%s'%title
#		print '\n%%font "normal-i", size 6, fore "white", center\n%s'%author
#		print '%%font "mono", size 7, center\n%s'%date
#
#def printFooter():
#	txt = '%s code generetad by txt2tags %s (%s)'%(doctype,my_version,my_url)
#	if doctype == 'sgml' or doctype == 'html': print "<!-- %s -->"%txt
#	elif doctype == 'mgp': print "%%%% %s"%txt
#	print TAGEOD[T]
#
#def doEscape(txt):
#	if doctype == 'html' or doctype == 'sgml':
#		txt = re.sub('&','&amp;',txt)
#		txt = re.sub('<','&lt;',txt)
#		txt = re.sub('>','&gt;',txt)
#		if doctype == 'sgml': txt = re.sub('˙','&yuml;',txt)
#	elif doctype == 'pm6' : txt = re.sub('<','<\#60>',txt)
#	elif doctype == 'mgp' : txt = re.sub('^%([^%])','%prefix ""\n  %\n%cont, prefix "  "\n\\1',txt)
#	return txt
#
#def doEscapeEscape(txt):
#	while re.search(r'\\<', txt):
#		txt = re.sub(r'\\<','<\#92><',txt)
#	return txt
#
#
#################################################################################
####MerryChristmas,IdontwanttofighttonightwithyouImissyourbodyandIneedyourlove###
#################################################################################
#
## reading our source file
#f = open(file, 'r')
#lines = f.readlines()
#f.close
#
## let's mark it up!
#linenr = 0
#urlmask = '@@__@@'
#for lineref in range(len(lines)):
#	urlbank = []
#	linenr = lineref +1
#	line = doEscape(string.rstrip(lines[lineref]))
#
#	# we need (not really) to mark each paragraph
#	if doctype == 'pm6' and f_lastblank:
#		if f_tt or f_header or listident: holdspace = ''
#		else: holdspace = TAGparagraph[T]
#
## PRE-formatted area
#	# we'll never support beautifiers inside pre-formatted
#	if f_tt: 
#		# closing PRE
#		if re_areaPreClose.search(line):
#			if doctype != 'pm6': print TAGareaPreClose[T]
#			f_tt = 0
#			continue
#		
#		# normal PRE-inside line
#		if doctype == 'pm6': line = doEscapeEscape(line)
#		print line
#		continue
#	
#	# detecting PRE
#	if re_areaPreOpen.search(line):
#		if f_tt:
#			print "%d:opening PRE-formatted tag without closing previous one" %linenr
#			print line
#			continue
#		
#		print TAGareaPreOpen[T]
#		f_tt = 1
#		continue
#
#
## blank lines
#	#TODO "holdspace" to save <p> to not show in closelist
#	if re_blankline.search(line):
#	
#		if f_lastblank:      # 2nd consecutive blank line
#			if listident:    # closes list (if any)
#				while len(listident):
#					if TAGlistClose[T]: print listident[-1]+TAGlistClose[T]
#					del listident[-1]
#			continue         # consecutive blanks are trash
#		
#		if f_header or linenr == 1:  # 1st blank after header (if any)
#			printHeader(title,author,date)
#			if doctype != 'pm6': print TAGparagraph[T]
#			f_header = 0     # we're done with header
#			continue
#		
#		# normal blank line
#		if doctype != 'pm6':
#			# paragraph (if any) is wanted inside lists also
#			if doctype == 'html' or listident:
#				print TAGparagraph[T]
#			# sgml: the quote close tag must not be \n\n</quote>
#			elif doctype == 'sgml' and quotedepth:
#				skip_continue = 1
#			# otherwise we just print a blank line	
#			else: print
#		
#		f_lastblank = 1
#		if not skip_continue: continue
#	else:
#		f_lastblank = 0      # reset blank status
#
#
## comments
#	# just skip them
#	if re_comment.search(line):
#		f_lastblank = 1
#		continue
#
#
## one line PRE-formatted text
#	if re_1linePre.search(line): 
#		line = re_1linePre.sub(r'\1',line)
#		if doctype == 'pm6': line = doEscapeEscape(line)
#		print '%s\n%s\n%s'%(TAGareaPreOpen[T],line,TAGareaPreClose[T]) 
#		continue
#
#
## HR line
#	if re_bar.search(line):
#		txt = re_bar.search(line).group(1)
#		if txt[0] == '=': bar = TAGbar2[T]
#		else            : bar = TAGbar1[T]
#		line = re_bar.sub(bar,line)
#		print re_x.sub(txt,line)
#		continue
#
#
## quote
#	if re_quote.search(line):
#		currquotedepth = len(re_quote.search(line).group(0)) # number of TABs
#		if doctype == 'sgml' and quotedepth and currquotedepth > quotedepth: currquotedepth = quotedepth
#		if not TAGareaQuoteClose[T]:
#			line = re_quote.sub(TAGareaQuoteOpen[T]*currquotedepth, line)
#		else:
#			# new (sub)quote
#			if not quotedepth or currquotedepth > quotedepth:
#				quotedepth = currquotedepth
#				print TAGareaQuoteOpen[T]
#			
#			if doctype != 'html'and doctype != 'sgml':
#				line = re_quote.sub('', line)
#			
#			# closing quotes
#			while currquotedepth < quotedepth:
#				quotedepth = quotedepth-1
#				print TAGareaQuoteClose[T]
#	else:
#		# closing quotes
#		while quotedepth:
#			quotedepth = quotedepth-1
#			print TAGareaQuoteClose[T]
#
#
## list
#	if re_list.search(line) and doctype != 'txt':
#		listitemident = re_list.search(line).group(1)
#		
#		# new sublist
#		if not listident or len(listitemident) > len(listident[-1]):
#			listident.append(listitemident)
#			openlist = listident[-1]+TAGlistOpen[T]
#			if doctype == 'pm6': listholdspace = openlist
#			else:
#				if string.strip(openlist): print openlist
#		
#		# closing sublists
#		while len(listitemident) < len(listident[-1]):
#			if TAGlistClose[T]: print listident[-1]+TAGlistClose[T]
#			del listident[-1]
#		
#		# normal item	
#		listid = listident[-1]
#		if doctype == 'mgp': listid = len(listident)*'\t'
#		line = re_list.sub(listid+TAGlistItem[T]+r'\2',line)
#		if listholdspace:
#			line = listholdspace+line
#			listholdspace = ''
#		if doctype == 'sgml': line = re.sub(r'\[', r'&lsqb;', line)
#
## title
#	#TODO set next blank and set f_lastblank or f_lasttitle
#	if re_title.search(line) and not listident:
#		m = re_title.search(line)
#		tag = m.group('tag')
#		tag = eval('TAGtitle'+`len(tag)`+'[T]')
#		
#		txt = string.strip(m.group('txt'))
#		if doctype == 'sgml': txt = re.sub(r'\[', r'&lsqb;', txt)
#		if doctype == 'sgml': txt = re.sub(r'\\', r'&bsol;', txt)
#		
#		line = re_title.sub(tag,line)
#		print re_x.sub(txt,line)
#		continue
#		
##		labeltxt = ''
##		label = m.group('label')
##		if label: labeltxt = '<label id="%s">' %label
#
#
#### BEGIN of at-any-part-of-the-line/various-per-line TAGs.
#
## date
#	if re_date.search(line):
#		m = re_date.search(line)
#		fmt = m.group('fmt')
#		if fmt: currdate = strftime(fmt,localtime(time()))
#		line = re_date.sub(currdate,line) 
#
## bold
#	if re_bold.search(line):
#		txt = r'%s\1%s'%(TAGfontBoldOpen[T],TAGfontBoldClose[T])
#		line = re_bold.sub(txt,line) 
##		if doctype == 'man': 
##			line = re.sub((TAGfontBoldItalicOpen[T]) ,r'\1',line) 
#
## italic
#	if re_italic.search(line):
#		txt = r'\1%s\2%s'%(TAGfontItalicOpen[T],TAGfontItalicClose[T]) 
#		line = re_italic.sub(txt,line) 
#
## bolditalic
#	if re_bolditalic.search(line):
#		txt = r'%s\1%s'%(TAGfontBoldItalicOpen[T],TAGfontBoldItalicClose[T])
#		line = re_bolditalic.sub(txt,line) 
#
## underline
#	if re_underline.search(line):
#		txt = r'%s\1%s'%(TAGfontUnderlineOpen[T],TAGfontUnderlineClose[T])
#		line = re_underline.sub(txt,line) 
#
## image
#	if re_img.search(line):
#		txt = re_img.search(line).group(1)
#		line = re_img.sub(TAGimg[T],line)
#		line = re_x.sub(txt,line)
#		
#		if doctype == 'sgml': line = re.sub(r'\[', r'&lsqb;', line)
#
## font PRE
#	if re_mono.search(line):
#		txt = r'%s\1%s'%(TAGfontMonoOpen[T],TAGfontMonoClose[T]) 
#		line = re_mono.sub(txt,line) 
#
## URL & email
#	# all this mask thing is to prevent re_url match already converted URLs
#	url_isemail = 0
#	while re_urlmark.search(line) or re_emailmark.search(line):
#		m = re_urlmark.search(line)
#		if not m:
#			m = re_emailmark.search(line)
#			url_isemail = 1
#		label = m.group(1)
#		url = m.group(2)
#		if not label: label = url               # for ["" link] cases
#		urlbank.append(url)
#		if url_isemail: line = re_emailmark.sub(TAGemailMark[T],line,1)
#		else:           line = re_urlmark.sub(TAGurlMark[T],line,1)
#		urlorder = [label, urlmask]             # label before link
#		if doctype in ('html', 'sgml', 'moin'): # link before label
#			urlorder = [urlmask, label]
#		for urlpart in urlorder:                # s/\a/mask|label/
#			line = re_x.sub(urlpart,line,1)
#	
#	while re_url.search(line) or re_email.search(line):
#		m = re_url.search(line)
#		if not m:   # email
#			m = re_email.search(line)
#			url_tag = TAGemail[T]
#			line = re_email.sub(url_tag,line,1)
#		else:       # url
#			url_tag = TAGurl[T]
#			line = re_url.sub(url_tag,line,1)
#		line = re_x.sub(urlmask,line)
#		
#		for urlcount in range(string.count(url_tag, '\a')): # for each \a
#			urlbank.append(m.group(0))
#
#
## finish URL & Email 
#	# replacing URL masks with URLs, one by one (if any)
#	for url in urlbank: line = re.sub(urlmask,url,line,1)
#
#
## header	
#	if linenr == 1:
#		title = line
#		f_header = 1 
#		continue
#	if f_header:
#		if   linenr == 2:
#			author = line
#			continue
#		elif linenr == 3:
#			date = line
#			continue
#		else:
#			printHeader(title,author,date)
#			f_header = 0
#			
#	# FINAL scapes. TODO function for it
#	# convert all \ before <...> to tag
#	if doctype == 'pm6': line = doEscapeEscape(line)
#	elif doctype == 'man' : line = re.sub('-',r'\-',line)
#	
#	if listident: holdspace = ''
#	print holdspace+line
#	holdspace = ''
#
#printFooter()
#
#
#
####  RESOURCES
## man: man 7 man
## sgml: www.linuxdoc.org
## sgml:
##   <table>
##   <tabular ca="cl">
##   cel1-1<colsep>cel1-2<rowsep>
##   cel2-1<colsep>cel2-2<rowsep>
##   </tabular>
##   </table>
## pm6: <font$> volta ao normal do estilo
## pm6: <#comentários#> <font #comment# $>
##  pagemaker table
##  1 = 0,55
##  2 = 1,10
##  3 = 1,65
##  4 = 2,20
## 
##        |__1_|    |    |    |    |    | 
##        |_______2_|    |    |    |    | 
##        |____________3_|    |    |    | 
