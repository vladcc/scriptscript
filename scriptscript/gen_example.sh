#!/bin/bash

function main
{
	pushd "$(dirname $(realpath $0))" > /dev/null
	
	awk -f scriptscript.awk -vScriptName=test_gen.awk -vScriptVersion=1.0 test_rules.txt | \
	awk '
	/<user_events>/,/<\/user_events>/ {next}
	
	function INCLUDE() {return "@include \"inc_user_events.awk\""}
	$0 ~ /<user_api>/ {print sprintf("%s\n\n%s", $0, INCLUDE()); next}
	 
	{print $0}
	' > ./example/test_gen.awk 

	popd > /dev/null
}

main
