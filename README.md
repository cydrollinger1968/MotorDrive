# MotorDrive						   
>Design: Motor Driver with Bluetooth 		   
>Engineer: Cy Drollinger								   
>Date: 6/25											           
>Email: cydrollinger@gmail.com
![Motor Driver](/docs/images/motorDRVjlc.png)
**PURPOSE:**
This design is an attempt at building a global team implementing an open source generic three phase brushless direct current(BLDC) motor driver. The completed hardware design, prototype, adds immediate value to you through turn-key manufacturing at a low price, jlcpcb.com. Future development is necessary in the areas of firmware, software and mechanical technologies in order to complete a sophisticated electro-mechanical system. This current hardware design with your contributions could leverage the following examples of today's cutting edge technologies: <a href="https://hubblenetwork.com/">Hubble Network< a/>, <a href="https://wirepas.com/">WirePas<a/>, and <a href="https://www.zephyrproject.org/"<Zephyr RTOS<a/>  enabling future technological solutions.    
Three file structures are necessary to upload at <a href ="https://jlcpcb.com/">JLCPCB.com<a/> for turn-key manufacturing: gerber/jlcpcb6lry/jlcpcb6lyr.zip, manufacturing/DRVjlc(2)_top_cpl.csv, and manufacturing/DRVjlc(2)_top_bom.csv. This would result in the following model of your new hardware: 
![motor drive jlcpcb](/docs/images/jlcII.png)
**TECHNOLOGIES:**<br />
GCT: <a href="https://gct.co/connector/usb4110">USBC connector</a> <br />
OnSemi: <a href="https://www.onsemi.com/products/interfaces/usb-type-c/fusb302b">USBC Controller</a><br />
NordicSemiconductor:<a href="https://www.nordicsemi.com/Products/nRF52840">nRF52840</a> <br />
Texas Instrument:<a href="https://www.ti.com/product/DRV8316?keyMatch=DRV8316&tisearch=universal_search&usecase=GPN-ALT">DRV8316</a> <br />
TDK:<a href="https://product.tdk.com/en/search/sensor/mortion-inertial/imu/info?part_no=ICM-20948">ICM-20948</a><br />
Analog Devices:<a href="https://www.analog.com/en/products/lt8640.html">LT8640</a> <br />
**LICENSES:**<br />
NONE