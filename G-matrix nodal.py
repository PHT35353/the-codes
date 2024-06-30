"""This python code is to calculate the node voltages in a circuit using nodal analysis. Because it is a lot of calculations involving numerous linear algebra and diffrential equations this python code was used to calculate the node voltages."""




import numpy as np
#the conductance matrix
"""G=[Gs0+G01+G02+G03 -G01 -G02 -G03]
     [-G01 Gs1+G01+G12+G13 -G12 -G13]
     [-G02 -G12 G02+G12 0]
     [-G03 -G13 0 G03+G13]"""
#  node voltage matrix
"""V=[V0]
     [V1]
     [V2]
     [V3]"""
# current matrix
"""I=[V*s0/Rs0]
     [V*s1/Rs1]
     [0]
     [I_ld]"""
 #the code to generate current matrix
def make_I(n, ld, gen, I_ld, Vs, Rs):
    I = np.zeros((n, 1))
    I[gen] = Vs[gen] / Rs[gen]
    I[ld] = I_ld
    return I

# the code to generate the conductance  matrix
def make_G(n, gen, lines, Gp):
    G = np.zeros((n, n))
    for source in gen:
        G[source, source] += Gp[source][0]
    for branch in lines:
        i, j = branch
        G[i, i] += Gp[i][0]
        G[j, j] += Gp[j][0]
        G[i, j] -= Gp[i][0]
        G[j, i] -= Gp[j][0]
    return G

# the code to find the node voltages
def find_node_voltages(n, m, ld, gen, lines, Gp, I_ld, Vs, Rs):
    G_matrix = make_G(n, gen, lines, Gp)
    I_matrix = make_I(n, ld, gen, I_ld, Vs, Rs)
    inv_G = np.linalg.inv(G_matrix)
    V = np.dot(inv_G, I_matrix)
    return V

# the code for generating circuit
def make_random_circuit(sn):
    np.random.seed(sn)
    n = 10
    m = 14
    ni = 4
    nv = 2
    Gpmin = 0.1
    Gpmax = 0.5
    I_ldmin = 1
    I_ldmax = 25
    Vsmin = 100
    Vsmax = 400
    Rsmin = 1
    Rsmax = 9

    Gp = Gpmin + (Gpmax - Gpmin) * np.random.rand(m, 1)
    s = np.random.permutation(n)
    ld = s[0:ni]
    gen = s[ni:ni + nv]
    I_ld = I_ldmin + (I_ldmax - I_ldmin) * np.random.rand(ni, 1)
    Vs = Vsmin + (Vsmax - Vsmin) * np.random.rand(nv, 1)
    Rs = Rsmin + (Rsmax - Rsmin) * np.random.rand(nv, 1)

    all_lines = []
    for i in range(n):
        for j in range(i + 1, n):
            all_lines.append([i, j])
    np.random.shuffle(all_lines)
    lines = np.asarray(all_lines[:m])

    return n, m, ld, gen, lines, Gp, I_ld, Vs, Rs

# The values
sn = 40
n, m, ld, gen, lines, Gp, I_ld, Vs, Rs = make_random_circuit(sn)

# Calibrating  Vs and Rs to match the indices in gen
Vs_full = np.zeros((n, 1))
Rs_full = np.zeros((n, 1))
Vs_full[gen] = Vs
Rs_full[gen] = Rs

# Find node voltages
V = find_node_voltages(n, m, ld, gen, lines, Gp, I_ld, Vs_full, Rs_full)
print(V)
