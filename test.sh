#!/bin/bash

function ciao {
	echo 2
}

if [ $(ciao) -eq 0 ]; then
	echo "zero"
else
	echo "nonzero"
fi