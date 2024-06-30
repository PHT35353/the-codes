#For this code the torque of a delta configured induction machine needed to be calculated and plotted from the different measured values.
#This code graphs the results using matplotlib library

import numpy as np
import matplotlib.pyplot as plt

#The motor speed (rpm) in different measurements  
n = [1461.07, 1468.66, 1476.74, 1485.84, 1493.43, 1502.02, 1506.57, 1516.68, 1524.27, 1531.85, 1536.91] 
n_array= np.array(n)

#The real power (W) in different measurements
p=[2145, 1821, 1460, 1072, 780, 403, -230, -379, -703, -943, -1219]
p_array= np.array(p)

#the line to line source voltage
V=400

#the apparent power (VA) in different measurements 
S=[3132, 2933, 2756, 2566, 2456, 2517, 2371, 2486, 2667, 2884, 3125]
S_array= np.array(S)

#The line to line current (A) in different measurments
IL= [3.43, 3.33, 3.21, 3.07, 2.92, 2.93, 2.87, 2.88, 2.94, 2.98, 3.13]
IL_array= np.array(IL)

#The phase current (A) that because it is calculated in a delta configured induction machine is devided by sqrt(3)
Is=IL_array/np.sqrt(3)

#The measured stator resistance (ohm)
rs= 9.020

"""the angular speed (rad/s) which because the given frequency was given as 50Hz it is calculated as 50*2*pi. this was then devided the by the 2 pole pairs which gave 50pi as 
the angular frequency"""
Ws= 50*np.pi
# In order to calculated the torque the airgap power (W) is needed. The formula below shows that the airgap power can be calculated from the above values.
pag=p_array-3*np.absolute(Is)**2*rs
#The formula of torque(Nm) which is the airgap power devided by the angular speed.
T=pag/Ws
print("T", T)

# Plot torque-speed characteristic
plt.figure(figsize=(10, 6))
plt.plot(n, T)
plt.title('Torque-Speed Characteristic of an Induction Motor')
plt.xlabel('Rotor Speed (RPM)')
plt.ylabel('Torque (Nm)')
plt.grid(True)
plt.xlim([1400, 1600])
plt.show()