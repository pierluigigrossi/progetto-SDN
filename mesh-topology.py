#! /usr/bin/python
# invocare con mn --custom mesh-topology.py --topo MeshTopo

from mininet.topo import Topo   #definire la topologia
# topologia full mesh s1-s4. un host per switch
class MeshTopo ( Topo ):

  def build(self):

    #Aggiungo nuovi host
    host1= self.addHost('h1')
    host2= self.addHost('h2')
    host3= self.addHost('h3')
    host4= self.addHost('h4')

    #Aggiungo nuovi switch
    switch1=self.addSwitch('s1')
    switch2=self.addSwitch('s2')
    switch3=self.addSwitch('s3')
    switch4=self.addSwitch('s4')

    #Aggiungo i link agli switch
    #switch1
    self.addLink(switch1,host1)
    self.addLink(switch1,switch2)
    self.addLink(switch1,switch3)
    self.addLink(switch1,switch4)

    #switch2
    self.addLink(switch2,host2)
    self.addLink(switch2,switch3)
    self.addLink(switch2,switch4)

    #switch3
    self.addLink(switch3,host3)
    self.addLink(switch3,switch4)

    #switch4
    self.addLink(switch4,host4)

topos = { 'MeshTopo' : ( lambda: MeshTopo() ) }
