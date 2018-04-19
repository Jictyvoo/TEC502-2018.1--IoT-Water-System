/* LQanalyze.c: get MAC for specified interface
*/
#include <stdio.h>              /* Standard I/O */
#include <stdlib.h>             /* Standard Library */
#include <errno.h>              /* Error number and related */
#include <string.h>


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
#include "lualib/lua.h"
#include "lualib/lauxlib.h"
#include "lualib/lualib.h"

/*This code was found in the internet, in some fórum, I don't remember the author, but credits to him*/
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


void findMac(char * argv[], char* returnedString){
    unsigned char  mac[IFHWADDRLEN];
    int i;
    get_local_hwaddr( argv[1], mac );
    char macPiece[IFHWADDRLEN][6];
    char completeMac[IFHWADDRLEN * 3];
    completeMac[0] = '\0';
    for( i = 0; i < IFHWADDRLEN; i++ ){
        ///*s*/printf(/*macPiece,*/ "%02X:", (unsigned int)(mac[i]) );
        snprintf(macPiece[i], sizeof(char*), "%02X:", (unsigned int)(mac[i]) );
        strcat(completeMac, macPiece[i]);
    }
    strcpy(returnedString, completeMac);
}

static int lua_findMac(lua_State *L){
    if(lua_gettop(L) >= 1){
        char* address[] = {"find","wlp3s0"};
        char macPiece[IFHWADDRLEN * 3];
        findMac(address, macPiece);
        macPiece[strlen(macPiece) - 1] = '\0';
        //printf("%s\n", macPiece);
        lua_pushstring (L, macPiece);
        return 1;
    }
}

static const struct luaL_Reg findMacFunc [] = {
  {"findMac", lua_findMac},
  {NULL,NULL}
};

int luaopen_util_macAdress(lua_State *L){
  luaL_newlib (L, findMacFunc);   /* register C functions with Lua */
  return 1;
}