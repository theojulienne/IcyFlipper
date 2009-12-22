#!/bin/sh

SCRIPT_PATH=`dirname $0`

cd $SCRIPT_PATH/../../../../
dsss distclean
dsss build