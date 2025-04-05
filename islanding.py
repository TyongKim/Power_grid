import numpy as np
import matlab
import time

def test_islanding(branches, buslist):
    buslist = buslist.tolist()
    foundbuses = []
    islands = []
    if branches.size == 0:
        for bus1 in buslist:
            islands.append([bus1])
        return islands
    if np.ndim(branches) == 1:
        islands.append([branches[0], branches[1]])
        for bus in buslist:
            if bus not in islands[0]:
                islands.append([bus])
        return islands
    for bus1 in buslist:
        if bus1 in foundbuses:
            continue
        else:
            curiter = [bus1]
            island = [bus1]
            foundbuses.append(bus1)
            while True:
                nextiter = []
                for bus in curiter:
                    adjbranches1 = branches[np.where(branches[:,0]==bus)] #find all branches in branches where the target bus appears in index 0
                    for branch in adjbranches1:
                        if (branch[1] not in nextiter) and (branch[1] not in foundbuses):
                            nextiter.append(branch[1])
                        #index = np.where([np.array_equal(sublist, branch) for sublist in branches])[0][0] #find the index of branch in branches
                        #branches = np.delete(branches, index, 0) #remove branch from branches, axis is 0
                    adjbranches2 = branches[np.where(branches[:,1]==bus)] #find all branches in branches where the target bus appears in index 1
                    for branch in adjbranches2:
                        if (branch[0] not in nextiter) and (branch[0] not in foundbuses):
                            nextiter.append(branch[0])
                        #index = np.where([np.array_equal(sublist, branch) for sublist in branches])[0][0]
                        #branches = np.delete(branches, index, 0)
                if nextiter == []:
                    islands.append(island)
                    break
                curiter = nextiter
                island.extend(curiter)
                foundbuses.extend(curiter)
    return islands
                

            




#branches = np.array([[1,4],[4,5], [5,6], [3,6], [6,7], [9,4]])
# buslist = np.array([1,2,3,4,5,6,7,9])


#buslist = np.array([1,2,3,4,5,6,7])
#branches = np.array([[1,4], [5,1], [4,6], [6, 5], [2, 7], [3, 7], [3, 2]])


#print(test_islanding(branches, buslist))

