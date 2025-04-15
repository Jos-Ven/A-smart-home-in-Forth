needs Common-extensions.f  cr \ Basic tools for Gforth and Win32Forth.
marker _SensorWeb1.fs .latest \ To support extra sensors and devices. By J.v.d.Ven. 04-06-2024
                              \ It needs Gforth on a Raspberry Pi with linux (Jessie or Bullseye)
                              \ Enable the interfaces I2c and Spi with: sudo raspi-config

cr .( Activated options:)
\ Extra options that can be activated by deleting the backslash before the marker.

\ MARKER AdminPage      .latest \ For a link to the AdministrationPage for multiple RPI's or multiple ESP32 systems
\                               \  Use it only on one RPI in your network.

\ Sensor related:
\ MARKER AdcMcp3008     .latest \ To read the ADC of an mcp3008
\ MARKER Bme280Sensor   .latest \ Loads the the bme280 driver and plotter and home page
\ MARKER Bme280Outside  .latest \ Changes the abstract if the bme280 is placed outside
\ MARKER ldr            .latest \ For a lightsensor connected to a Mcp3008 at channel 0
\ MARKER Mq135Sensor    .latest \ Gas sensor for: NH3, NOx, alcohol, Benzene, smoke, CO2. Needs an ADC
\ MARKER NegateLdr      .latest \ Reverses the LDR values
\ MARKER PushBme280Data .latest \ To send Bme280Data to another Rpi
\ MARKER Resetbutton    .latest \ To Reset when the system hangs.
\ MARKER SendingState   .latest \ Sent sensor (Bme280Data) state and gpio state to the admin server

\ Controlling:
\ MARKER CentralHeating .latest \ To set a Central heating in the nightmode
\ MARKER ControlWindow  .latest \ To control a window opener
\ MARKER ControlLights  .latest \ Used to controll all lights in the main room. Was LowLightLevel.

\ MARKER DisableUpdServer .latest \ For applications that uses a special udp-server like in  _UploadServer.f
\ MARKER WarningLight   .latest \ Used to put a warning light on when the presure drops below 1007 HPA

\ Layout options:
\ MARKER DisableLogging .latest \ Disable logging after starting the webserver
\ MARKER Floorplan      .latest \ Changes the abstract to print a floorplan
\ MARKER FloordataToMsgBoard .latest \ Sent floordata also to a message board
\ MARKER SitesIndexOpt  .latest \ Makes the index with links visible
\ MARKER WiFiBitRate    .latest \ Overwrites mq135 data with the WiFiBitRate in Wifi_signal.fs in the graph.
\ MARKER WiFiBitSignal  .latest \ Overwrites ldr data with the signal level of the WiFi connection in the graph.


s" Documents/MachineSettings.fs" file-status nip 0= [if]
            needs Documents/MachineSettings.fs    \ Optional, to load machine depended markers.
            [THEN]

cr s" gpio -v"  ShGet nip        \ Is the wiringPi installed?
[if]  needs wiringPi.fs          \ From: https://github.com/kristopherjohnson/wiringPi_gforth
      needs gpio.fs              \ To control and administer GPio pins
[then]

needs multiport_gate.f     \ To monitor and handle complex logical decisions

\ Options depended on the activated marker
[defined] AdminPage      [IF]  Needs Master.fs      [ELSE] needs slave.fs   [THEN]  \ Also loads the webserver

\  Input devices and sensors
needs     Wifi_signal.fs       \ For WiFi signal strength
[defined] Resetbutton    [IF]  needs resetbutton.fs [THEN]
[defined] AdcMcp3008     [IF]  needs mcp3008.fs     [THEN]
[defined] Mq135Sensor    [IF]  needs mq135.fs       [THEN]
[defined] ldr            [IF]  needs ldr.fs         [THEN]
[defined] Bme280Sensor   [IF]  needs bme280.fs      [THEN]

\ Add your own sensor here....

: WiFiBitRate@|Mq135f@    ( - f ) [DEFINED] Mq135f@  [IF]   Mq135f@  [ELSE]  WiFiBitRate@    [THEN]  ;
: WiFiSignalLeve@|Ldrf@%  ( - f ) [DEFINED] Ldrf@%   [IF]   Ldrf@%   [ELSE]  WiFiSignalLeve@ [THEN]  ;

:  NotSet ( f: - n ) 0.0001e ;

\ The following 3 vectors are ignored when a BME280 is acivated
defer PressureSensor    ' NotSet is PressureSensor
defer TemperatureSensor ' NotSet is TemperatureSensor
defer HumiditySensor    ' NotSet is HumiditySensor

defer PollutionSensor   ' WiFiBitRate@|Mq135f@    is PollutionSensor
defer LdrSensor         ' WiFiSignalLeve@|Ldrf@%  is LdrSensor

needs avsampler.fs         \ Calculates an average for a number of samples.
needs bsearch.f            \ For a quick search in a sorted file.
needs svg_plotter.f        \ To plot simple charts for a web client.
needs bme280-logger.fs     \ Contains the data definitions. It also logs non BME280 data
needs bme280-output.fs     \ To format the output
[defined] CentralHeating [defined] Floorplan or     [IF] needs CentralHeating.fs    [ELSE] : OnStandby ;   [THEN]

\  Controls depended on sensors:
[DEFINED] ControlLights [IF] needs LightControl.fs  [THEN]
[DEFINED] ControlWindow [IF] Needs windowcontrol.f  [THEN]

[defined] SitesIndexOpt [defined] AdminPage and \ Needs both on the master
      [IF]    needs sitelinks.fs
              1 to #IndexSite   \ #IndexSite is network wide! Change #IndexSite to your server-ID
              cr cr .( NOTE: The server-id for the index page is set to:)
              #IndexSite dup .  .( IP:) ipAdress$ type
              cr .( This system has server-ID:) FindOwnId .

              needs SitesIndex.fs \ A page with links to ControlLights and ControlWindow
      [THEN]

needs graphics.fs          \ To plot historical data
needs job_support.fs       \ For background tasks.
needs schedule_daily.fs    \ Actions at a planned time.


\ Options to see the complete received request:
\ ' see-UDP-request  is udp-requests
\ ' see-request is handle-request

cr cr .( Starting the webserver-light.)
cr    .( The context will be TCP/IP only !  +a will get Forth again.)

start-servers
