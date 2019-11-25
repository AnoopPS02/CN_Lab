set stop 100;

set type gsm;

set minth 30
set maxth 0
set adaptive 1;

set flows 0;
set window 30;

set opt(wrap) 100;
set opt(srcTrace) is;
set opt(dstTrace) bs2;
set bwDL(gsm) 9600
set propDL(gsm).500

set ns [new Simulator]
set tf [open out.tr w]
$ns trace-all $tf

set nodes(is)[$ns node]
set nodes(ms)[$ns node]
set nodes(bs1)[$ns node]
set nodes(bs2)[$ns node]
set nodes(1p)[$ns node]

proc cell_topo {} {
global ns nodes
$ns duplex-link $nodes(1p) $nodes(bs1) 3Mbps 10ms DropTail
$ns duplex-link $nodes(bs1) $nodes(ms) 1 1 RED
$ns duplex-link $nodes(bs1) $nodes(bs2) 1 1 RED
$ns duplex-link $nodes(bs2) $nodes(is) 3Mbps 50ms DropTail
puts "GSM cell toplogy"
}

proc set_link_params {t} {
global ns nodes bwDL propDL
$ns bandwidth $nodes(bs1) $nodes(ms) $bwDL($t) duplex
$ns bandwidth $nodes(bs2) $nodes(ms) $bwDL($t) duplex

$ns delay $nodes(bs1) $nodes(ms) $propDL($t) duplex
$ns delay $nodes(bs2) $nodes(ms) $propDL($t) duplex

$ns queue_limit $nodes(bs1) $nodes(ms) 10
$ns queue_limit $nodes(bs2) $nodes(ms) 10
}

Queue/RED set adaptive_$adaptive
Queue/RED set thresh_$minth
Queue/RED set maxthresh_$maxth
Queue/RED set window_$window

source web.tcl

switch $type{
gsm-
cdma{cell_topo}
}

set_link_params $type
$ns insert-delayer $nodes(ms) $nodes(bs1) [new Delayer]
$ns insert-delayer $nodes(ms) $nodes(bs2) [new Delayer]

if{$flows==0} {
set tcp1[$ns create_connection TCP/sack1 $node(is) TCP Sink/Sink1 $nodes(1p) 0]
set ftp[[set tcp1] attach-app FTP]
$ns at 0.8 "[set ftp1] start"
}

proc stop {} {
global nodes opt tf
set wrap $opt(wrap)
set sid [$nodes($opt(src-Trace))id]
set did [$nodes($opt(dst_Trace))id]

set a "out.tr"

set GETRC "../../../bin.getrc"
set RAW2XG "../../../bin/raw2xg"

exec $GETRC -s $sid -d $did -f 0  out.tr | \
$RAW2XG -s 0.01 -m $wrap -r > plot.xgr

exec $GETRC -s $sid -d $did -f 0  out.tr | \
$RAW2XG -s 0.01 -m $wrap -r >> plot.xgr

exec xgraph -x time -y packets plot.xgr &
exit 0
}

$ns at $stop "stop"
$ns run
