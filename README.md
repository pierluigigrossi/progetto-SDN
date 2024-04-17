**Progetto 8. Blocco traffico anomalo**

Scrivere un programma che, da ogni host, generi traffico TCP iperf a intervalli casuali e con durate casuali verso altri host. Scrivere un programma Ryu che osservi i pacchetti SYN. Se una destinazione riceve più di X nuove connessioni nell’ultimo intervallo T la nuova connessione è bloccata. Siano X e T valori arbitrari.

[Presentazione intermedia condivisa](https://polimi365-my.sharepoint.com/:p:/g/personal/10169800_polimi_it/EaobnsC3-O9ArCa_GNBwLsgB0S-8JqHUxtt0P7-_12-jfQ?e=cplChJ)

Istruzioni esecuzione:
copiare in una cartella di docker i file ryu.sh, tcp.py, topology.sh, iperf.sh,mesh-topology.py
aggiungere i permessi per esecuzione:
```
chmod +x ryu.sh topology.sh iperf.sh
```
eseguire prima mininet con il comando:
```
./topology.sh
```
poi in un'altra finestra ryu con il comando
```
./ryu.sh
```

esguire iperf sugli host, aprendo altri terminali (4) in contempornea con i comandi
dalla directory di docker in cui si è salvato iperf.sh:
```
/root/mininet/util/m h1 ./iperf.sh
/root/mininet/util/m h2 /path/to/iperf.sh
/root/mininet/util/m h2 /path/to/iperf.sh
```