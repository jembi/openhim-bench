OpenHIM Bench
=============

Vagrant/Puppet can be used to setup a development instance of OpenHIM core. Simply run ```vagrant up``` from within the ```env/``` directory.

A shared folder will be setup in the vm that includes the directory with the source code. So you can run the benchmark suite as follows:
```
cd /openhim-bench/
./bench.sh
```
