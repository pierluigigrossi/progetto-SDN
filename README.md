**Progetto 8. Blocco traffico anomalo**

Scrivere un programma che, da ogni host, generi traffico TCP iperf a intervalli casuali e con durate casuali verso altri host. Scrivere un programma Ryu che osservi i pacchetti SYN. Se una destinazione riceve più di X nuove connessioni nell’ultimo intervallo T la nuova connessione è bloccata. Siano X e T valori arbitrari.

[Presentazione intermedia condivisa](https://polimi365-my.sharepoint.com/:p:/g/personal/10169800_polimi_it/EaobnsC3-O9ArCa_GNBwLsgB0S-8JqHUxtt0P7-_12-jfQ?e=cplChJ)

Istruzioni esecuzione:
creeare la cartella progetto8 in sdn-lab di docker
copiare sotto creare una cartella sotto sdn-lab, montato in  docker e copiare i file:
```
 ryu.sh tcp.py topology.sh iperf.sh mesh-topology.py mininet_iperf.sh
```
entrare nella cartella da 3 terminali diversi:
```
cd sdn-lab/progetto8
```
Necessari 3 terminali

eseguire prima mininet con il comando:
```
./topology.sh
```
poi in un altro terminale  lanciare ryu con il comando
```
./ryu.sh
```
eseguire in mininet:
```
pingall
```
esguire lo script per iperf casuali iperf sui 4 host:

```
./mininet_iperf.sh
```