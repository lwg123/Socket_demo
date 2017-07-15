# Socket_demo
socket基本使用  

###1、TCP/IP
TCP/IP就是传输控制协议/网间协议，网络层的“ip地址”可以唯一标识网络中的主机，而传输层的“协议+端口”可以唯一标识主机中的应用程序（进程）  
下面说一下IP地址和端口号
####IP地址
IP地址用于唯一标识网络中的一个通信实体，这个通信实体既可以是一台主机，也可以是一台打印机，或者是路由器的某一个端口。在基于IP协议的网络中传输的数据包，都必须使用IP地址在进行标识。IP地址用于唯一标识网络上的一个通信实体，但一个通信实体可以有多个通信程序同时提供网络服务，此时还需要使用端口。
#### 端口  
端口是一个16位的整数，用于表示数据交给哪个通信程序处理。一次端口就是应用程序与外界交流的出入口，它是一种抽象的软件结构，包括一些数据结构I/O(基本输入输出)缓冲区。不同的应用程序处理不同端口上的数据，同一台机器上不能有两个程序使用同一个端口，端口号从0到65535。  
TCP/IP协议参考模型把所有的TCP/IP系列协议归类到四个抽象层中，  
应用层：TFTP，HTTP，SNMP，FTP，SMTP，DNS，Telnet 等等  
传输层：TCP，UDP  
网络层：IP，ICMP，OSPF，EIGRP，IGMP  
数据链路层：SLIP，CSLIP，PPP，MTU
![](http://oqfs0y2cu.bkt.clouddn.com/17-7-14/40970466.jpg)

###2、Socket
利用ip地址＋协议＋端口号唯一标示网络中的一个进程，就可以利用socket进行通信了，我们经常把socket翻译为套接字，socket是在应用层和传输层之间的一个抽象层，它把TCP/IP层复杂的操作抽象为几个简单的接口供应用层调用以实现进程在网络中通信。
![](http://oqfs0y2cu.bkt.clouddn.com/17-7-14/31112059.jpg)

####socket通信流程
socket是"打开—读/写—关闭"模式的实现，以使用TCP协议通讯的socket为例，其交互流程大概是这样子的  
![](http://oqfs0y2cu.bkt.clouddn.com/17-7-14/85317428.jpg)

####socket编程API
这里简单解释一下方法作用和参数 
 
	int socket(int domain, int type, int protocol);
根据指定的地址族、数据类型和协议来分配一个socket的描述字及其所用的资源。
domain:协议族，常用的有AF_INET、AF_INET6、AF_LOCAL、AF_ROUTE其中AF_INET代表使用ipv4地址。  
type:socket类型，常用的socket类型有，SOCK_STREAM、SOCK_DGRAM、SOCK_RAW、SOCK_PACKET、SOCK_SEQPACKET等  
protocol:协议。常用的协议有，IPPROTO_TCP、IPPTOTO_UDP、IPPROTO_SCTP、IPPROTO_TIPC等 
 
	int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
	
把一个地址族中的特定地址赋给socket  
sockfd:socket描述字，也就是socket引用  
addr:要绑定给sockfd的协议地址  
addrlen:地址的长度

	int listen(int sockfd, int backlog);
监听socket  
sockfd:要监听的socket描述字  
backlog:相应socket可以排队的最大连接个数 

	int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);	
连接某个socket  
sockfd:客户端的socket描述字  
addr:服务器的socket地址  
addrlen:socket地址的长度

	int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
TCP服务器监听到客户端请求之后，调用accept()函数取接收请求  
sockfd:服务器的socket描述字  
addr:客户端的socket地址  
addrlen:socket地址的长度  

	ssize_t read(int fd, void *buf, size_t count);
读取socket内容  
fd:socket描述字  
buf：缓冲区  
count：缓冲区长度

	ssize_t write(int fd, const void *buf, size_t count);
向socket写入内容，其实就是发送内容  
fd:socket描述字  
buf：缓冲区  
count：缓冲区长度

int close(int fd);
socket标记为以关闭 ，使相应socket描述字的引用计数-1，当引用计数为0的时候，触发TCP客户端向服务器发送终止连接请求。
