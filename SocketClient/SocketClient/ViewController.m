//
//  ViewController.m
//  SocketClient
//
//  Created by weiguang on 2018/2/8.
//  Copyright © 2018年 weiguang. All rights reserved.
//

#import "ViewController.h"
#import <arpa/inet.h>
#import <sys/socket.h>
#import <ifaddrs.h>

@interface ViewController ()
@property (nonatomic, assign) int sock;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)connectBtnClick {
    // 1.创建socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        NSLog(@"socket error : %d",sock);
        return;
    }
    NSString *host = [self getIPAddress];
    const char *ip = [host cStringUsingEncoding:NSASCIIStringEncoding];
    //2,获取主机的地址,绑定地址和端口
    struct sockaddr_in server_addr;
    server_addr.sin_len = sizeof(struct sockaddr_in);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(12345);
    server_addr.sin_addr.s_addr = inet_addr(ip);
    bzero(&(server_addr.sin_zero), 8);
    
    //接受客户端的链接
    /*
     * connect函数通常用于客户端建立tcp连接，连接指定地址的主机，函数返回一个int值，-1为失败
     * 第一个参数为socket函数创建的套接字，代表这个套接字要连接指定主机
     * 第二个参数为套接字sock想要连接的主机地址和端口号
     * 第三个参数为主机地址大小
     */
    int con = connect(sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (con == -1) {
        close(sock);
        NSLog(@"连接失败");
        return;
    }
    NSLog(@"连接成功");
    self.sock = sock;
    
    // 开启一个子线程用于接收数据
    NSThread *recvThread = [[NSThread alloc] initWithTarget:self selector:@selector(recvData) object:nil];
    [recvThread start];
}

- (void)recvData{
    while (1) {
        //接受服务器传来的数据
        char buf[1024];
        long iReturn = recv(self.sock, buf, 1024, 0);
        if (iReturn > 0) {
            NSString *str = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
            NSLog(@"服务器端来消息了");
            NSLog(@"接收到的数据：%@",str);
        }else if (iReturn == -1) {
            NSLog(@"接受失败-1");
            break;
        }
    }
}

- (IBAction)sendMsg {
    NSString *msg = @"hello service";
    char *buf[1024] = {0};
    const char *p1 = (char*)buf;
    p1 = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(self.sock, p1, 1024, 0);
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
