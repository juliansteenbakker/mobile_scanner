#!/bin/bash

# We assume that the build takes longer than 200 seconds.
sleep 200

for i in {1..100}
do
   adb shell screencap -p > test_results/$i.jpg
   sleep 1
done