# MotorDrive						   
>Design: Motor Driver with Bluetooth 		   
>Engineer: Cy Drollinger								   
>Date: 6/25											           
>Email: cydrollinger@gmail.com
![Motor Driver](/docs/images/motorDRVjlc.png)
**PURPOSE:**<br />
This design attempts to build global collaboration implementing an open source generic three phase brushless direct current(BLDC) motor driver. Transparency is primary and allows anyone access to every bit of design. The completed hardware design, a prototype, adds immediate value to you through low price turn-key manufacturing at jlcpcb.com. Future development is necessary in the areas of firmware, software, mechanical, hardware, and Github repository technologies to complete a sophisticated but transparnet electro-mechanical system. This current hardware design with your contributions could leverage the following examples of today's cutting edge technologies: 
<a href="https://hubblenetwork.com/" target="_blank">Hubble Network<a/>, 
<a href="https://wirepas.com/" target="_blank">WirePas<a/>, and 
<a href="https://www.zephyrproject.org/" target="_blank">Zephyr RTOS<a/> enabling future solutions.    
Three file structures are necessary to upload at <a href ="https://jlcpcb.com/" target="_blank">JLCPCB.com<a/> for turn-key manufacturing: hardware/manufacturing/gerber/jlcpcb6lry/jlcpcb6lyr.zip, hardware/manufacturing/DRVjlc(2)_top_cpl.csv, and hardware/manufacturing/DRVjlc(2)_top_bom.csv. This would result in the following model of your new hardware: 
<a href ="/docs/images/jlcII.png" target="_blank">JLCPCB.com Model<a/><br />
**HARDWARE DESIGN:**
<br /><a href ="/docs/images/schem1.png" target="_blank">SchematicOne<a/><br />
<a href ="/docs/images/schem2.png" target="_blank">SchematicTwo<a/><br />
<a href ="/docs/images/board.png" target="_blank">Board<a/><br />
**TECHNOLOGIES:**<br />
GCT: <a href="https://gct.co/connector/usb4110"  target="_blank">USBC connector</a> <br />
OnSemi: <a href="https://www.onsemi.com/products/interfaces/usb-type-c/fusb302b" target="_blank">USBC Controller</a><br />
NordicSemiconductor: <a href="https://www.nordicsemi.com/Products/nRF52840" target="_blank">nRF52840</a> <br />
Texas Instrument: <a href="https://www.ti.com/product/DRV8316?keyMatch=DRV8316&tisearch=universal_search&usecase=GPN-ALT" target="_blank">DRV8316</a> <br />
TDK: <a href="https://product.tdk.com/en/search/sensor/mortion-inertial/imu/info?part_no=ICM-20948" target="_blank">ICM-20948</a><br />
Analog Devices: <a href="https://www.analog.com/en/products/lt8640.html" target="_blank">LT8640</a> <br />
**LICENSES:**<br />
OPEN