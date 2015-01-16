package br.pucminas.icei;
import java.util.*;
import java.net.*;

public class TracedExampleClass {

    public static void main( String[] args ) throws Exception {
        Enumeration<NetworkInterface> nics = NetworkInterface.getNetworkInterfaces();
        while (nics.hasMoreElements()) {
            NetworkInterface nic = nics.nextElement();
            if (nic.isUp() && !nic.isVirtual()) {
                Enumeration<InetAddress> addrs = nic.getInetAddresses();
                while (addrs.hasMoreElements()) {
                    InetAddress addr = addrs.nextElement();

                    // Currently, seems there's a bug on Linux that one is
                    // unable to get IPv6 datagrams to be received by an
                    // IPv6 socket bound to any address except ::1. So filter
                    // out IPv6 address here. The test should be revisited
                    // later when aforementioned bug gets fixed.
                    if (addr instanceof Inet4Address) {
                        System.out.printf("%s : %s\n", nic.getName(), addr);
                        testConnectedUDP(addr);
                    }
                }
            }
        }
    }


    /*r
     * Connect a UDP socket, disconnect it, then send and recv on it.
     * It will fail on Linux if we don't silently bind(2) again at the
     * end of DatagramSocket.disconnect().
     */
    private static void testConnectedUDP(InetAddress addr) throws Exception {
        try {
            DatagramSocket s = new DatagramSocket(0, addr);
            DatagramSocket ss = new DatagramSocket(0, addr);
            System.out.print("\tconnect...");
            s.connect(ss.getLocalAddress(), ss.getLocalPort());
            System.out.print("disconnect...");
            s.disconnect();

            byte[] data = { 0, 1, 2 };
            DatagramPacket p = new DatagramPacket(data, data.length,
                    s.getLocalAddress(), s.getLocalPort());
            s.setSoTimeout( 10000 );
            System.out.print("send...");
            s.send( p );
            System.out.print("recv...");
            s.receive( p );
            System.out.println("OK");

            ss.close();
            s.close();
        } catch( Exception e ){
            e.printStackTrace();
            throw e;
        }
    }

}
