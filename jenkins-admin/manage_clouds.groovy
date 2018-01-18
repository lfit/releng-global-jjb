import jenkins.plugins.openstack.compute.JCloudsCloud
import jenkins.plugins.openstack.compute.JCloudsSlaveTemplate
import jenkins.plugins.openstack.compute.SlaveOptions
import jenkins.plugins.openstack.compute.slaveopts.BootSource
import jenkins.plugins.openstack.compute.slaveopts.LauncherFactory



def bs = new BootSource.Image("Image")
def hardwareId = "hardwareId"
def networkId = "networkId"
def userDataId = "userDataId"
def instanceCap = 10
def floatingIpPool = ""
def securityGroups = "Default"
def availabilityZone = "cmyk"
def startTimeout = 100000
def keyPairName = "jenkins"
def numExecutors = 1
def jvmOptions = ""
def fsRoot = "/w"
def launcherFactory = new LauncherFactory.SSH("id", "path")
def retentionTIme = 1

slaveOptions = new SlaveOptions(
    bs, 
    hardwareId,
    networkId,
    userDataId,
    instanceCap,
    floatingIpPool,
    securityGroups,
    availabilityZone,
    startTimeout,
    keyPairName,
    numExecutors,
    jvmOptions,
    fsRoot,
    launcherFactory,
    retentionTIme
)

def templateName = "steve"
def label = "a-label"

template = new JCloudsSlaveTemplate(
    templateName,
    label,
    slaveOptions
)

def cloudName = "cloud"
def endPointUrl = "https://endpoint.com"
def ignoreSsl = false
def zone = "zone"
templates = Collections.singletonList(template)
def credId = "cred"

cloud = new JCloudsCloud("a", "b", "a", "d", "d", slaveOptions, [template])

def clouds = Jenkins.instance.clouds
clouds.replace(cloud)
