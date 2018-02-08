//
//  ViewController.m
//  SocketService
//
//  Created by weiguang on 2018/2/8.
//  Copyright © 2018年 weiguang. All rights reserved.
//

#import "ViewController.h"
#import <arpa/inet.h>
#import <sys/socket.h>
#import <ifaddrs.h>

// 最大连接客户端数量
static int const kMaxConnectCount = 5;

@interface ViewController ()
// 服务器端socket
@property (nonatomic, assign) int serverSocket;
// 接收消息时客户端socket
@property (nonatomic, assign) int newSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startConnect:(UIButton *)sender {
    // 1.创建socket
    /*
     * socket返回一个int值，-1为创建失败
     * 第一个参数指明了协议族/域 ，通常有AF_INET(IPV4)、AF_INET6(IPV6)、AF_LOCAL
     * 第二个参数指定一个套接口类型：SOCK_STREAM,SOCK_DGRAM、SOCK_SEQPACKET等
     * 第三个参数指定相应的传输协议，常用的：IPPROTO_TCP、IPPTOTO_UDP,一般设置为0来使用这个默认的值，会根据第二个参数自动选择合适的，一般SOCK_STREAM对应TCP协议，SOCK_DGRAM对应UDP协议
     */
    int server_Socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_Socket == -1) {
        NSLog(@"创建失败");
        // 创建失败，要关闭socket
        close(server_Socket);
        // 退出
        exit(1);
        return;
    }
    self.serverSocket = server_Socket;
    
    // 2.绑定地址和端口
    // 地址结构体数据，记录ip和端口号
    struct sockaddr_in server_addr;
    // 声明使用的协议
    server_addr.sin_family = AF_INET;
    
    // 设置端口号，htons()是将整型变量从主机字节顺序转变成网络字节顺序
    server_addr.sin_port = htons(12345);
    
    // 获取本机的ip，转换成char类型的
    NSString *ipStr = [self getIPAddress];
    const char *ip = [ipStr cStringUsingEncoding:NSASCIIStringEncoding];
    // inet_addr("127.0.0.1"),可以直接用本机地址
    server_addr.sin_addr.s_addr = inet_addr(ip);
    
    /*
     * bind函数用于将套接字关联一个地址，返回一个int值，-1为失败
     * 第一个参数指定套接字，就是前面socket函数调用返回额套接字
     * 第二个参数为指定的地址
     * 第三个参数为地址数据的大小
     */
    int bind_result = bind(server_Socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (bind_result == -1) {
         NSLog(@"绑定端口失败");
        close(self.serverSocket);
        //exit(1);
        return;
    }
    
    // 3.监听绑定的地址
    /*
     * listen函数使用主动连接套接接口变为被连接接口，使得可以接受其他进程的请求，返回一个int值，-1为失败
     * 第一个参数是之前socket函数返回的套接字
     * 第二个参数可以理解为连接的最大限制
     */
    int ls = listen(self.serverSocket, kMaxConnectCount);
    if (ls == -1) {
        NSLog(@"监听失败");
        close(self.serverSocket);
        exit(1);
        return;
    }
    
    // 4,开启一个子线程用于数据的接收
    NSThread *recvThread = [[NSThread alloc] initWithTarget:self selector:@selector(recvData) object:nil];
    [recvThread start];
}

// 等待客户端的连接，使用accept()(由于accept函数会阻塞线程，在等待连接的过程中会一直卡着，所以建议将其放在子线程里面)
- (void)recvData {
    /*
     * accept()函数在连接成功后会返回一个新的套接字(self.newSocket)，用于之后和这个客户端之前收发数据
     * 第一个参数为之接前监听的套字,之前是局部变量，现在需要改为全局的
     * 第二个参数是一个结果参数，它用来接收一个返回值，这个返回值指定客户端的地址
     * 第三个参数也是一个结果参数，它用来接收recvAddr结构体的代销，指明其所占的字节数
     */
    struct sockaddr_in client_address;
    socklen_t address_len = 0;
    int client_socket = accept(self.serverSocket, (struct sockaddr *)&client_address, &address_len);
    self.newSocket = client_socket;
    if (client_socket == -1) {
         NSLog(@"接受客户端链接失败");
        return;
    }
    
    while (1) {
        // 接收客户端传来的数据
        char buf[1024] = {0};
        long iReturn = recv(client_socket, buf, 1024, 0);
        if (iReturn > 0) {
            NSLog(@"客户端来消息了");
            NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
            NSLog(@"%@",str);
        }else if (iReturn == -1) {
            NSLog(@"读取消息失败");
            break;
        }else if (iReturn == 0) {
            NSLog(@"客户端走了");
            close(client_socket);
            break;
        }
    }
    
}

- (IBAction)sendMessage:(UIButton *)sender {
    NSString *msg = @"hello client";
    char *buf[1024] = {0};
    const char *p1 = (char*)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(self.newSocket, p1, 1024, 0);
}


// Get IP Address
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    NSLog(@"%@",address);
    return address;
}


@end
