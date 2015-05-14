jackd  --realtime -p8 -t100000 -d alsa -dhw:1 -p512 -n3 -H -M -z none -s&
sleep 3
~/chuck --in1 Looper/looper-pedal.ck

