/* LQanalyze.c: get MAC for specified interface
*/
#include <stdio.h>              /* Standard I/O */
#include <stdlib.h>             /* Standard Library */
#include <errno.h>              /* Error number and related */


#define ENUMS
#include <sys/socket.h>
#include <net/route.h>
#include <net/if.h>
#include <features.h>           /* for the glibc version number */
#if __GLIBC__ >= 2 && __GLIBC_MINOR >= 1
#include <netpacket/packet.h>
#include <net/ethernet.h>       /* the L2 protocols */
#else
#include <asm/types.h>
#include <linux/if_packet.h>
#include <linux/if_ether.h>     /* The L2 protocols */
#endif
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/un.h>
#include <sys/ioctl.h>
#include <netdb.h>

/*include lua library*/
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

int get_local_hwaddr(const char *ifname, unsigned char *mac)
{
    struct ifreq ifr;
    int fd;
    int rv;                     // return value - error value from df or ioctl call

    /* determine the local MAC address */
    strcpy(ifr.ifr_name, ifname);
    fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    if (fd < 0)
        rv = fd;
    else {
        rv = ioctl(fd, SIOCGIFHWADDR, &ifr);
        if (rv >= 0)            /* worked okay */
            memcpy(mac, ifr.ifr_hwaddr.sa_data, IFHWADDRLEN);
    }

    return rv;
}


void findMac(char * argv[] ){

unsigned char  mac[IFHWADDRLEN];
int i;
    get_local_hwaddr( argv[1], mac );
    for( i = 0; i < IFHWADDRLEN; i++ ){
        printf( "%02X:", (unsigned int)(mac[i]) );
    }

}

int main(int argc, char * argv[]) {

    lua_State * L;
    lua_open(L);
    /* Bind the C functions to Lua functions */
    luaL_Reg func[] = {
        {"findMac", findMac},
        {NULL, NULL}
    };
    luaL_setfuncs(L, &func, 0);
    /* execute script from stdin */
    int res = luaL_dofile(L, NULL);
    //findMac(argv);
    return 0;
}