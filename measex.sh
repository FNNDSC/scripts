#!/bin/bash

DICOMFILE=$1

strings $DICOMFILE | sed -n '/BEGIN/,/END/p'
