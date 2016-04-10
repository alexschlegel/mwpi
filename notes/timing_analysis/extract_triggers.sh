#!/bin/bash

codes=(16mar16eb 16mar16kh 05apr16ph 02apr16gd 05apr16gl)

for code in ${codes[@]}
do
	grep 'scanner\sTR' $code.log | gawk -F'[[:blank:]/]*' '{printf "%d, %.3f;\n", $4, $1}' > ${code}_triggers.csv
done
			
