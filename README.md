# ParadropEmonixDemo
Snappy Package for Emonix SmartVent Demo on Paradrop

# Instructions
+ **Step 1:** Creating the Snappy Package

shell> snapcraft

will create the snappy package.

+ **Step 2:** Installing on Paradrop

shell> ./install\_on\_paradrop

will install the package on the paradrop router, assuming that the ssh alias for the router is "paradrop"

+ **Step 3:** Configuring Settings

To adjust the temperature threshold (for the vent to decide to open/close), the value of the "$temperature\_threshold" variable should be adjusted in the file control\_vent.pl. This change can be made in the development machine, recompiled as a new snappy package and reinstalled on the router, OR, can directly be changed on the router using vim-tiny.

In both cases, the vent processes should be restarted by first running

shell> sudo "install dir"/emonix-smartvent-killall

shell> sudo "install dir"/emonix-smartvent

+ **Step 4:** Setting up the vent

Hardware Setup:

The connections should be as illustrated in the pictures from this album: https://goo.gl/photos/eWHXn4d16V3KxevKA

Software Setup:

  - Holding the RESET button on the sensor board during and after powerup (for about 5-10 seconds) will erase the programmed network settings on the sensor board and put it in Access Point mode.
  - The Access Point name will be "xbee...". It will be an open connection.
  - Connect to the AP using the development computer and open the address: 192.168.1.10:9750 on a browser
  - Type in the correct network parameters, as illustrated in this image: https://goo.gl/photos/HfQDvbgYPYHrXLTQ7
  - NOTE: The controller URI is the IP address of the server (in the case of the paradrop router, this will be the gateway, which in the example was 192.168.128.1)
  - NOTE: Only open APs and WPA2 APs will work with the sensor board
  - Type in your email address
  - Click submit

The sensor node should associate with the AP and start logging data on the paradrop router

+ **Step 5:** Verifying

The data logging happens ~ once / minute. A quick way to check if everything went fine is to see if, on the paradrop router/

  - /home/ubuntu/smartvent/vpn\_ip exists and has a valid value. This is the IP address of the sensor node on the smartvent VPN
  - /home/ubuntu/smartvent/data.csv exists and has valid values.

