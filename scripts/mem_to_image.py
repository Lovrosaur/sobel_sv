import numpy as np
from matplotlib import pyplot as plt

file = open("actual_gradients.mem")
w = int(input("image width:"))-2
h = int(input("image height:"))-2

arr = np.array(list(map(lambda x: (int(x,16) if x!="xx\n" else 0),file.readlines()))[:w*h]).reshape((w,h))
plt.imshow(arr,"gray")
plt.show()