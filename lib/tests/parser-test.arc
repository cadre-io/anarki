(register-test '(suite "parser tests"
  ("parse a single symbol"              (parse "foo")                   foo                 )
  ("parse a single symbol: is sym"      (type:parse "foo")              sym                 )
  ("parse a single string"              (parse "\"foo\"")               "foo"               )
  ("parse a single string: is string"   (type:parse "\"foo\"")          string              )
  ("parse a quoted symbol"              (parse "'foo")                  'foo                )
  ("parse an empty list"                (parse "()")                    ()                  )
  ("parse an empty list: is sym"        (type:parse "()")               sym                 )
  ("parse a character"                  (parse "#\\a")                  #\a                 )
  ("parse a char by number"             (parse "#\\103")                #\C                 )
  ("parse a newline character"          (parse "#\\
")                                                                      #\newline           )
  ("parse a character: is char"         (type:parse "#\\a")             char                )
  ("parse a number"                     (parse "99/101")                99/101              )
  ("parse a number: is num"             (type:parse "99/101")           num                 )
  ("parse numbers in a list"            (parse "(12 34.56 -17 3/4)")    (12 34.56 -17 3/4)  )
  ("parse an improper list"             (parse "(a b c . d)")           (a b c . d))
  ("parse a list of characters"         
    (eval (parse "(coerce '(#\\( #\\a #\\b #\\space #\\c #\\  #\\d #\\)) 'string)"))
    "(ab c d)")
  ("raise error for unrecognised chars"
    (on-err (fn (ex) (details ex)) (fn () (parse "#\\spade")))
    "unknown char: #\\spade")
  ("parse a string containing spaces"
    (parse "\"foo bar\"")               
    "foo bar")
  ("completely ignore comments"
    (parse "(foo bar) ; the foo bar\n; more commentary")               
    (foo bar))
  ("parse quote non-atom"
    (parse "'(foo bar)")               
    '(foo bar))
  ("parse whitespace before closing paren"
    (parse "(foo bar )")               
    (foo bar))
  ("parse a nasty string containing parens and escapes"
    (parse "(parse \"\\\"foo bar\\\"\")")
    (parse "\"foo bar\""))
  ("parse bracket syntax for functions"
    (apply (eval (parse "[* _ _]")) '(27))
    729)
  ("interpolations expand to (string ...)"
    (parse:string "\"one #" "(2) three #" "(4)\"")
    (string "one " 2 " three " 4))
  ("parse string interpolations"
    (eval (parse:string "(with (foo 120 bar \"this\") \"foo is #" "((/ foo 10)), bar is #" "(bar), x is #" "((+ 1 2 3))\")"))
    "foo is 12, bar is this, x is 6")
  ("parse escaped interpolations"
    (coerce (parse:string "\"foo \\#" "(foo)\"") 'cons)
    (#\f #\o #\o #\space #\# #\( #\f #\o #\o #\)))
  ("parse a complex expression"    
    (parse "(foo bar '(toto) `(do ,blah ,@blahs \"astring\") titi)")
    (foo bar '(toto) `(do ,blah ,@blahs "astring") titi))))

(register-test '(suite "source code indexer test"
  ("index a proper expression"
    (index-source "\n(def foo (bar)\n  (toto 'a \"blah\"))")
    (((syntax left-paren    1 35 )
      (sym    def           2  5 )
      (sym    foo           6  9 )
      (syntax left-paren   10 15 )
      (sym    bar          11 14 )
      (syntax right-paren  10 15 )
      (syntax left-paren   18 34 )
      (sym    toto         19 23 )
      (syntax quote        24 25 )
      (sym    a            25 26 )
      (syntax          left-string-delimiter  27 33 )
      (string-fragment "blah"                 28 32 )
      (syntax          right-string-delimiter 27 33 )
      (syntax right-paren  18 34 )
      (syntax right-paren   1 35 )) 3))

  ("index an unbalanced left-paren"
    (index-source "(def foo (bar) (toto 'a \"blah\")") 
    (((syntax unmatched-left-paren     0  1 )
      (sym    def                      1  4 )
      (sym    foo                      5  8 )
      (syntax left-paren               9 14 )
      (sym    bar                     10 13 )
      (syntax right-paren              9 14 )
      (syntax left-paren              15 31 )
      (sym    toto                    16 20 )
      (syntax quote                   21 22 )
      (sym    a                       22 23 )
      (syntax left-string-delimiter   24 30 )
      (string-fragment "blah"         25 29 )
      (syntax right-string-delimiter  24 30 )
      (syntax right-paren             15 31 )) 1))

  ("index an unbalanced left-bracket"
    (index-source "(map [disp _ val)") 
    (((syntax left-paren               0 17 )
      (sym    map                      1  4 )
      (syntax unmatched-left-bracket   5  6 )
      (sym    disp                     6 10 )
      (sym    _                       11 12 )
      (sym    val                     13 16 )
      (syntax right-paren              0 17 )) 1))
     
  ("index an unbalanced right-paren"
    (index-source "(prn (foo (x) y))) (prn 'yo)") 
    (((syntax left-paren               0 17 )
      (sym    prn                      1  4 )
      (syntax left-paren               5 16 )
      (sym    foo                      6  9 )
      (syntax left-paren              10 13 )
      (sym    x                       11 12 )
      (syntax right-paren             10 13 )
      (sym    y                       14 15 )
      (syntax right-paren              5 16 )
      (syntax right-paren              0 17 )
      (syntax unmatched-right-paren   17 18 )
      (syntax left-paren              19 28 )
      (sym    prn                     20 23 )
      (syntax quote                   24 25 )
      (sym    yo                      25 27 )
      (syntax right-paren             19 28 )) 1))))
