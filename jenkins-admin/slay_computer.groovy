/*****************
* Completely slays misbehaving slave nodes
*
* NOTE: Use del_computer.groovy first! If nodes are still hanging around
* _then_ consider using this script. This one is mucking around in a
* location we should not normally be touching, however if a slave
* refuses to go away (tosses an exception) this _will_ get rid of it.
*
* NOTE 2: If you have any slaves you want to live through this and you
* have them currently marked offline you _must_ bring them back online.
*****************/

import jenkins.*
import jenkins.model.*
import hudson.*
import hudson.model.*

for (aComputer in Jenkins.instance.computers) {
    try {
        println "displayName: " + aComputer.properties.displayName
        println "offline: " + aComputer.properties.offline
        println "temporarilyOffline: " + aComputer.properties.temporarilyOffline
        if (aComputer.properties.offline) {
            println "Bad node, removing"
            Jenkins.instance.removeComputer(aComputer)
        }
        println ""
    }
    catch (NullPointerException nullPointer) {
        println "NullPointerException caught"
        println ""
    }
}

// vim: sw=4 sts=4 ts=4 et ai :
