/*****************
* Removes offline slave nodes
*
* NOTE: Some slaves can't be removed as the backing instance already is
* missing but the UI collection didn't get the update. See the
* slay_computer.groovy for a more drastic destruction
*
* NOTE 2: If you have any slaves you want to live through this and you
* have them currently marked offline you _must_ bring them back online.
*****************/

import hudson.model.*

def numberOfflineNodes = 0
def numberNodes = 0

slaveNodes = hudson.model.Hudson.instance

for (slave in slaveNodes.nodes) {
    def computer = slave.computer
    numberNodes ++
    println ""
    println "Checking computer ${computer.name}:"
    if (computer.offline) {
        numberOfflineNodes ++
        println '\tcomputer.isOffline: ' + slave.getComputer().isOffline()
        println '\tcomputer.offline: ' + computer.offline
        println '\tRemoving slave'
        slaveNodes.removeNode(slave)
    } else {
        println '\tcomputer.isOffline: ' + slave.getComputer().isOffline()
        println '\tcomputer.offline: ' + computer.offline
    }
}

println "Number of Offline Nodes: " + numberOfflineNodes
println "Number of Nodes: " + numberNodes

// vim: sw=4 sts=4 ts=4 et ai :
