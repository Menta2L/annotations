%name Annotation_
%declare_class {class Annotation_Parser }
%include_class {
    public $body = array();

    const T_ARRAY = 308;

    const T_ANNOTATION = 300;

    private $input;

    private $N;

    public $token;

    public $value;

    public $line;

    function parse($str) {
        $this->input = $this->remove_comment_separators($str);
        $this->N = 0;
        $this->line = 1;
        while ($this->yylex()) {
             if ($this->token < 0){
                 continue;
             }
             $this->doParse($this->token, $this->value);
        }
        $this->doParse(self::T_NEWLINE, "\n");

        return $this->body;
    }
    function remove_comment_separators($comment) {
            str_replace("\r\n", "\n", $comment);
            $start_mode = 1;
            $processed_str = '';
    	    for ($i = 0; $i < strlen($comment); $i++) {
    		    $ch = $comment[$i];
        		if ($start_mode) {
    			    if ($ch == ' ' || $ch == '*' || $ch == '/' || $ch == "\t" || ord($ch) == 11) {
    				    continue;
    			    }
    			    $start_mode = 0;
    		    }
    		    if ($ch == '@') {
        			$processed_str.= $ch;
    	    		$i++;
        			$open_parentheses = 0;
    	    		for ($j = $i; $j < strlen($comment); $j++) {
    		    		$ch = $comment[$j];
    			    	if ($start_mode) {
    				    	if ($ch == ' ' || $ch == '*' || $ch == '/' || $ch == "\t" || ord($ch) == 11) {
    					    	continue;
    					    }
    					    $start_mode = 0;
    				    }
    				    if ($open_parentheses == 0) {
    					    if (ctype_alnum($ch) || '_' == $ch || '\\' == $ch) {
    						    $processed_str.= $ch;
    						    continue;
    					    }
    					    if ($ch == '(') {
    						    $processed_str.= $ch;
    						    $open_parentheses++;
    						    continue;
    					    }

    				    } else {
    					    $processed_str.= $ch;
    					    if ($ch == '(') {
    						    $open_parentheses++;
    					    } else {
    						    if ($ch == ')') {
    							    $open_parentheses--;
    						    } else {
    							    if ($ch == "\n") {
    								    $start_mode = 1;
    							    }
    						    }
    					    }
    					    if ($open_parentheses > 0) {
    						    continue;
    					    }
    				    }
        				$i = $j;
    	    			$processed_str.= "\n";
    		    		break;
    			    }
    		    }
        		if ($ch == '\n') {
    	    		$start_mode = 1;
    		    }
    	    }
    	    return $processed_str;
    }
    /*!lex2php
    %input $this->input
    %counter $this->N
    %token $this->token
    %value $this->value
    %line $this->line
    %unicode 1

    TDOUBLE = /([\-]?[0-9]+[\.][0-9]+)/
    TINTEGER = /[\-]?[0-9]+/
    TNULL = /null/
    TFALSE = /false/
    TTRUE = /true/
    TSTRING = ~(\x22|\x27)((?!\1).|\1{2})*\1~
    TIDENTIFIER = /\x5C?[a-zA-Z][_a-zA-Z0-9]+/
    TPARENTHESES_OPEN = ~\s*[(]\s*~
    TPARENTHESES_CLOSE = ~\s*[)]~
    TBRACKET_OPEN = ~\s*[{]\s*~
    TBRACKET_CLOSE = ~\s*[}]~
    TSBRACKET_OPEN = ~\[\s*~
    TSBRACKET_CLOSE = ~\s*\]~
    TAT = ~[@]~
    TEQUALS = ~\s*[=]\s*~
    TCOLON = ~\s*[:]\s*~
    TCOMMA =~\s*[,]\s*~
    TNEWLINE = /\n/
    WHITESPACE = /[ \n\t]+/
    TLOP = ~\s+(&&|\|\|)\s+~
    TOP = ~\s*(([!=][=]{1,2})|([<][=>]?)|([>][=]?)|[&|]{2})\s*~
    */

/*!lex2php
%statename START
TAT {
    $this->token = self::T_AT;
}
TIDENTIFIER {
    $this->token = self::T_IDENTIFIER;
}
TDOUBLE {
    $this->token = self::T_DOUBLE;
}
TINTEGER {
    $this->token = self::T_INTEGER;
}
TNULL {
    $this->token = self::T_NULL;
}
TFALSE {
    $this->token = self::T_FALSE;
}
TTRUE {
    $this->token = self::T_TRUE;
}
TPARENTHESES_OPEN {
    $this->token = self::T_PARENTHESES_OPEN;
}
TSTRING {
    $this->token = self::T_STRING;
}

TPARENTHESES_CLOSE {
    $this->token = self::T_PARENTHESES_CLOSE;
}
TBRACKET_OPEN {
    $this->token = self::T_BRACKET_OPEN;

}
TBRACKET_CLOSE {
    $this->token = self::T_BRACKET_CLOSE;

}
TEQUALS {
    $this->token = self::T_EQUALS;
}
TCOLON {
    $this->token = self::T_COLON;
}
TCOMMA {
    $this->token = self::T_COMMA;
}
TSBRACKET_OPEN {
    $this->token = self::T_SBRACKET_OPEN;
}
TSBRACKET_CLOSE {
    $this->token = self::T_SBRACKET_CLOSE;
}
TNEWLINE {
    return false;
}
*/
}

%syntax_error {
  foreach ($this->yy_get_expected_tokens($yymajor) as $token)
    $expect[] = self::$yyTokenName[$token];
  throw new Exception('Unexpected ' . $this->tokenName($yymajor) .
    '(' . $TOKEN . ') on line '.$this->line.', expected one of: ' . implode(',', $expect));
}

%left T_COMMA.

start ::= body.

body ::= body code.
body ::= .

code ::= T_NEWLINE.

code ::= T_AT T_IDENTIFIER(I) T_PARENTHESES_OPEN argument_list(L) T_PARENTHESES_CLOSE .  {
    $this->body[] = [ trim(I) => L];
}

argument_list(R) ::= argument_list(L) T_COMMA argument_item(I) . {
      foreach (L as $item) {
        R[] = $item;
      }
	  R[] = I;
}

argument_list(R) ::= argument_item(I) . {
    R[] = I;
}

argument_item(R) ::= expr(E) . {
    R = ['expr' => E];
}

argument_item(R) ::= T_STRING(S) T_EQUALS expr(E) . {
    R = ['expr' => E,'name' => S];
}

argument_item(R) ::= T_STRING(S) T_COLON expr(E) . {
    R = ['expr' => E,'name' => S];
}

argument_item(R) ::= T_IDENTIFIER(I) T_EQUALS expr(E) . {
    R = ['expr' => E,'name' => I];
}

argument_item(R) ::= T_IDENTIFIER(I) T_COLON expr(E) . {
	    R = ['expr' => E,'name' => I];
}

expr(R) ::= array(A) . {
	R = A;
}

expr(R) ::= T_IDENTIFIER(I) . {
    R = ['type' => self::T_IDENTIFIER ,'value' => I];
}

expr(R) ::= T_INTEGER(I) . {
    R = ['type' => self::T_INTEGER ,'value' => I];
}

expr(R) ::= T_STRING(S) . {
	    R = ['type' => self::T_STRING ,'value' => S];
}

expr(R) ::= T_DOUBLE(D) . {
	R = ['type' => self::T_DOUBLE ,'value' => D];
}

expr(R) ::= T_NULL . {
	R = ['type' => self::T_NULL ,'value' => null];
}

expr(R) ::= T_FALSE . {
	R = ['type' => self::T_FALSE ,'value' => false];
}

expr(R) ::= T_TRUE . {
	R = ['type' => self::T_TRUE ,'value' => true];
}

array(R) ::= T_BRACKET_OPEN argument_list(A) T_BRACKET_CLOSE . {
    R = ['type' => self::T_ARRAY ,'items' => A];

}

array(R) ::= T_SBRACKET_OPEN argument_list(A) T_SBRACKET_CLOSE . {
	R = ['type' => self::T_ARRAY ,'items' => A];
}