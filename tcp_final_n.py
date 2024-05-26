# Implementazione openflow di hop-by-hop routing
# usando la mappa della rete trovata con topology discovery
#
# Si richiede l'uso del topology discovery
# ryu-manager --observe-links
#

from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import set_ev_cls, CONFIG_DISPATCHER, MAIN_DISPATCHER, DEAD_DISPATCHER
from ryu.ofproto import ofproto_v1_3
from ryu.topology import event, switches
from ryu.topology.api import get_all_switch, get_all_link, get_all_host,get_switch
from ryu.lib.packet import packet, ethernet, ether_types, arp, tcp,ipv4
from collections import defaultdict
import networkx as nx
import time
import csv 
import sys

#costanti da impostare 
X = 3 #numero connessioni TCP
T = 10 #in intervallo di tempo
reset = True #manda RST/ACK
reroute= True #resileinte a guasti
approx = False #conteggio approssimato
report = True #salva csv
report_file='ryu_tcp.csv'


#struttura dati per salvare destinazioni dei SYN
d = defaultdict(list)
#controllo valori soglie
if X < 0 or T < 0 :
    print ('Valori T o X non validi')
    sys.exit(1)

if report is True :
    header = ['Accepted or not','timestamp','IP_SRC', 'IP_DST', 'PORT_SRC', 'PORT_DST']
    with open(report_file, 'a', encoding='UTF8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
    f.close()

class HopByHopSwitch(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]
    # alla regitrazione di uno switch nella rete 
    # tutti i pacchetti al controllore
    # priorità più alta per IPv4 TCP
    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [
            parser.OFPInstructionActions(
                ofproto.OFPIT_APPLY_ACTIONS,
                [
                    parser.OFPActionOutput(ofproto.OFPP_CONTROLLER,
                                           ofproto.OFPCML_NO_BUFFER)
                ]
            )
        ]
        mod = parser.OFPFlowMod(
            datapath=datapath,
            priority=0,
            match = parser.OFPMatch(),
            instructions=inst
        )
        datapath.send_msg(mod)
        #tutti i TCP IPv4 al controllore
        match = parser.OFPMatch(
            eth_type=0x0800,     #ipv4   
            ip_proto=6,          #tcp
        )
        #Regola di match con priorità più alta 
        mod = parser.OFPFlowMod(
            datapath=datapath,
            priority=20,
            match = match,
            instructions=inst
        )
        datapath.send_msg(mod)

    # il controllore trova switch destinazione e porta dello switch
    def find_destination_switch(self,destination_mac):
        for host in get_all_host(self):
            if host.mac == destination_mac:
                return (host.port.dpid, host.port.port_no)
        return (None,None)
    #Calcolo dei cammini minimi
    def find_next_hop_to_destination(self,source_id,destination_id):
        net = nx.DiGraph()
        for link in get_all_link(self):
            net.add_edge(link.src.dpid, link.dst.dpid, port=link.src.port_no)

        path = nx.shortest_path(
            net,
            source_id,
            destination_id
        )

        first_link = net[ path[0] ][ path[1] ]

        return first_link['port']
    
    # eseguo quando arriva packet-in, uno switch manda un pacchetto al controllore
    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    
    def _packet_in_handler(self, ev):

        msg = ev.msg
        datapath = msg.datapath     #numero dello switch da cui arriva il pacchetto
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)

        # se ARP esegui proxy arp, l'host non conosce mac della dst, gli viene comunicato da controller 
        if eth.ethertype == ether_types.ETH_TYPE_ARP:
            self.proxy_arp(msg)
            return

        # ignora pacchetti non IPv4 (es. ARP, LLDP)
        if eth.ethertype != ether_types.ETH_TYPE_IP:
            return
        
        destination_mac = eth.dst
        source_mac = eth.src

        # trova switch destinazione
        (dst_dpid, dst_port) = self.find_destination_switch(destination_mac)
        # trova switch sorgente
        (src_dpid, src_port) = self.find_destination_switch(source_mac)

        # host non trovato
        if dst_dpid is None:
            #print "DP: ", datapath.id, "Host not found: ", pkt_ip.dst
            return

        if dst_dpid == datapath.id:
            # da usare se l'host e' direttamente collegato
            output_port = dst_port    
        else:
            # host non direttamente collegato
            output_port = self.find_next_hop_to_destination(datapath.id,dst_dpid)

        # print "DP: ", datapath.id, "Host: ", pkt_ip.dst, "Port: ", output_port
        pkt_ipv4 = pkt.get_protocol(ipv4.ipv4)
        pkt_tcp = pkt.get_protocol(tcp.tcp)
        #elaborazione pacchetto TCP
        if pkt_tcp is not None:
            #X =3 T=10 blocco successivo, se ricevo più di 3 SYN in 10 s
            #il primo pacchetto è per forza un syn, perchè tutto il resto viene inoltrato direttamente 
            #elaborazione sullo switch dove è connesso direttamente host  sorgente, serve per contare una sola volta
            if pkt_tcp.has_flags(tcp.TCP_SYN) and (not pkt_tcp.has_flags(tcp.TCP_ACK)) and src_dpid == datapath.id :
                #tempo arrivo TCP SYN
                t = time.time()
                #soluzione apporssimata
                if approx is True :
                   # se primo SYN per una destinazione: 
                    if destination_mac not in d :
                        # formato array [numero_syn,last_syn]
                        d[destination_mac] =[1,t]
                    else :
                        d[destination_mac][0] = d[destination_mac][0]+1
                    #calcolo delta come differenza tra tempo syn attuale e primo SYN
                    delta_t = t-d[destination_mac][1]
                    #reset (come fosse primo SYN), oltre la soglia 
                    if delta_t > T :
                        d[destination_mac] =[1,t]
                    #salvo
                    i = d[destination_mac][0]
                    #stampo 
                    print(pkt_ipv4.dst,':',pkt_tcp.dst_port,'Elapsed time:',delta_t)
                #soluzione esatta
                else :
                    #riconto ad ogni SYN tutto il delta
                    i = 1
                    delta_t = 0
                    #array di timestamp per il dato mac
                    d[destination_mac].append(t) 
                    l = len(d[destination_mac])
                    #loop di conteggio SYN, almeno 2, dentro le soglie.
                    #Mi fermo al primo sopra soglia 
                    while l >= 2 and delta_t < T and i <= X :
                        delta_t = delta_t + d[destination_mac][l-1]-d[destination_mac][l-2]
                        l = l-1
                        i = i+1
                    # i = SYN ricevuti in un periodo di tempo delta_t
                    #tieni nel dizionario solo SYN nell'intervallo di tempo di osservazione 0-T e in soglia
                    while  l >= 1  and ( i > X or delta_t > T ) :
                        del d[destination_mac][l-1]
                        l = l-1
                    print(pkt_ipv4.dst,':',pkt_tcp.dst_port,'Elapsed time:',delta_t)
                    #scarta pacchetto oltre soglia, più di X SYN in tempo minore di T
                if i > X  and delta_t <= T:
                    if report is True :
                        with open(report_file, 'a', encoding='UTF8', newline='') as f:
                            writer = csv.writer(f)
                            writer.writerow(['X',time.ctime(t),pkt_ipv4.src, pkt_ipv4.dst, pkt_tcp.src_port, pkt_tcp.dst_port])
                        f.close()
                    print('KO at least', i, 'SYNs in', delta_t,'\n',)
                    if reset is True :
                        #creazione pacchetto RESET ACK
                        pkt_rst = packet.Packet()
                        eth_rst = ethernet.ethernet(
                        dst = source_mac,
                        src = destination_mac,
                        ethertype = 0x0800 #IPv4 
                        )
                        ip_rst = ipv4.ipv4(
                            src=pkt_ipv4.dst,
                            dst=pkt_ipv4.src ,
                            proto=6  # TCP 
                        )
                        tcp_rst = tcp.tcp(
                            src_port=pkt_tcp.dst_port,
                            dst_port=pkt_tcp.src_port,
                            bits=0x014,  # RST/ACK flag
                            seq=pkt_tcp.ack,
                            ack=pkt_tcp.seq +1
                        )
                        pkt_rst.add_protocol(eth_rst)
                        pkt_rst.add_protocol(ip_rst)
                        pkt_rst.add_protocol(tcp_rst)
                        pkt_rst.serialize()
                        print("RST")
                        #inoltro direttto sullo switch dove è connesso host dst
                        out = parser.OFPPacketOut(
                            datapath=datapath,
                            buffer_id=ofproto.OFP_NO_BUFFER,
                            in_port=ofproto.OFPP_CONTROLLER,
                            actions=[parser.OFPActionOutput(in_port)],
                            data=pkt_rst.data
                        )
                        datapath.send_msg(out)
                    #fine
                    return
                #se non ho ritornato prima il  TCP SYN è da inoltrare
                print('OK')
                if report is True :
                    with open(report_file, 'a', encoding='UTF8', newline='') as f:
                        writer = csv.writer(f)
                        writer.writerow(['A',time.ctime(t),pkt_ipv4.src, pkt_ipv4.dst, pkt_tcp.src_port, pkt_tcp.dst_port])
                        f.close()
            #installo regola per flusso TCP per instradamento diretto se sono sulla sorgente
            #non voglio avere altre packet in per quel flusso      
            if datapath.id == src_dpid:
                match = parser.OFPMatch(
                    eth_dst=destination_mac, 
                    eth_src=source_mac,
                    eth_type=0x0800, #ipv4
                    ipv4_src=pkt_ipv4.src,
                    ipv4_dst=pkt_ipv4.dst,        
                    ip_proto=6,          #tcp
                    tcp_dst=pkt_tcp.dst_port,
                    tcp_src=pkt_tcp.src_port
                )
                inst = [
                        parser.OFPInstructionActions(
                        ofproto.OFPIT_APPLY_ACTIONS,
                        [ parser.OFPActionOutput(output_port) ]
                        )
                ]
                mod = parser.OFPFlowMod(
                    datapath=datapath,
                    priority=30,
                    match = match,
                    instructions=inst,
                    idle_timeout=5
                    )
                datapath.send_msg(mod)
        #trattamento generico per qualsiasi pacchetto:
        
        # inoltra il pacchetto corrente & learning hop by hop 
        actions = [ parser.OFPActionOutput(output_port) ]
        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=in_port,
            actions=actions,
            data=msg.data
        )
        datapath.send_msg(out)

        # aggiungi la regola per instradare direttamente i prossimi
        match = parser.OFPMatch(
            eth_dst=destination_mac
            )
        inst = [
            parser.OFPInstructionActions(
                ofproto.OFPIT_APPLY_ACTIONS,
                [ parser.OFPActionOutput(output_port) ]
            )
        ]
        #Solo se l'host sorgente non è direttamente connesso allo switch  
        #scavalco le regole che mi mandano tutto il traffico TCP al controllore
        #faccio inoltro diretto
        if datapath.id != src_dpid:
            priority = 40
        else :
            priority = 10
        
        mod = parser.OFPFlowMod(
            datapath=datapath,
            cookie=1,
            priority=priority,
            match=match,
            instructions=inst,
            buffer_id=msg.buffer_id
        )
        datapath.send_msg(mod)

        return
    if reroute:
        @set_ev_cls( ofp_event.EventOFPPortStatus, MAIN_DISPATCHER)
        def port_status_handler(self, ev):
            msg = ev.msg
            datapath = msg.datapath
            ofproto = datapath.ofproto
            self.logger.info("Port status change")
            self.clean_all_flows()
            return
        def clean_all_flows(self):
            switch_list = get_switch(self, None)
            for switch in switch_list:
                datapath = switch.dp
                self.clean_flows(datapath)

        def clean_flows(self, datapath):
            ofproto = datapath.ofproto
            parser = datapath.ofproto_parser

            # Cancella flow entries con cookie 1
            mod = parser.OFPFlowMod(
                datapath=datapath,
                command=ofproto.OFPFC_DELETE,
                out_port=ofproto.OFPP_ANY,
                out_group=ofproto.OFPG_ANY,
                cookie=1,
                cookie_mask=0xFFFFFFFFFFFFFFFF
            )
            datapath.send_msg(mod)    
    
    def proxy_arp(self, msg):
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        pkt_in = packet.Packet(msg.data)
        eth_in = pkt_in.get_protocol(ethernet.ethernet)
        arp_in = pkt_in.get_protocol(arp.arp)

        # gestiamo solo i pacchetti ARP REQUEST
        if arp_in.opcode != arp.ARP_REQUEST:
            return

        destination_host_mac = None

        for host in get_all_host(self):
            if arp_in.dst_ip in host.ipv4:
                destination_host_mac = host.mac
                break

        # host non trovato
        if destination_host_mac is None:
            return

        pkt_out = packet.Packet()
        eth_out = ethernet.ethernet(
            dst = eth_in.src,
            src = destination_host_mac,
            ethertype = ether_types.ETH_TYPE_ARP
        )
        arp_out = arp.arp(
            opcode  = arp.ARP_REPLY,
            src_mac = destination_host_mac,
            src_ip  = arp_in.dst_ip,
            dst_mac = arp_in.src_mac,
            dst_ip  = arp_in.src_ip
        )
        pkt_out.add_protocol(eth_out)
        pkt_out.add_protocol(arp_out)
        pkt_out.serialize()

        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=ofproto.OFP_NO_BUFFER,
            in_port=ofproto.OFPP_CONTROLLER,
            actions=[parser.OFPActionOutput(in_port)],
            data=pkt_out.data
        )
        datapath.send_msg(out)
        return