cd ~/LoopPI
sudo python buttons.py &
./start.sh | tee -a ~/looper.log
echo "exited - cleaning up"
ps aux | grep button | grep python | grep "on[s]" | awk '{print $2}' | xargs sudo kill
killall chuck
killall jackd
echo "Ended"

