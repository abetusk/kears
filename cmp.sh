#!/bin/bash


chip="attiny13"

s=$1
b=`basename $1 .asm`



if [[ -z "$s" || ! -e "$s" ]]
then
  echo provide source file
  exit 1
fi

sec=`date '+%s'`;

mkdir -p .bak
cp $s .bak/$s.$sec

echo using $b for chip $chip

m4 $s > $b.S

avr-as -mmcu=$chip -o $b.o $b.S
if [ "$?" -ne 0 ]
then
  exit $?
fi

avr-ld -o $b.elf $b.o
if [ "$?" -ne 0 ]
then
  exit $?
fi

avr-objcopy --output-target=ihex $b.elf $b.ihex
if [ "$?" -ne 0 ]
then
  exit $?
fi






