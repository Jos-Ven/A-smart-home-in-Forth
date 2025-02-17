# A-smart-home-in-Forth

This project contains the Web-server-light.

The Web-server-light is used to make a smart home that runs local under gForth.
The cloud or an IOT-hub are not needed.
Just run gForth with a webserver and connect it to a wifi router.

The aims for the web-server-light are:
1. To be able to run a smart home by using a wireless UDP or TCP connection.
2. Exchange data between servers.
3. Keep all data local.

Thanks to the added **multi port gates** you do not have to take any action to put on a number of lights or open a window. 
The multi port gates also allows you to monitor what is going on.
Of course you can override then if you like to.

The Web-server-light runs best under Linux on a Raspberry Zero W.
A PC with Linux (Bookworm) or PC with Windows10/11 can also be used.

Read the Installation guide for the details.
Here is how a smart home may look under Linux when _SensorWeb1.fs is compiled with the option SitesIndexOpt active:

![01_ScreenShot](https://github.com/Jos-Ven/A-smart-home-in-Forth/assets/47664564/6e1347e7-d738-40e5-bccf-d34910833473)


![02_ScreenShot](https://github.com/Jos-Ven/A-smart-home-in-Forth/assets/47664564/094546f4-3e19-447e-9fbc-f9676bee5250)

A multi port gate:

![04_ScreenShot](https://github.com/Jos-Ven/A-smart-home-in-Forth/assets/47664564/7731ace1-5a45-4702-9653-5d4201979c6f)



