#!/usr/bin/perl -w
#
# nathelper - Masquerading und Port-Forwarding in einer Kommandozeile
#             benoetigt natuerlich iptables
#
# Autor: otzenpunk (UbuntuUsers.de)
# Lizenz: Public Domain

use strict;
use Getopt::Std;

our %opts;
usage() unless @ARGV;
getopts('qvdhmi:', \%opts);
usage() if $opts{'h'} or !$opts{'i'};

init();                             # ip_forward, iptables -F

masq($opts{'i'}) if ($opts{'m'});   # evtl. Masquerading

our @forwards;
our $fw_indx = 0;
while ($_ = shift @ARGV) {          # Array of Arrays: je 1xIP und n x Ports
  ++$fw_indx if /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && @forwards;
  push @{$forwards[$fw_indx]}, $_;
}

forw($_) for @forwards;             # jede IP verarbeiten

print "NAT erfolgreich aktiviert.\n" unless $opts{'q'} or $opts{'d'};
exit(0);

# masq(iface): Masquerading

sub masq {
  my @iptables = (qw(/sbin/iptables -t nat -A POSTROUTING -o), $opts{'i'}, qw(-j MASQUERADE));
  iptables(@iptables);
}

# forw(IP, Ports, ...): Ports duerfen Aufzaehlungen  (zahl,zahl)
#                                     Ranges         (zahl-zahl)
#                                 und Uebersetzungen (zahl:zahl) enthalten.

sub forw {
  my $argptr = shift;               # Pointer auf Array
  my $ip = shift @$argptr;          # Erstes Element = IP
  for (@$argptr) {
    s/[^0-9u:,-]//ig;               # saeubern von verbotenen Zeichen
    my $proto = s/^u//i ? 'udp' : 'tcp';   # u = UDP
    my ($von, $nach) = split ':';   # Uebersetzung trennen
    $nach ||= $von;                 # wenn kein ':' -> Ports bleiben gleich
    my @von = expand_range($von);   # ',' und '-' expandieren
    my @nach = expand_range($nach);
    unless (@von == @nach) {        # Falsche Parameter abfangen:
      print "Ungleiche Anzahl Ports: ", join(', ', @von), ' -> ', join(', ', @nach), "\n\n";
      usage();
    }
    my $i = 0;
    for (@von) {                    # je eine iptables-Zeile pro Port
      my @iptables = (qw(/sbin/iptables -t nat -A PREROUTING -i), $opts{'i'},
		      '-p', $proto, '--dport', $_,
		      qw(-j DNAT --to-destination), "$ip:$nach[$i++]");
      iptables(@iptables);
    }
  }
}

# iptables(Liste der Argumente, inkl. iptables-Pfad)

sub iptables {            # system() gibt >0 bei Fehler
  print join(' ', @_), "\n" if $opts{'v'} or $opts{'d'};
  system(@_) && die("Fehler bei iptables. Root?\n") unless ($opts{'d'});
}

# expand_range(Port-String inkl. [,-])
#             ',' und '-' expandieren und Liste zurueck

sub expand_range {
  my @werte = split ',', shift;
  @werte = map {
    my ($down, $up) = split '-', $_;
    $down < ($up ||= 0) ? ($down..$up) : $down;
  } @werte;
  return @werte;
}

sub init {
  print "sysctl -w net/ipv4/ip_forward=1\n" if $opts{'v'} or $opts{'d'};
  system(qw(sysctl -w net/ipv4/ip_forward=1)) if not $opts{'d'};
  iptables(qw(/sbin/iptables -t nat -F));
}

sub usage {
  print <<EOT;
Usage: $0 [-v] [-d] -i iface [-m] [ip ports ...] ...
       $0 [-h]

-h : Hilfe
-v : Verbose, iptables-Befehle ausgeben und durchfuehren
-d : Debug, nicht wirklich durchfuehren
-q : Keine Erfolgsmeldung ausgeben
-i : externes Interface
-m : Masquerading aktivieren

ip ports : Ports, die auf IP umgeleitet werden, mehrere moeglich
ports : 1234 -> Port wird 1:1 umgeleitet
        1234:5678 -> Port wird auf anderen Port umgeleitet
        1234-1238 -> Port-Range wird umgeleitet
        1234-1238:5674-5678 -> beides
        u1234 -> UDP-Port(s) verwenden
EOT
  exit(1);
}
