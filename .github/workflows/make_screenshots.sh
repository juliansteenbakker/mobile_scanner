#!/bin/bash

# We assume that the build takes longer than 200 seconds.
sleep 300

for i in {1..1000}
do
   adb shell screencap -p > test_results/$i.jpg
   sleep 1
done