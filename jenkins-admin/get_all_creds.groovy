/*****************
* Extracts all registered credentials and passwords
*
* Jenkins credentials are encrypted and passwords cannot be retrived easily.
* Run this script to get all credentials pairs in an "Id : Password" fortmat.
* Note: This script will not display information for SSH and Certificate
* credential type.
*
*****************/

import com.cloudbees.plugins.credentials.*

println "printing all the credentials and passwords..."
def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
   com.cloudbees.plugins.credentials.common.StandardUsernameCredentials.class,
   Jenkins.instance,
   null,
   null
);

for (c in creds) {
 try {
    println(c.id + " : " + c.password )
 } catch (MissingPropertyException) {}
}
