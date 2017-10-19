<?php

require_once "parser.php";

$text = <<<EOT
/**
 * TestClass
 *
 * This is a test class, it's useful to make tests
 *
 * @RecursiveHash({key1="value", "key2"=value, "key3"=[1.1, 2, 3, 4]});
 * @AlternativeHashParams({"key1"="value", "key2"="value", "key3"="value"},"foo"="bar");
 * @TestHash("a"="b");
 *
 */
EOT;

$p = new Annotation_Parser();
$data = $p->parse($text);

print_r($data);


?>
