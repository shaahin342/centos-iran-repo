Kubernetes (K8s) is an open-source system for automating deployment, scaling, and management of containerized applications. It groups containers that make up an application into logical units for easy management and discovery. Kubernetes builds upon 15 years of experience of running production workloads at Google, combined with best-of-breed ideas and practices from the community.

## 1\. Architecture Diagram[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#1-architecture-diagram "Direct link to 1. Architecture Diagram")

![](https://blog.yasithab.com/img/centos/kubernetes-ceph-architecture-diagram.svg)

## 2\. System Requirements[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#2-system-requirements "Direct link to 2. System Requirements")

### 2.1. Nginx Load Balancer[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#21-nginx-load-balancer "Direct link to 2.1. Nginx Load Balancer")

| Component | Description |
| --- | --- |
| Number of VMs | 2 |
| CPU | 2 Cores |
| Memory | 4 GB |
| Disk Size | 20 GB SSD |
| Storage Type | Thin Provision |
| Operating System | CentOS 8 x64 |
| File System | XFS |
| Privileges | **ROOT** access prefered |

### 2.2. Master Nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#22-master-nodes "Direct link to 2.2. Master Nodes")

| Component | Description |
| --- | --- |
| Number of VMs | 3 |
| CPU | 2 Cores |
| Memory | 8 GB |
| Disk Size | 150 GB SSD |
| Storage Type | Thin Provision |
| Operating System | CentOS 8 x64 |
| File System | XFS |
| Privileges | **ROOT** access prefered |

### 2.3. Worker Nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#23-worker-nodes "Direct link to 2.3. Worker Nodes")

| Component | Description |
| --- | --- |
| Number of VMs | 3 |
| CPU | 4 Cores |
| Memory | 16 GB |
| Disk Size | 500 GB SSD |
| Storage Type | Thin Provision |
| Operating System | CentOS 8 x64 |
| File System | XFS |
| Privileges | **ROOT** access prefered |

### 2.4. IP Allocation[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#24-ip-allocation "Direct link to 2.4. IP Allocation")

| Component | Description |
| --- | --- |
| Load Balancer Virtual IP | 192.168.16.80 |
| VM IPs | 192.168.16.100 - 192.168.16.108 |
| MetalLB IP Pool | 192.168.16.200 - 192.168.16.250 |

### 2.5. DNS Entries[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#25-dns-entries "Direct link to 2.5. DNS Entries")

| IP | Hostname | FQDN |
| --- | --- | --- |
| 192.168.16.80 | N/A | kube-api.example.local |
| 192.168.16.100 | kubelb01 | kubelb01.example.local |
| 192.168.16.101 | kubelb02 | kubelb02.example.local |
| 192.168.16.102 | kubemaster01 | kubemaster01.example.local |
| 192.168.16.103 | kubemaster02 | kubemaster02.example.local |
| 192.168.16.104 | kubemaster03 | kubemaster03.example.local |
| 192.168.16.105 | kubeworker01 | kubeworker01.example.local |
| 192.168.16.106 | kubeworker02 | kubeworker02.example.local |
| 192.168.16.107 | kubeworker03 | kubeworker03.example.local |

## 3\. Configure Nginx Load Balancers[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#3-configure-nginx-load-balancers "Direct link to 3. Configure Nginx Load Balancers")

info

-   Verify the **MAC address** and **product\_uuid** are unique for every node. You can get the MAC address of the network interfaces using `ip link | grep link/ether`
    
-   The **product\_uuid** can be checked by using `cat /sys/class/dmi/id/product_uuid`
    

3.1. Set server hostname.

```
<span><span># Example:</span><span></span><br></span><span><span></span><span># hostnamectl set-hostname kubelb01</span><span></span><br></span><span><span></span><br></span><span><span>hostnamectl set-hostname </span><span>&lt;</span><span>hostname</span><span>&gt;</span><br></span>
```

3.2. Install prerequisites.

```
<span><span># Clean YUM repository cache</span><span></span><br></span><span><span>dnf clean all</span><br></span><span><span></span><br></span><span><span></span><span># Update packages</span><span></span><br></span><span><span>dnf update -y</span><br></span><span><span></span><br></span><span><span></span><span># Install prerequisites</span><span></span><br></span><span><span>dnf </span><span>install</span><span> -y </span><span>vim</span><span> net-tools chrony ntpstat keepalived nginx policycoreutils-python-utils</span><br></span>
```

3.3. Synchronize server time with **Google NTP** server.

```
<span><span># Add Google NTP Server</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'/^pool/c\pool time.google.com iburst'</span><span> /etc/chrony.conf</span><br></span><span><span></span><br></span><span><span></span><span># Set timezone to Asia/Colombo</span><span></span><br></span><span><span>timedatectl set-timezone Asia/Colombo</span><br></span><span><span></span><br></span><span><span></span><span># Enable NTP time synchronization</span><span></span><br></span><span><span>timedatectl set-ntp </span><span>true</span><br></span>
```

3.4. Start and enable _chronyd_ service.

```
<span><span># Start and enable chronyd service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now chronyd</span><br></span><span><span></span><br></span><span><span></span><span># Check if chronyd service is running</span><span></span><br></span><span><span>systemctl status chronyd</span><br></span>
```

3.5. Display time synchronization status.

```
<span><span># Verify synchronisation state</span><span></span><br></span><span><span>ntpstat</span><br></span><span><span></span><br></span><span><span></span><span># Check Chrony Source Statistics</span><span></span><br></span><span><span>chronyc sourcestats -v</span><br></span>
```

3.6. Permanently disable SELinux.

```
<span><span># Permanently disable SELinux</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'s/^SELINUX=enforcing$/SELINUX=disabled/'</span><span> /etc/selinux/config</span><br></span>
```

3.7. Disable IPv6 on network interface.

```
<span><span># Disable IPv6 on ens192 interface</span><span></span><br></span><span><span>nmcli connection modify ens192 ipv6.method ignore</span><br></span>
```

3.8. Execute the following commands to turn off all swap devices and files.

```
<span><span># Permanently disable swapping</span><span></span><br></span><span><span></span><span>sed</span><span> -e </span><span>'/swap/ s/^#*/#/g'</span><span> -i /etc/fstab</span><br></span><span><span></span><br></span><span><span></span><span># Disable all existing swaps from /proc/swaps</span><span></span><br></span><span><span>swapoff -a</span><br></span>
```

3.9. Disable **File Access Time Logging** and enable **Combat Fragmentation** to enhance XFS file system performance. Add `noatime,nodiratime,allocsize=64m` to all XFS volumes under `/etc/fstab`.

```
<span><span># Edit /etc/fstab</span><span></span><br></span><span><span></span><span>vim</span><span> /etc/fstab</span><br></span><span><span></span><br></span><span><span></span><span># Modify XFS volume entries as follows</span><span></span><br></span><span><span></span><span># Example:</span><span></span><br></span><span><span></span><span>UUID</span><span>=</span><span>"03c97344-9b3d-45e2-9140-cbbd57b6f085"</span><span>  /  xfs  defaults,noatime,nodiratime,allocsize</span><span>=</span><span>64m  </span><span>0</span><span> </span><span>0</span><br></span>
```

3.10. Tweaking the system for high concurrancy and security.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/sysctl.d/00-sysctl.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>################################################################################################</span><br></span><span><span># Tweak virtual memory</span><br></span><span><span>################################################################################################</span><br></span><span><span></span><br></span><span><span># Default: 30</span><br></span><span><span># 0 - Never swap under any circumstances.</span><br></span><span><span># 1 - Do not swap unless there is an out-of-memory (OOM) condition.</span><br></span><span><span>vm.swappiness = 1</span><br></span><span><span></span><br></span><span><span># vm.dirty_background_ratio is used to adjust how the kernel handles dirty pages that must be flushed to disk.</span><br></span><span><span># Default value is 10.</span><br></span><span><span># The value is a percentage of the total amount of system memory, and setting this value to 5 is appropriate in many situations.</span><br></span><span><span># This setting should not be set to zero.</span><br></span><span><span>vm.dirty_background_ratio = 5</span><br></span><span><span></span><br></span><span><span># The total number of dirty pages that are allowed before the kernel forces synchronous operations to flush them to disk</span><br></span><span><span># can also be increased by changing the value of vm.dirty_ratio, increasing it to above the default of 30 (also a percentage of total system memory)</span><br></span><span><span># vm.dirty_ratio value in-between 60 and 80 is a reasonable number.</span><br></span><span><span>vm.dirty_ratio = 60</span><br></span><span><span></span><br></span><span><span># vm.max_map_count will calculate the current number of memory mapped files.</span><br></span><span><span># The minimum value for mmap limit (vm.max_map_count) is the number of open files ulimit (cat /proc/sys/fs/file-max).</span><br></span><span><span># map_count should be around 1 per 128 KB of system memory. Therefore, max_map_count will be 262144 on a 32 GB system.</span><br></span><span><span># Default: 65530</span><br></span><span><span>vm.max_map_count = 2097152</span><br></span><span><span></span><br></span><span><span>################################################################################################</span><br></span><span><span># Tweak file handles</span><br></span><span><span>################################################################################################</span><br></span><span><span></span><br></span><span><span># Increases the size of file handles and inode cache and restricts core dumps.</span><br></span><span><span>fs.file-max = 2097152</span><br></span><span><span>fs.suid_dumpable = 0</span><br></span><span><span></span><br></span><span><span>################################################################################################</span><br></span><span><span># Tweak network settings</span><br></span><span><span>################################################################################################</span><br></span><span><span></span><br></span><span><span># Default amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span># This will significantly increase performance for large transfers.</span><br></span><span><span>net.core.wmem_default = 25165824</span><br></span><span><span>net.core.rmem_default = 25165824</span><br></span><span><span></span><br></span><span><span># Maximum amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span># This will significantly increase performance for large transfers.</span><br></span><span><span>net.core.wmem_max = 25165824</span><br></span><span><span>net.core.rmem_max = 25165824</span><br></span><span><span></span><br></span><span><span># In addition to the socket settings, the send and receive buffer sizes for</span><br></span><span><span># TCP sockets must be set separately using the net.ipv4.tcp_wmem and net.ipv4.tcp_rmem parameters.</span><br></span><span><span># These are set using three space-separated integers that specify the minimum, default, and maximum sizes, respectively.</span><br></span><span><span># The maximum size cannot be larger than the values specified for all sockets using net.core.wmem_max and net.core.rmem_max.</span><br></span><span><span># A reasonable setting is a 4 KiB minimum, 64 KiB default, and 2 MiB maximum buffer.</span><br></span><span><span>net.ipv4.tcp_wmem = 20480 12582912 25165824</span><br></span><span><span>net.ipv4.tcp_rmem = 20480 12582912 25165824</span><br></span><span><span></span><br></span><span><span># Increase the maximum total buffer-space allocatable</span><br></span><span><span># This is measured in units of pages (4096 bytes)</span><br></span><span><span>net.ipv4.tcp_mem = 65536 25165824 262144</span><br></span><span><span>net.ipv4.udp_mem = 65536 25165824 262144</span><br></span><span><span></span><br></span><span><span># Minimum amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span>net.ipv4.udp_wmem_min = 16384</span><br></span><span><span>net.ipv4.udp_rmem_min = 16384</span><br></span><span><span></span><br></span><span><span># Enabling TCP window scaling by setting net.ipv4.tcp_window_scaling to 1 will allow</span><br></span><span><span># clients to transfer data more efficiently, and allow that data to be buffered on the broker side.</span><br></span><span><span>net.ipv4.tcp_window_scaling = 1</span><br></span><span><span></span><br></span><span><span># Increasing the value of net.ipv4.tcp_max_syn_backlog above the default of 1024 will allow</span><br></span><span><span># a greater number of simultaneous connections to be accepted.</span><br></span><span><span>net.ipv4.tcp_max_syn_backlog = 10240</span><br></span><span><span></span><br></span><span><span># Increasing the value of net.core.netdev_max_backlog to greater than the default of 1000</span><br></span><span><span># can assist with bursts of network traffic, specifically when using multigigabit network connection speeds,</span><br></span><span><span># by allowing more packets to be queued for the kernel to process them.</span><br></span><span><span>net.core.netdev_max_backlog = 65536</span><br></span><span><span></span><br></span><span><span># Increase the maximum amount of option memory buffers</span><br></span><span><span>net.core.optmem_max = 25165824</span><br></span><span><span></span><br></span><span><span># Number of times SYNACKs for passive TCP connection.</span><br></span><span><span>net.ipv4.tcp_synack_retries = 2</span><br></span><span><span></span><br></span><span><span># Allowed local port range.</span><br></span><span><span>net.ipv4.ip_local_port_range = 2048 65535</span><br></span><span><span></span><br></span><span><span># Protect Against TCP Time-Wait</span><br></span><span><span># Default: net.ipv4.tcp_rfc1337 = 0</span><br></span><span><span>net.ipv4.tcp_rfc1337 = 1</span><br></span><span><span></span><br></span><span><span># Decrease the time default value for tcp_fin_timeout connection</span><br></span><span><span>net.ipv4.tcp_fin_timeout = 15</span><br></span><span><span></span><br></span><span><span># The maximum number of backlogged sockets.</span><br></span><span><span># Default is 128.</span><br></span><span><span>net.core.somaxconn = 4096</span><br></span><span><span></span><br></span><span><span># Turn on syncookies for SYN flood attack protection.</span><br></span><span><span>net.ipv4.tcp_syncookies = 1</span><br></span><span><span></span><br></span><span><span># Avoid a smurf attack</span><br></span><span><span>net.ipv4.icmp_echo_ignore_broadcasts = 1</span><br></span><span><span></span><br></span><span><span># Turn on protection for bad icmp error messages</span><br></span><span><span>net.ipv4.icmp_ignore_bogus_error_responses = 1</span><br></span><span><span></span><br></span><span><span># Enable automatic window scaling.</span><br></span><span><span># This will allow the TCP buffer to grow beyond its usual maximum of 64K if the latency justifies it.</span><br></span><span><span>net.ipv4.tcp_window_scaling = 1</span><br></span><span><span></span><br></span><span><span># Turn on and log spoofed, source routed, and redirect packets</span><br></span><span><span>net.ipv4.conf.all.log_martians = 1</span><br></span><span><span>net.ipv4.conf.default.log_martians = 1</span><br></span><span><span></span><br></span><span><span># Tells the kernel how many TCP sockets that are not attached to any</span><br></span><span><span># user file handle to maintain. In case this number is exceeded,</span><br></span><span><span># orphaned connections are immediately reset and a warning is printed.</span><br></span><span><span># Default: net.ipv4.tcp_max_orphans = 65536</span><br></span><span><span>net.ipv4.tcp_max_orphans = 65536</span><br></span><span><span></span><br></span><span><span># Do not cache metrics on closing connections</span><br></span><span><span>net.ipv4.tcp_no_metrics_save = 1</span><br></span><span><span></span><br></span><span><span># Enable timestamps as defined in RFC1323:</span><br></span><span><span># Default: net.ipv4.tcp_timestamps = 1</span><br></span><span><span>net.ipv4.tcp_timestamps = 1</span><br></span><span><span></span><br></span><span><span># Enable select acknowledgments.</span><br></span><span><span># Default: net.ipv4.tcp_sack = 1</span><br></span><span><span>net.ipv4.tcp_sack = 1</span><br></span><span><span></span><br></span><span><span># Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks.</span><br></span><span><span># net.ipv4.tcp_tw_recycle has been removed from Linux 4.12. Use net.ipv4.tcp_tw_reuse instead.</span><br></span><span><span>net.ipv4.tcp_max_tw_buckets = 1440000</span><br></span><span><span>net.ipv4.tcp_tw_reuse = 1</span><br></span><span><span></span><br></span><span><span># The accept_source_route option causes network interfaces to accept packets with the Strict Source Route (SSR) or Loose Source Routing (LSR) option set. </span><br></span><span><span># The following setting will drop packets with the SSR or LSR option set.</span><br></span><span><span>net.ipv4.conf.all.accept_source_route = 0</span><br></span><span><span>net.ipv4.conf.default.accept_source_route = 0</span><br></span><span><span></span><br></span><span><span># Turn on reverse path filtering</span><br></span><span><span>net.ipv4.conf.all.rp_filter = 1</span><br></span><span><span>net.ipv4.conf.default.rp_filter = 1</span><br></span><span><span></span><br></span><span><span># Disable ICMP redirect acceptance</span><br></span><span><span>net.ipv4.conf.all.accept_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.accept_redirects = 0</span><br></span><span><span>net.ipv4.conf.all.secure_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.secure_redirects = 0</span><br></span><span><span></span><br></span><span><span># Disables sending of all IPv4 ICMP redirected packets.</span><br></span><span><span>net.ipv4.conf.all.send_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.send_redirects = 0</span><br></span><span><span></span><br></span><span><span># Disable IP forwarding.</span><br></span><span><span># IP forwarding is the ability for an operating system to accept incoming network packets on one interface,</span><br></span><span><span># recognize that it is not meant for the system itself, but that it should be passed on to another network, and then forwards it accordingly.</span><br></span><span><span>net.ipv4.ip_forward = 0</span><br></span><span><span></span><br></span><span><span># Disable IPv6</span><br></span><span><span>net.ipv6.conf.all.disable_ipv6 = 1</span><br></span><span><span>net.ipv6.conf.default.disable_ipv6 = 1</span><br></span><span><span></span><br></span><span><span>################################################################################################</span><br></span><span><span># Tweak kernel parameters</span><br></span><span><span>################################################################################################</span><br></span><span><span></span><br></span><span><span># Address Space Layout Randomization (ASLR) is a memory-protection process for operating systems that guards against buffer-overflow attacks.</span><br></span><span><span># It helps to ensure that the memory addresses associated with running processes on systems are not predictable,</span><br></span><span><span># thus flaws or vulnerabilities associated with these processes will be more difficult to exploit.</span><br></span><span><span># Accepted values: 0 = Disabled, 1 = Conservative Randomization, 2 = Full Randomization</span><br></span><span><span>kernel.randomize_va_space = 2</span><br></span><span><span></span><br></span><span><span># Allow for more PIDs (to reduce rollover problems)</span><br></span><span><span>kernel.pid_max = 65536</span><br></span><span><span>EOF</span><br></span>
```

3.11. Reload all **sysctl** variables without rebooting the server.

```
<span><span>sysctl -p /etc/sysctl.d/00-sysctl.conf</span><br></span>
```

3.12. Configure firewall for **Nginx** and **Keepalived**.

```
<span><span># Enable ans start firewalld.service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now firewalld</span><br></span><span><span></span><br></span><span><span></span><span># You must allow VRRP traffic to pass between the keepalived nodes</span><span></span><br></span><span><span>firewall-cmd --permanent --add-rich-rule</span><span>=</span><span>'rule protocol value="vrrp" accept'</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Enable Kubernetes API</span><span></span><br></span><span><span>firewall-cmd --permanent --add-port</span><span>=</span><span>6443</span><span>/tcp</span><br></span><span><span></span><br></span><span><span></span><span># Reload firewall rules</span><span></span><br></span><span><span>firewall-cmd --reload</span><br></span>
```

3.13. Create Local DNS records.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/hosts </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span># localhost</span><br></span><span><span>127.0.0.1     localhost        localhost.localdomain</span><br></span><span><span></span><br></span><span><span># When DNS records are updated in the DNS server, remove these entries.</span><br></span><span><span>192.168.16.80  kube-api.example.local</span><br></span><span><span>192.168.16.102 kubemaster01  kubemaster01.example.local</span><br></span><span><span>192.168.16.103 kubemaster02  kubemaster02.example.local</span><br></span><span><span>192.168.16.104 kubemaster03  kubemaster03.example.local</span><br></span><span><span>192.168.16.105 kubeworker01  kubeworker01.example.local</span><br></span><span><span>192.168.16.106 kubeworker02  kubeworker02.example.local</span><br></span><span><span>192.168.16.107 kubeworker03  kubeworker03.example.local</span><br></span><span><span>EOF</span><br></span>
```

3.14. Configure _keepalived_ failover on **kubelb01** and **kubelb02**.

info

-   Don't forget to change _**auth\_pass**_ to something more secure.
    
-   Change interface _**ens192**_ to match your interface name.
    
-   Change _**virtual\_ipaddress**_ from 192.168.16.80 to a valid IP.
    
-   The _**priority**_ specifies the order in which the assigned interface takes over in a failover; the higher the number, the higher the priority.
    

3.14.1. Please execute the following command on **kubelb01** Server.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/keepalived/keepalived.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span># Global definitions configuration block</span><br></span><span><span>global_defs {</span><br></span><span><span></span><br></span><span><span>    router_id LVS_LB</span><br></span><span><span></span><br></span><span><span>}</span><br></span><span><span></span><br></span><span><span>vrrp_instance VI_1 {</span><br></span><span><span></span><br></span><span><span>    # The state MASTER designates the active server, the state BACKUP designates the backup server.</span><br></span><span><span>    state MASTER</span><br></span><span><span></span><br></span><span><span>    virtual_router_id 100</span><br></span><span><span></span><br></span><span><span>    # The interface parameter assigns the physical interface name </span><br></span><span><span>    # to this particular virtual IP instance.</span><br></span><span><span>    interface ens192</span><br></span><span><span></span><br></span><span><span>    # The priority specifies the order in which the assigned interface</span><br></span><span><span>    # takes over in a failover; the higher the number, the higher the priority.</span><br></span><span><span>    # This priority value must be within the range of 0 to 255, and the Load Balancing </span><br></span><span><span>    # server configured as state MASTER should have a priority value set to a higher number </span><br></span><span><span>    # than the priority value of the server configured as state BACKUP.</span><br></span><span><span>    priority 150</span><br></span><span><span></span><br></span><span><span>    advert_int 1</span><br></span><span><span></span><br></span><span><span>    authentication {</span><br></span><span><span></span><br></span><span><span>        auth_type PASS</span><br></span><span><span></span><br></span><span><span>        # Don't forget to change auth_pass to something more secure.</span><br></span><span><span>        # auth_pass value MUST be same in both nodes.</span><br></span><span><span>        auth_pass Bx3ae3Gr</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span></span><br></span><span><span>    virtual_ipaddress {</span><br></span><span><span></span><br></span><span><span>        192.168.16.80</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span>}</span><br></span><span><span>EOF</span><br></span>
```

3.14.2. Please execute the following command on **kubelb02** Server.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/keepalived/keepalived.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span># Global definitions configuration block</span><br></span><span><span>global_defs {</span><br></span><span><span></span><br></span><span><span>    router_id LVS_LB</span><br></span><span><span></span><br></span><span><span>}</span><br></span><span><span></span><br></span><span><span>vrrp_instance VI_1 {</span><br></span><span><span></span><br></span><span><span>    # The state MASTER designates the active server, the state BACKUP designates the backup server.</span><br></span><span><span>    state BACKUP</span><br></span><span><span></span><br></span><span><span>    virtual_router_id 100</span><br></span><span><span></span><br></span><span><span>    # The interface parameter assigns the physical interface name </span><br></span><span><span>    # to this particular virtual IP instance.</span><br></span><span><span>    interface ens192</span><br></span><span><span></span><br></span><span><span>    # The priority specifies the order in which the assigned interface</span><br></span><span><span>    # takes over in a failover; the higher the number, the higher the priority.</span><br></span><span><span>    # This priority value must be within the range of 0 to 255, and the Load Balancing </span><br></span><span><span>    # server configured as state MASTER should have a priority value set to a higher number </span><br></span><span><span>    # than the priority value of the server configured as state BACKUP.</span><br></span><span><span>    priority 100</span><br></span><span><span></span><br></span><span><span>    advert_int 1</span><br></span><span><span></span><br></span><span><span>    authentication {</span><br></span><span><span></span><br></span><span><span>        auth_type PASS</span><br></span><span><span></span><br></span><span><span>        # Don't forget to change auth_pass to something more secure.</span><br></span><span><span>        # auth_pass value MUST be same in both nodes.</span><br></span><span><span>        auth_pass Bx3ae3Gr</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span></span><br></span><span><span>    virtual_ipaddress {</span><br></span><span><span></span><br></span><span><span>        192.168.16.80</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span>}</span><br></span><span><span>EOF</span><br></span>
```

3.15. Start and enable _keepalived_ service on **both** load balancer nodes.

```
<span><span># Start and enable keepalived service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now keepalived</span><br></span><span><span></span><br></span><span><span></span><span># Check if the keepalived service is running</span><span></span><br></span><span><span>systemctl status keepalived</span><br></span>
```

3.16. To determine whether a server is acting as the master, you can use the following command to see whether the virtual address is active.

3.17. Configure nginx on **both** load balancer nodes.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/nginx/nginx.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>user nginx;</span><br></span><span><span>worker_processes auto;</span><br></span><span><span>error_log /var/log/nginx/error.log;</span><br></span><span><span>pid /run/nginx.pid;</span><br></span><span><span></span><br></span><span><span># Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.</span><br></span><span><span>include /usr/share/nginx/modules/*.conf;</span><br></span><span><span></span><br></span><span><span>events {</span><br></span><span><span></span><br></span><span><span>    worker_connections 2048;</span><br></span><span><span></span><br></span><span><span>}</span><br></span><span><span></span><br></span><span><span>stream {</span><br></span><span><span></span><br></span><span><span>    upstream stream_backend {</span><br></span><span><span></span><br></span><span><span>        # Load balance algorithm</span><br></span><span><span>        least_conn;</span><br></span><span><span></span><br></span><span><span>        # kubemaster01</span><br></span><span><span>        server kubemaster01.example.local:6443;</span><br></span><span><span></span><br></span><span><span>        # kubemaster02</span><br></span><span><span>        server kubemaster02.example.local:6443;</span><br></span><span><span></span><br></span><span><span>        # kubemaster03</span><br></span><span><span>        server kubemaster03.example.local:6443;</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span></span><br></span><span><span>    server {</span><br></span><span><span></span><br></span><span><span>        listen                  6443;</span><br></span><span><span>        proxy_pass              stream_backend;</span><br></span><span><span></span><br></span><span><span>        proxy_timeout           300s;</span><br></span><span><span>        proxy_connect_timeout   60s;</span><br></span><span><span></span><br></span><span><span>    }</span><br></span><span><span></span><br></span><span><span>}</span><br></span><span><span>EOF</span><br></span>
```

3.18. Start and enable _nginx_ service on **both** load balancer nodes.

```
<span><span># Start and enable nginx service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now nginx</span><br></span><span><span></span><br></span><span><span></span><span># Check if the nginx service is running</span><span></span><br></span><span><span>systemctl status nginx</span><br></span>
```

3.19. The servers need to be restarted before continue further.

3.20. Verify the load balancer.

```
<span><span>curl</span><span> -k https://kube-api.example.local:6443</span><br></span>
```

note

#### If the load balancers are working, you should get the following output[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#if-the-load-balancers-are-working-you-should-get-the-following-output "Direct link to If the load balancers are working, you should get the following output")

curl: (35) OpenSSL SSL\_connect: SSL\_ERROR\_SYSCALL in connection to [https://kube-api.example.local:6443](https://kube-api.example.local:6443/)

## 4\. Install and Configure Kubernetes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#4-install-and-configure-kubernetes "Direct link to 4. Install and Configure Kubernetes")

### 4.1. Install prerequisites on **BOTH** Master and Worker nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#41-install-prerequisites-on-both-master-and-worker-nodes "Direct link to 41-install-prerequisites-on-both-master-and-worker-nodes")

info

-   Verify the **MAC address** and **product\_uuid** are unique for every node. You can get the MAC address of the network interfaces using `ip link | grep link/ether`
    
-   The **product\_uuid** can be checked by using `cat /sys/class/dmi/id/product_uuid`
    
-   Verify the **Linux Kernel** version is greater than **4.5.0**. It can be checked by using `uname -r`
    
-   Docker, CentOS 8 and the XFS filesystem could be a trouble giving combination if you don't meet all the specifications of the overlay/overlay2 storage driver.
    
-   The overlay storage driver relies on a technology called "directory entry type" (d\_type) and is used to describe information of a directory on the filesystem. Make sure you have a _d\_type_ enabled filesystem by running the `xfs_info / | grep ftype` command. The **ftype** value must be set to **1**. If not do not continue further.
    

4.1.1. Set server hostname.

```
<span><span># Example:</span><span></span><br></span><span><span></span><span># hostnamectl set-hostname kubelb01</span><span></span><br></span><span><span></span><br></span><span><span>hostnamectl set-hostname </span><span>&lt;</span><span>hostname</span><span>&gt;</span><br></span>
```

4.1.2. Install prerequisites.

```
<span><span># Clean YUM repository cache</span><span></span><br></span><span><span>dnf clean all</span><br></span><span><span></span><br></span><span><span></span><span># Update packages</span><span></span><br></span><span><span>dnf update -y</span><br></span><span><span></span><br></span><span><span></span><span># Install prerequisites</span><span></span><br></span><span><span>dnf </span><span>install</span><span> -y </span><span>vim</span><span> net-tools chrony ntpstat</span><br></span>
```

4.1.3. Synchronize server time with **Google NTP** server.

```
<span><span># Add Google NTP Server</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'/^pool/c\pool time.google.com iburst'</span><span> /etc/chrony.conf</span><br></span><span><span></span><br></span><span><span></span><span># Set timezone to Asia/Colombo</span><span></span><br></span><span><span>timedatectl set-timezone Asia/Colombo</span><br></span><span><span></span><br></span><span><span></span><span># Enable NTP time synchronization</span><span></span><br></span><span><span>timedatectl set-ntp </span><span>true</span><br></span>
```

4.1.4. Start and enable _chronyd_ service.

```
<span><span># Start and enable chronyd service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now chronyd</span><br></span><span><span></span><br></span><span><span></span><span># Check if chronyd service is running</span><span></span><br></span><span><span>systemctl status chronyd</span><br></span>
```

4.1.5. Display time synchronization status.

```
<span><span># Verify synchronisation state</span><span></span><br></span><span><span>ntpstat</span><br></span><span><span></span><br></span><span><span></span><span># Check Chrony Source Statistics</span><span></span><br></span><span><span>chronyc sourcestats -v</span><br></span>
```

4.1.6. Permanently disable SELinux.

```
<span><span># Permanently disable SELinux</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'s/^SELINUX=enforcing$/SELINUX=disabled/'</span><span> /etc/selinux/config</span><br></span>
```

4.1.7. Enable IP masquerade at the Linux firewall.

```
<span><span># Enable IP masquerade at the firewall</span><span></span><br></span><span><span>firewall-cmd --permanent --add-masquerade</span><br></span><span><span>firewall-cmd --reload</span><br></span>
```

4.1.8. Disable IPv6 on network interface.

```
<span><span># Disable IPv6 on ens192 interface</span><span></span><br></span><span><span>nmcli connection modify ens192 ipv6.method ignore</span><br></span>
```

4.1.9. Execute the following commands to turn off all swap devices and files.

```
<span><span># Permanently disable swapping</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'/ swap / s/^/#/'</span><span> /etc/fstab</span><br></span><span><span></span><br></span><span><span></span><span>#d Disable all existing swaps from /proc/swaps</span><span></span><br></span><span><span>swapoff -a</span><br></span>
```

4.1.10. Enable auto-loading of required kernel modules.

```
<span><span># Enable auto-loading of required kernel modules</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/modules-load.d/crio.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>overlay</span><br></span><span><span>br_netfilter</span><br></span><span><span>EOF</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Add overlay and br_netfilter kernel modules to the Linux kernel</span><span></span><br></span><span><span></span><span># The br_netfilter kernel modules will enable transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster</span><span></span><br></span><span><span>modprobe overlay</span><br></span><span><span>modprobe br_netfilter</span><br></span>
```

4.1.11. Disable **File Access Time Logging** and enable **Combat Fragmentation** to enhance XFS file system performance. Add `noatime,nodiratime,allocsize=64m` to all XFS volumes under `/etc/fstab`.

```
<span><span># Edit /etc/fstab</span><span></span><br></span><span><span></span><span>vim</span><span> /etc/fstab</span><br></span><span><span></span><br></span><span><span></span><span># Modify XFS volume entries as follows</span><span></span><br></span><span><span></span><span># Example:</span><span></span><br></span><span><span></span><span>UUID</span><span>=</span><span>"03c97344-9b3d-45e2-9140-cbbd57b6f085"</span><span>  /  xfs  defaults,noatime,nodiratime,allocsize</span><span>=</span><span>64m  </span><span>0</span><span> </span><span>0</span><br></span>
```

4.1.12. Tweaking the system for high concurrancy and security.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/sysctl.d/00-sysctl.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>#############################################################################################</span><br></span><span><span># Tweak virtual memory</span><br></span><span><span>#############################################################################################</span><br></span><span><span></span><br></span><span><span># Default: 30</span><br></span><span><span># 0 - Never swap under any circumstances.</span><br></span><span><span># 1 - Do not swap unless there is an out-of-memory (OOM) condition.</span><br></span><span><span>vm.swappiness = 1</span><br></span><span><span></span><br></span><span><span># vm.dirty_background_ratio is used to adjust how the kernel handles dirty pages that must be flushed to disk.</span><br></span><span><span># Default value is 10.</span><br></span><span><span># The value is a percentage of the total amount of system memory, and setting this value to 5 is appropriate in many situations.</span><br></span><span><span># This setting should not be set to zero.</span><br></span><span><span>vm.dirty_background_ratio = 5</span><br></span><span><span></span><br></span><span><span># The total number of dirty pages that are allowed before the kernel forces synchronous operations to flush them to disk</span><br></span><span><span># can also be increased by changing the value of vm.dirty_ratio, increasing it to above the default of 30 (also a percentage of total system memory)</span><br></span><span><span># vm.dirty_ratio value in-between 60 and 80 is a reasonable number.</span><br></span><span><span>vm.dirty_ratio = 60</span><br></span><span><span></span><br></span><span><span># vm.max_map_count will calculate the current number of memory mapped files.</span><br></span><span><span># The minimum value for mmap limit (vm.max_map_count) is the number of open files ulimit (cat /proc/sys/fs/file-max).</span><br></span><span><span># map_count should be around 1 per 128 KB of system memory. Therefore, max_map_count will be 262144 on a 32 GB system.</span><br></span><span><span># Default: 65530</span><br></span><span><span>vm.max_map_count = 2097152</span><br></span><span><span></span><br></span><span><span>#############################################################################################</span><br></span><span><span># Tweak file handles</span><br></span><span><span>#############################################################################################</span><br></span><span><span></span><br></span><span><span># Increases the size of file handles and inode cache and restricts core dumps.</span><br></span><span><span>fs.file-max = 2097152</span><br></span><span><span>fs.suid_dumpable = 0</span><br></span><span><span></span><br></span><span><span>#############################################################################################</span><br></span><span><span># Tweak network settings</span><br></span><span><span>#############################################################################################</span><br></span><span><span></span><br></span><span><span># Default amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span># This will significantly increase performance for large transfers.</span><br></span><span><span>net.core.wmem_default = 25165824</span><br></span><span><span>net.core.rmem_default = 25165824</span><br></span><span><span></span><br></span><span><span># Maximum amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span># This will significantly increase performance for large transfers.</span><br></span><span><span>net.core.wmem_max = 25165824</span><br></span><span><span>net.core.rmem_max = 25165824</span><br></span><span><span></span><br></span><span><span># In addition to the socket settings, the send and receive buffer sizes for</span><br></span><span><span># TCP sockets must be set separately using the net.ipv4.tcp_wmem and net.ipv4.tcp_rmem parameters.</span><br></span><span><span># These are set using three space-separated integers that specify the minimum, default, and maximum sizes, respectively.</span><br></span><span><span># The maximum size cannot be larger than the values specified for all sockets using net.core.wmem_max and net.core.rmem_max.</span><br></span><span><span># A reasonable setting is a 4 KiB minimum, 64 KiB default, and 2 MiB maximum buffer.</span><br></span><span><span>net.ipv4.tcp_wmem = 20480 12582912 25165824</span><br></span><span><span>net.ipv4.tcp_rmem = 20480 12582912 25165824</span><br></span><span><span></span><br></span><span><span># Increase the maximum total buffer-space allocatable</span><br></span><span><span># This is measured in units of pages (4096 bytes)</span><br></span><span><span>net.ipv4.tcp_mem = 65536 25165824 262144</span><br></span><span><span>net.ipv4.udp_mem = 65536 25165824 262144</span><br></span><span><span></span><br></span><span><span># Minimum amount of memory allocated for the send and receive buffers for each socket.</span><br></span><span><span>net.ipv4.udp_wmem_min = 16384</span><br></span><span><span>net.ipv4.udp_rmem_min = 16384</span><br></span><span><span></span><br></span><span><span># Enabling TCP window scaling by setting net.ipv4.tcp_window_scaling to 1 will allow</span><br></span><span><span># clients to transfer data more efficiently, and allow that data to be buffered on the broker side.</span><br></span><span><span>net.ipv4.tcp_window_scaling = 1</span><br></span><span><span></span><br></span><span><span># Increasing the value of net.ipv4.tcp_max_syn_backlog above the default of 1024 will allow</span><br></span><span><span># a greater number of simultaneous connections to be accepted.</span><br></span><span><span>net.ipv4.tcp_max_syn_backlog = 10240</span><br></span><span><span></span><br></span><span><span># Increasing the value of net.core.netdev_max_backlog to greater than the default of 1000</span><br></span><span><span># can assist with bursts of network traffic, specifically when using multigigabit network connection speeds,</span><br></span><span><span># by allowing more packets to be queued for the kernel to process them.</span><br></span><span><span>net.core.netdev_max_backlog = 65536</span><br></span><span><span></span><br></span><span><span># Increase the maximum amount of option memory buffers</span><br></span><span><span>net.core.optmem_max = 25165824</span><br></span><span><span></span><br></span><span><span># Number of times SYNACKs for passive TCP connection.</span><br></span><span><span>net.ipv4.tcp_synack_retries = 2</span><br></span><span><span></span><br></span><span><span># Allowed local port range.</span><br></span><span><span>net.ipv4.ip_local_port_range = 2048 65535</span><br></span><span><span></span><br></span><span><span># Protect Against TCP Time-Wait</span><br></span><span><span># Default: net.ipv4.tcp_rfc1337 = 0</span><br></span><span><span>net.ipv4.tcp_rfc1337 = 1</span><br></span><span><span></span><br></span><span><span># Decrease the time default value for tcp_fin_timeout connection</span><br></span><span><span>net.ipv4.tcp_fin_timeout = 15</span><br></span><span><span></span><br></span><span><span># The maximum number of backlogged sockets.</span><br></span><span><span># Default is 128.</span><br></span><span><span>net.core.somaxconn = 4096</span><br></span><span><span></span><br></span><span><span># Turn on syncookies for SYN flood attack protection.</span><br></span><span><span>net.ipv4.tcp_syncookies = 1</span><br></span><span><span></span><br></span><span><span># Avoid a smurf attack</span><br></span><span><span>net.ipv4.icmp_echo_ignore_broadcasts = 1</span><br></span><span><span></span><br></span><span><span># Turn on protection for bad icmp error messages</span><br></span><span><span>net.ipv4.icmp_ignore_bogus_error_responses = 1</span><br></span><span><span></span><br></span><span><span># Enable automatic window scaling.</span><br></span><span><span># This will allow the TCP buffer to grow beyond its usual maximum of 64K if the latency justifies it.</span><br></span><span><span>net.ipv4.tcp_window_scaling = 1</span><br></span><span><span></span><br></span><span><span># Turn on and log spoofed, source routed, and redirect packets</span><br></span><span><span>net.ipv4.conf.all.log_martians = 1</span><br></span><span><span>net.ipv4.conf.default.log_martians = 1</span><br></span><span><span></span><br></span><span><span># Tells the kernel how many TCP sockets that are not attached to any</span><br></span><span><span># user file handle to maintain. In case this number is exceeded,</span><br></span><span><span># orphaned connections are immediately reset and a warning is printed.</span><br></span><span><span># Default: net.ipv4.tcp_max_orphans = 65536</span><br></span><span><span>net.ipv4.tcp_max_orphans = 65536</span><br></span><span><span></span><br></span><span><span># Do not cache metrics on closing connections</span><br></span><span><span>net.ipv4.tcp_no_metrics_save = 1</span><br></span><span><span></span><br></span><span><span># Enable timestamps as defined in RFC1323:</span><br></span><span><span># Default: net.ipv4.tcp_timestamps = 1</span><br></span><span><span>net.ipv4.tcp_timestamps = 1</span><br></span><span><span></span><br></span><span><span># Enable select acknowledgments.</span><br></span><span><span># Default: net.ipv4.tcp_sack = 1</span><br></span><span><span>net.ipv4.tcp_sack = 1</span><br></span><span><span></span><br></span><span><span># Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks.</span><br></span><span><span># net.ipv4.tcp_tw_recycle has been removed from Linux 4.12. Use net.ipv4.tcp_tw_reuse instead.</span><br></span><span><span>net.ipv4.tcp_max_tw_buckets = 1440000</span><br></span><span><span>net.ipv4.tcp_tw_reuse = 1</span><br></span><span><span></span><br></span><span><span># The accept_source_route option causes network interfaces to accept packets with the Strict Source Route (SSR) or Loose Source Routing (LSR) option set. </span><br></span><span><span># The following setting will drop packets with the SSR or LSR option set.</span><br></span><span><span>net.ipv4.conf.all.accept_source_route = 0</span><br></span><span><span>net.ipv4.conf.default.accept_source_route = 0</span><br></span><span><span></span><br></span><span><span># Turn on reverse path filtering</span><br></span><span><span>net.ipv4.conf.all.rp_filter = 1</span><br></span><span><span>net.ipv4.conf.default.rp_filter = 1</span><br></span><span><span></span><br></span><span><span># Disable ICMP redirect acceptance</span><br></span><span><span>net.ipv4.conf.all.accept_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.accept_redirects = 0</span><br></span><span><span>net.ipv4.conf.all.secure_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.secure_redirects = 0</span><br></span><span><span></span><br></span><span><span># Disables sending of all IPv4 ICMP redirected packets.</span><br></span><span><span>net.ipv4.conf.all.send_redirects = 0</span><br></span><span><span>net.ipv4.conf.default.send_redirects = 0</span><br></span><span><span></span><br></span><span><span># Disable IPv6</span><br></span><span><span>net.ipv6.conf.all.disable_ipv6 = 1</span><br></span><span><span>net.ipv6.conf.default.disable_ipv6 = 1</span><br></span><span><span></span><br></span><span><span>#############################################################################################</span><br></span><span><span># Kubernetes related settings</span><br></span><span><span>#############################################################################################</span><br></span><span><span></span><br></span><span><span># Enable IP forwarding.</span><br></span><span><span># IP forwarding is the ability for an operating system to accept incoming network packets on one interface,</span><br></span><span><span># recognize that it is not meant for the system itself, but that it should be passed on to another network, and then forwards it accordingly.</span><br></span><span><span>net.ipv4.ip_forward = 1</span><br></span><span><span></span><br></span><span><span># These settings control whether packets traversing a network bridge are processed by iptables rules on the host system.</span><br></span><span><span>net.bridge.bridge-nf-call-iptables = 1</span><br></span><span><span>net.bridge.bridge-nf-call-ip6tables = 1</span><br></span><span><span></span><br></span><span><span># To prevent Linux conntrack table is out of space, increase the conntrack table size.</span><br></span><span><span># This setting is for Calico networking.</span><br></span><span><span>net.netfilter.nf_conntrack_max = 1000000</span><br></span><span><span></span><br></span><span><span>#############################################################################################</span><br></span><span><span># Tweak kernel parameters</span><br></span><span><span>#############################################################################################</span><br></span><span><span></span><br></span><span><span># Address Space Layout Randomization (ASLR) is a memory-protection process for operating systems that guards against buffer-overflow attacks.</span><br></span><span><span># It helps to ensure that the memory addresses associated with running processes on systems are not predictable,</span><br></span><span><span># thus flaws or vulnerabilities associated with these processes will be more difficult to exploit.</span><br></span><span><span># Accepted values: 0 = Disabled, 1 = Conservative Randomization, 2 = Full Randomization</span><br></span><span><span>kernel.randomize_va_space = 2</span><br></span><span><span></span><br></span><span><span># Allow for more PIDs (to reduce rollover problems)</span><br></span><span><span>kernel.pid_max = 65536</span><br></span><span><span>EOF</span><br></span>
```

4.1.13. Reload all _sysctl_ variables without rebooting the server.

4.1.14. Create Local DNS records.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/hosts </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span># localhost</span><br></span><span><span>127.0.0.1     localhost        localhost.localdomain</span><br></span><span><span></span><br></span><span><span># When DNS records are updated in the DNS server, remove these entries.</span><br></span><span><span>192.168.16.80  kube-api.example.local</span><br></span><span><span>192.168.16.102 kubemaster01  kubemaster01.example.local</span><br></span><span><span>192.168.16.103 kubemaster02  kubemaster02.example.local</span><br></span><span><span>192.168.16.104 kubemaster03  kubemaster03.example.local</span><br></span><span><span>192.168.16.105 kubeworker01  kubeworker01.example.local</span><br></span><span><span>192.168.16.106 kubeworker02  kubeworker02.example.local</span><br></span><span><span>192.168.16.107 kubeworker03  kubeworker03.example.local</span><br></span><span><span>EOF</span><br></span>
```

4.1.15. Configure _NetworkManager_ before attempting to use Calico networking.

```
<span><span># Create the following configuration file to prevent NetworkManager from interfering with the interfaces</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/NetworkManager/conf.d/calico.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>[keyfile]</span><br></span><span><span>unmanaged-devices=interface-name:cali*;interface-name:tunl*</span><br></span><span><span>EOF</span><br></span>
```

4.1.16. The servers need to be restarted before continue further.

4.1.17. Configure _CRI-O_ Container Runtime Interface repositories.

info

Note: The CRI-O major and minor versions must match the Kubernetes major and minor versions. For more information, see the [CRI-O compatibility matrix](https://github.com/cri-o/cri-o).

```
<span><span># Set environment variables according to the operating system and Kubernetes version</span><span></span><br></span><span><span></span><span>OS</span><span>=</span><span>CentOS_8</span><br></span><span><span></span><span>VERSION</span><span>=</span><span>1.19</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Configure YUM repositories</span><span></span><br></span><span><span></span><span>curl</span><span> -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/</span><span>$OS</span><span>/devel:kubic:libcontainers:stable.repo</span><br></span><span><span></span><span>curl</span><span> -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:</span><span>$VERSION</span><span>.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:</span><span>$VERSION</span><span>/</span><span>$OS</span><span>/devel:kubic:libcontainers:stable:cri-o:</span><span>$VERSION</span><span>.repo</span><br></span>
```

4.1.18. Install _CRI-O_ package.

```
<span><span># Install cri-o package</span><span></span><br></span><span><span>dnf </span><span>install</span><span> -y cri-o</span><br></span>
```

4.1.19. Start and enable CRI-O service.

```
<span><span># Start and enable crio service</span><span></span><br></span><span><span>systemctl </span><span>enable</span><span> --now crio</span><br></span><span><span></span><br></span><span><span></span><span># Check if the crio service is running</span><span></span><br></span><span><span>systemctl status crio</span><br></span>
```

4.1.20. Add Kubernetes repository.

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/yum.repos.d/kubernetes.repo </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>[kubernetes]</span><br></span><span><span>name=Kubernetes</span><br></span><span><span>baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64</span><br></span><span><span>enabled=1</span><br></span><span><span>gpgcheck=1</span><br></span><span><span>repo_gpgcheck=1</span><br></span><span><span>gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg</span><br></span><span><span>       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg</span><br></span><span><span>exclude=kubelet kubeadm kubectl</span><br></span><span><span>EOF</span><br></span>
```

4.1.21. Install _kubeadm_, _kubelet_ and _kubectl_ packages.

```
<span><span>dnf </span><span>install</span><span> -y --disableexcludes</span><span>=</span><span>kubernetes kubelet-1.19* kubeadm-1.19* kubectl-1.19*</span><br></span>
```

4.1.22. Configure runtime cgroups used by _kubelet_ service.

```
<span><span># Configure runtime cgroups used by kubelet</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/sysconfig/kubelet </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>KUBELET_EXTRA_ARGS="--runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice"</span><br></span><span><span>EOF</span><br></span>
```

4.1.23. Enable _kubelet_ service.

4.1.24. Pull latest docker images used by kubeadm.

```
<span><span>kubeadm config images pull</span><br></span>
```

### 4.2. Configure **MASTER** nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#42-configure-master-nodes "Direct link to 42-configure-master-nodes")

#### 4.2.1. Prepare Master Nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#421-prepare-master-nodes "Direct link to 4.2.1. Prepare Master Nodes")

4.2.1.1. Open necessary firewall ports used by Kubernetes.

```
<span><span># Open necessary firewall ports</span><span></span><br></span><span><span>firewall-cmd --zone</span><span>=</span><span>public --permanent --add-port</span><span>=</span><span>{</span><span>6443,2379</span><span>,2380,10250,10251,10252</span><span>}</span><span>/tcp</span><br></span><span><span></span><br></span><span><span></span><span># Allow docker access from another node</span><span></span><br></span><span><span>firewall-cmd --zone</span><span>=</span><span>public --permanent --add-rich-rule </span><span>'rule family=ipv4 source address=192.168.16.0/24 accept'</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Apply firewall changes</span><span></span><br></span><span><span>firewall-cmd --reload</span><br></span>
```

#### 4.2.2. Configure the First Master Node (**kubemaster01**)[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#422-configure-the-first-master-node-kubemaster01 "Direct link to 422-configure-the-first-master-node-kubemaster01")

4.2.2.1. Create the **kubeadm** config file.

info

Please make sure to change **controlPlaneEndpoint** value as appropriate

```
<span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> </span><span>sudo</span><span> </span><span>tee</span><span> /etc/kubernetes/kubeadm.conf </span><span>&gt;</span><span> /dev/null</span><span></span><br></span><span><span>---</span><br></span><span><span>apiServer:</span><br></span><span><span>apiVersion: kubeadm.k8s.io/v1beta2</span><br></span><span><span>certificatesDir: /etc/kubernetes/pki</span><br></span><span><span>clusterName: kubernetes</span><br></span><span><span>controlPlaneEndpoint: kube-api.example.local:6443</span><br></span><span><span>dns:</span><br></span><span><span>  type: CoreDNS</span><br></span><span><span>etcd:</span><br></span><span><span>  local:</span><br></span><span><span>    dataDir: /var/lib/etcd</span><br></span><span><span>imageRepository: k8s.gcr.io</span><br></span><span><span>kind: ClusterConfiguration</span><br></span><span><span>networking:</span><br></span><span><span>  dnsDomain: example.local</span><br></span><span><span>  podSubnet: 192.168.0.0/16</span><br></span><span><span>  serviceSubnet: 10.96.0.0/12</span><br></span><span><span>---</span><br></span><span><span>apiVersion: kubelet.config.k8s.io/v1beta1</span><br></span><span><span>kind: KubeletConfiguration</span><br></span><span><span>cgroupDriver: "systemd"</span><br></span><span><span>EOF</span><br></span>
```

4.2.2.2. Initialize the first control plane.

```
<span><span>kubeadm init </span><span>\</span><span></span><br></span><span><span>    --config /etc/kubernetes/kubeadm.conf </span><span>\</span><span></span><br></span><span><span>    --upload-certs </span><span>\</span><span></span><br></span><span><span>    --v</span><span>=</span><span>5</span><br></span>
```

> #### You will get an output like this. Please make sure to record **MASTER** and **WORKER** join commands.[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#you-will-get-an-output-like-this-please-make-sure-to-record-master-and-worker-join-commands "Direct link to you-will-get-an-output-like-this-please-make-sure-to-record-master-and-worker-join-commands")
> 
> Your Kubernetes control-plane has initialized successfully!
> 
> To start using your cluster, you need to run the following as a regular user:
> 
> mkdir -p $HOME/.kube  
> sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config  
> sudo chown $(id -u):$(id -g) $HOME/.kube/config
> 
> You should now deploy a pod network to the cluster. Run "kubectl apply -f \[podnetwork\].yaml" with one of the options listed at: [https://kubernetes.io/docs/concepts/cluster-administration/addons/](https://kubernetes.io/docs/concepts/cluster-administration/addons/)
> 
> You can now join any number of the control-plane node running the following command on each as root:
> 
> kubeadm join kube-api.example.local:6443 --token ti2ho7.t146llqa4sn8y229 \\  
> \--discovery-token-ca-cert-hash sha256:9e73a021b8b26c8a2fc04939729acc7670769f15469887162cdbae923df906f9 \\  
> \--control-plane --certificate-key d9d631a0aef1a5a474faa6787b54814040adf1012c6c1922e8fe096094547b65 \\  
> \--v=5
> 
> Please note that the certificate-key gives access to cluster sensitive data, keep it secret! As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use "kubeadm init phase upload-certs --upload-certs" to reload certs afterward.
> 
> Then you can join any number of worker nodes by running the following on each as root:
> 
> kubeadm join kube-api.example.local:6443 --token ti2ho7.t146llqa4sn8y229 \\  
> \--discovery-token-ca-cert-hash sha256:9e73a021b8b26c8a2fc04939729acc7670769f15469887162cdbae923df906f9 \\  
> \--v=5

4.2.2.3. To start using kubectl, you need to run the following command.

```
<span><span>mkdir</span><span> -p </span><span>$HOME</span><span>/.kube</span><br></span><span><span></span><span>sudo</span><span> </span><span>cp</span><span> -i /etc/kubernetes/admin.conf </span><span>$HOME</span><span>/.kube/config</span><br></span><span><span></span><span>sudo</span><span> </span><span>chown</span><span> </span><span>$(</span><span>id</span><span> -u</span><span>)</span><span>:</span><span>$(</span><span>id</span><span> -g</span><span>)</span><span> </span><span>$HOME</span><span>/.kube/config</span><br></span>
```

4.2.2.4. Install calico CNI-plugin.

```
<span><span># Install calico CNI-plugin</span><span></span><br></span><span><span>kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml</span><br></span>
```

4.2.2.5. Check _NetworkReady_ status. It must be **TRUE**. If not, wait some time and check it again.

```
<span><span># Check NetworkReady status</span><span></span><br></span><span><span></span><span>watch</span><span> crictl info</span><br></span>
```

4.2.2.6. Watch the ods created in the _kube-system_ namespace and make sure all are running.

```
<span><span># Watch the Pods created in the kube-system namespace</span><span></span><br></span><span><span></span><span>watch</span><span> kubectl get pods --namespace kube-system</span><br></span>
```

4.2.2.7. Check master node status.

```
<span><span># Check master node status</span><span></span><br></span><span><span>kubectl get nodes -o wide</span><br></span>
```

#### 4.2.3. Configure other master nodes (**kubemaster02** and **kubemaster03**).[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#423-configure-other-master-nodes-kubemaster02-and-kubemaster03 "Direct link to 423-configure-other-master-nodes-kubemaster02-and-kubemaster03")

info

-   Make sure to join other master nodes **ONE BY ONE** when the **kubemaster01** status becomes **READY**.
    
-   Before execute the _kubectl join_ command, make sure to verify all pods are up and running using `kubectl get po,svc --all-namespaces`.
    
-   Use `--v=5` argument with _kubeadm join_ in order to get a verbose output.
    

4.2.3.1. Execute the **control-plane join** command recorded in step _**4.2.2.2**_.

```
<span><span># Control plane join command example:</span><span></span><br></span><span><span>kubeadm </span><span>join</span><span> kube-api.example.local:6443 --token ti2ho7.t146llqa4sn8y229 </span><span>\</span><span></span><br></span><span><span>    --discovery-token-ca-cert-hash sha256:9e73a021b8b26c8a2fc04939729acc7670769f15469887162cdbae923df906f9 </span><span>\</span><span></span><br></span><span><span>    --control-plane --certificate-key d9d631a0aef1a5a474faa6787b54814040adf1012c6c1922e8fe096094547b65 </span><span>\</span><span></span><br></span><span><span>    --v</span><span>=</span><span>5</span><br></span>
```

4.2.3.2. To start using kubectl, you need to run the following command.

```
<span><span>mkdir</span><span> -p </span><span>$HOME</span><span>/.kube</span><br></span><span><span></span><span>sudo</span><span> </span><span>cp</span><span> -i /etc/kubernetes/admin.conf </span><span>$HOME</span><span>/.kube/config</span><br></span><span><span></span><span>sudo</span><span> </span><span>chown</span><span> </span><span>$(</span><span>id</span><span> -u</span><span>)</span><span>:</span><span>$(</span><span>id</span><span> -g</span><span>)</span><span> </span><span>$HOME</span><span>/.kube/config</span><br></span>
```

4.2.3.3. Check master node status.

```
<span><span># Check master node status</span><span></span><br></span><span><span>kubectl get nodes -o wide</span><br></span>
```

### 4.3. Configure **WORKER** nodes[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#43-configure-worker-nodes "Direct link to 43-configure-worker-nodes")

info

-   Make sure to join worker nodes **ONE BY ONE** when the **MASTER** nodes status becomes **READY**.
    
-   Before execute the _kubectl join_ command on worker nodes, make sure to verify all pods are up and running on master nodes using `kubectl get po,svc --all-namespaces`.
    
-   Use `--v=5` argument with _kubeadm join_ in order to get a verbose output.
    

4.3.1. Open necessary firewall ports used by Kubernetes.

```
<span><span># Open necessary firewall ports</span><span></span><br></span><span><span>firewall-cmd --zone</span><span>=</span><span>public --permanent --add-port</span><span>=</span><span>{</span><span>10250,30000</span><span>-32767</span><span>}</span><span>/tcp</span><br></span><span><span></span><br></span><span><span></span><span># Apply firewall changes</span><span></span><br></span><span><span>firewall-cmd --reload</span><br></span>
```

4.3.2. Execute the **worker nodes join** command recorded in step _**4.2.2.2**_.

```
<span><span># Worker node join command example:</span><span></span><br></span><span><span>kubeadm </span><span>join</span><span> kube-api.example.local:6443 --token ti2ho7.t146llqa4sn8y229 </span><span>\</span><span></span><br></span><span><span>    --discovery-token-ca-cert-hash sha256:9e73a021b8b26c8a2fc04939729acc7670769f15469887162cdbae923df906f9 </span><span>\</span><span></span><br></span><span><span>    --v</span><span>=</span><span>5</span><br></span>
```

### 4.4. Configure **MetalLB Load Balancer**[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#44-configure-metallb-load-balancer "Direct link to 44-configure-metallb-load-balancer")

info

-   You **MUST** execute these commands on a **MASTER** node.
    
-   Make sure to follow these steps only when the both **MASTER** and **WORKER** nodes status becomes **READY**.
    
-   Make sure to execute `kubectl get po,svc --all-namespaces` on a master node and verify all pods are up and running.
    

4.4.1. Install MetalLB Load Balancer.

```
<span><span># Install MetalLB Load Balancer</span><span></span><br></span><span><span>kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml</span><br></span>
```

4.4.2. Create MetalLB ConfigMap.

```
<span><span># Create MetalLB ConfigMap</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> kubectl apply -f -</span><span></span><br></span><span><span>apiVersion: v1</span><br></span><span><span>kind: ConfigMap</span><br></span><span><span>metadata:</span><br></span><span><span>  namespace: metallb-system</span><br></span><span><span>  name: config</span><br></span><span><span>data:</span><br></span><span><span>  config: |</span><br></span><span><span>    address-pools:</span><br></span><span><span>    - name: default</span><br></span><span><span>      protocol: layer2</span><br></span><span><span></span><br></span><span><span>      # MetalLB IP Pool</span><br></span><span><span>      addresses:</span><br></span><span><span>      - 192.168.16.200-192.168.16.250</span><br></span><span><span>EOF</span><br></span>
```

4.4.3. Watch the Pods created in the _metallb-system_ namespace and make sure all are running.

```
<span><span># Watch the Pods created in the metallb-system namespace</span><span></span><br></span><span><span></span><span>watch</span><span> kubectl get pods --namespace metallb-system</span><br></span>
```

note

If you want to change the MetalLB IP Pool, please follow these steps.

1.  Note the old IPs allocated to services.
    
    ```
    <span><span>kubectl get svc --all-namespaces</span><br></span>
    ```
    
2.  Delete the old ConfigMap.
    
    ```
    <span><span>kubectl -n metallb-system delete cm config</span><br></span>
    ```
    
3.  Apply the new ConfigMap
    
    ```
    <span><span>cat &lt;&lt;EOF | kubectl apply -f -</span><br></span><span><span>apiVersion: v1</span><br></span><span><span>kind: ConfigMap</span><br></span><span><span>metadata:</span><br></span><span><span>  namespace: metallb-system</span><br></span><span><span>  name: config</span><br></span><span><span>data:</span><br></span><span><span>  config: |</span><br></span><span><span>    address-pools:</span><br></span><span><span>    - name: default</span><br></span><span><span>      protocol: layer2</span><br></span><span><span></span><br></span><span><span>      # MetalLB IP Pool</span><br></span><span><span>      addresses:</span><br></span><span><span>      - 192.168.16.150-192.168.16.175</span><br></span><span><span>EOF</span><br></span>
    ```
    
4.  Delete the existing MetalLB pods.
    
    ```
    <span><span>kubectl -n metallb-system delete pod --all</span><br></span>
    ```
    
5.  New MetalLB pods will be created automatically. Please make sure the pods are running.
    
    ```
    <span><span>kubectl -n metallb-system get pods</span><br></span>
    ```
    
6.  Inspect new IPs of services.
    
    ```
    <span><span>kubectl get svc --all-namespaces</span><br></span>
    ```
    

### 4.5. Configure **Kubernetes Dashboard**[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#45-configure-kubernetes-dashboard "Direct link to 45-configure-kubernetes-dashboard")

info

-   You **MUST** execute these commands on a **MASTER** node.
    
-   Make sure to follow these steps only when the both **MASTER** and **WORKER** nodes status becomes **READY**.
    
-   Make sure to execute `kubectl get po,svc --all-namespaces` on a master node and verify all pods are up and running.
    

4.5.1. Install Kubernetes Dashboard.

```
<span><span># Install Kubernetes Dashboard</span><span></span><br></span><span><span>kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc6/aio/deploy/recommended.yaml</span><br></span>
```

4.5.2. Create the Dashboard service account.

```
<span><span># Create the Dashboard service account</span><span></span><br></span><span><span></span><span># This will create a service account named dashboard-admin in the default namespace</span><span></span><br></span><span><span>kubectl create serviceaccount dashboard-admin --namespace kubernetes-dashboard</span><br></span>
```

4.5.3. Bind the dashboard-admin service account to the cluster-admin role.

```
<span><span># Bind the dashboard-admin service account to the cluster-admin role</span><span></span><br></span><span><span>kubectl create clusterrolebinding dashboard-admin --clusterrole</span><span>=</span><span>cluster-admin </span><span>\</span><span></span><br></span><span><span>    --serviceaccount</span><span>=</span><span>kubernetes-dashboard:dashboard-admin</span><br></span>
```

4.5.4. When we created the **dashboard-admin** service account, Kubernetes also created a secret for it. List secrets using the following command.

```
<span><span># When we created the dashboard-admin service account Kubernetes also created a secret for it.</span><span></span><br></span><span><span></span><span># List secrets using:</span><span></span><br></span><span><span>kubectl get secrets --namespace kubernetes-dashboard</span><br></span>
```

4.5.5. Get **Dashboard Access Token**.

```
<span><span># We can see the dashboard-admin-sa service account secret in the above command output.</span><span></span><br></span><span><span></span><span># Use kubectl describe to get the access token:</span><span></span><br></span><span><span>kubectl describe --namespace kubernetes-dashboard secret dashboard-admin-token</span><br></span>
```

4.5.6. Watch Pods and Service accounts under kubernetes-dashboard namespace.

```
<span><span># Watch Pods and Service accounts under kubernetes-dashboard</span><span></span><br></span><span><span></span><span>watch</span><span> kubectl get po,svc --namespace kubernetes-dashboard</span><br></span>
```

4.5.7. Get logs of kubernetes-dashboard.

```
<span><span># Get logs of kubernetes-dashboard</span><span></span><br></span><span><span>kubectl logs --follow --namespace kubernetes-dashboard deployment/kubernetes-dashboard</span><br></span>
```

4.5.8. Create kubernetes-dashboard load balancer.

```
<span><span># Create kubernetes-dashboard load balancer</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> kubectl apply -f -</span><span></span><br></span><span><span>apiVersion: v1</span><br></span><span><span>kind: Service</span><br></span><span><span>metadata:</span><br></span><span><span>  labels:</span><br></span><span><span>    app.kubernetes.io/name: load-balancer-dashboard</span><br></span><span><span>  name: dashboard-load-balancer</span><br></span><span><span>  namespace: kubernetes-dashboard</span><br></span><span><span>spec:</span><br></span><span><span>  ports:</span><br></span><span><span>    - port: 443</span><br></span><span><span>      protocol: TCP</span><br></span><span><span>      targetPort: 8443</span><br></span><span><span>  selector:</span><br></span><span><span>    k8s-app: kubernetes-dashboard</span><br></span><span><span>  type: LoadBalancer</span><br></span><span><span>EOF</span><br></span>
```

4.5.9. Get logs of kubernetes-dashboard.

```
<span><span># Get logs of kubernetes-dashboard</span><span></span><br></span><span><span>kubectl logs --follow --namespace kubernetes-dashboard deployment/kubernetes-dashboard</span><br></span>
```

4.5.10. Get kubernetes-dashboard **External IP**.

```
<span><span># Get kubernetes-dashboard external IP</span><span></span><br></span><span><span>kubectl get po,svc --namespace kubernetes-dashboard </span><span>|</span><span> </span><span>grep</span><span> -i service/dashboard-load-balancer</span><br></span>
```

### 4.6. Configure **ROOK-CEPH** Distributed Block Storage[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#46-configure-rook-ceph-distributed-block-storage "Direct link to 46-configure-rook-ceph-distributed-block-storage")

info

-   You **MUST** execute these commands on a **MASTER** node.
    
-   Make sure to follow these steps only when the both **MASTER** and **WORKER** nodes status becomes **READY**.
    
-   Make sure to execute `kubectl get po,svc --all-namespaces` on a master node and verify all pods are up and running.
    

4.6.1. Download and extract latest rook binaries.

```
<span><span># Download Rook 1.2.5</span><span></span><br></span><span><span></span><span>wget</span><span> -O /tmp/v1.2.6.tar.gz https://github.com/rook/rook/archive/v1.2.6.tar.gz</span><br></span><span><span></span><br></span><span><span></span><span># Extract it under /tmp/rook</span><span></span><br></span><span><span></span><span>mkdir</span><span> -p /tmp/rook </span><span>&amp;&amp;</span><span> </span><span>tar</span><span> xfz /tmp/v1.2.6.tar.gz -C /tmp/rook --strip-components </span><span>1</span><br></span>
```

4.6.2. Deploy all the resources needed by the Rook Ceph operator.

```
<span><span># Deploy all the resources needed by the Rook Ceph operator.</span><span></span><br></span><span><span></span><span># Those resources are mainly CustomRessourceDefinitions, also known as CRDs.</span><span></span><br></span><span><span></span><span># They are used to define new resources which will be used by the Operator.</span><span></span><br></span><span><span></span><span># The other resources created are mainly linked to the access rights so the Operator can communicate with the cluster API Server.</span><span></span><br></span><span><span>kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/common.yaml</span><br></span>
```

4.6.3. Deploy the Ceph operator that will be in charge of the setup and of the orchestration of a Ceph cluster.

```
<span><span># Deploy the Ceph operator that will be in charge of the setup</span><span></span><br></span><span><span></span><span># and of the orchestration of a Ceph cluster</span><span></span><br></span><span><span>kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/operator.yaml</span><br></span>
```

info

-   It takes about **10 minutes** for the operator to be up and running.
    
-   Its status can be verified using `watch kubectl get pod -n rook-ceph` command.
    
-   Once the operator is ready, it triggers the creation of a DaemonSet in charge of deploying a **rook-discover** agent on each worker node of the Kubernetes cluster.
    
-   Do **NOT** proceed further until both **rook-ceph-operator** and **rook-discover** pods are in **RUNNING** state.
    

4.6.4. Create Ceph cluster.

```
<span><span># Make sure to edit "nodes" section according to your environment configurations</span><span></span><br></span><span><span></span><span>cat</span><span> </span><span>&lt;&lt;</span><span>EOF</span><span> </span><span>|</span><span> kubectl create -f -</span><span></span><br></span><span><span>apiVersion: ceph.rook.io/v1</span><br></span><span><span>kind: CephCluster</span><br></span><span><span>metadata:</span><br></span><span><span>  name: rook-ceph</span><br></span><span><span>  namespace: rook-ceph</span><br></span><span><span>spec:</span><br></span><span><span>  cephVersion:</span><br></span><span><span>    image: ceph/ceph:v14.2.8</span><br></span><span><span>    allowUnsupported: false</span><br></span><span><span>  dataDirHostPath: /var/lib/rook</span><br></span><span><span>  skipUpgradeChecks: false</span><br></span><span><span>  continueUpgradeAfterChecksEvenIfNotHealthy: false</span><br></span><span><span>  mon:</span><br></span><span><span>    count: 3</span><br></span><span><span>    allowMultiplePerNode: false</span><br></span><span><span>  dashboard:</span><br></span><span><span>    enabled: true</span><br></span><span><span>    ssl: true</span><br></span><span><span>  monitoring:</span><br></span><span><span>    enabled: false</span><br></span><span><span>    rulesNamespace: rook-ceph</span><br></span><span><span>  network:</span><br></span><span><span>    hostNetwork: false</span><br></span><span><span>  rbdMirroring:</span><br></span><span><span>    workers: 0</span><br></span><span><span>  crashCollector:</span><br></span><span><span>    disable: false</span><br></span><span><span>  mgr:</span><br></span><span><span>    modules:</span><br></span><span><span>    - name: pg_autoscaler</span><br></span><span><span>      enabled: true</span><br></span><span><span>  removeOSDsIfOutAndSafeToRemove: true</span><br></span><span><span>  storage:</span><br></span><span><span>    useAllNodes: false</span><br></span><span><span>    useAllDevices: false</span><br></span><span><span>    # specific directories to use for storage</span><br></span><span><span>    directories:</span><br></span><span><span>    - path: "/var/lib/rook"</span><br></span><span><span>    # Each node's 'name' field should match their 'kubernetes.io/hostname' label</span><br></span><span><span>    nodes:</span><br></span><span><span>    - name: "kubeworker01"</span><br></span><span><span>    - name: "kubeworker02"</span><br></span><span><span>    - name: "kubeworker03"</span><br></span><span><span>  disruptionManagement:</span><br></span><span><span>    managePodBudgets: false</span><br></span><span><span>    osdMaintenanceTimeout: 30</span><br></span><span><span>    manageMachineDisruptionBudgets: false</span><br></span><span><span>    machineDisruptionBudgetNamespace: openshift-machine-api</span><br></span><span><span>EOF</span><br></span>
```

info

-   It takes about **15 minutes** for the cluster to be up and running.
    
-   Verify the cluster status using `watch kubectl get pod -n rook-ceph`.
    
-   Do **NOT** proceed further until all the Pods in the _rook-ceph_ namespace are in **RUNNING** state.
    
-   You can read **rook-ceph-operator** logs using `kubectl logs --follow --namespace rook-ceph --tail=100 -l app=rook-ceph-operator`.
    

4.6.5. Create a **ReplicaPool** and a **StorageClass** to automate the creation of a Kubernetes PersistentVolume backed-up by Ceph block storage.

```
<span><span># Specify the filesystem type of the volume</span><span></span><br></span><span><span></span><span>sed</span><span> -i </span><span>'s|csi.storage.k8s.io/fstype: ext4|csi.storage.k8s.io/fstype: xfs|g'</span><span> </span><span>\</span><span></span><br></span><span><span>    /tmp/rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml</span><br></span><span><span></span><br></span><span><span></span><span># Create a ReplicaPool and a StorageClass</span><span></span><br></span><span><span>kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml</span><br></span>
```

4.6.6. Install **Rook Toolbox**.

```
<span><span># Install rook toolbox</span><span></span><br></span><span><span>kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/toolbox.yaml</span><br></span><span><span></span><br></span><span><span></span><span># Verify rook toolbox pod is running</span><span></span><br></span><span><span>kubectl -n rook-ceph get pod -l </span><span>"app=rook-ceph-tools"</span><br></span>
```

4.6.7. To verify that the cluster is in a healthy state, connect to the _Rook Toolbox_ and run the _ceph status_ command.

```
<span><span># Connect to rook toolbox</span><span></span><br></span><span><span>kubectl -n rook-ceph </span><span>exec</span><span> -it </span><span>$(</span><span>kubectl -n rook-ceph get pod -l </span><span>"app=rook-ceph-tools"</span><span> -o </span><span>jsonpath</span><span>=</span><span>'{.items[0].metadata.name}'</span><span>)</span><span> </span><span>bash</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Execute the following commands inside the container</span><span></span><br></span><span><span></span><span>#</span><span></span><br></span><span><span></span><span># If the health is not HEALTH_OK, the warnings or errors should be investigated</span><span></span><br></span><span><span>ceph status</span><br></span><span><span></span><br></span><span><span></span><span># Check ceph osd status</span><span></span><br></span><span><span></span><span># ceph-osd is the object storage daemon for the Ceph distributed file system.</span><span></span><br></span><span><span></span><span># It is responsible for storing objects on a local file system and providing</span><span></span><br></span><span><span></span><span># access to them over the network</span><span></span><br></span><span><span>ceph osd status</span><br></span><span><span></span><br></span><span><span></span><span># Check a cluster's data usage and data distribution among pools</span><span></span><br></span><span><span>ceph </span><span>df</span><br></span>
```

4.6.8. Create **Ceph Dashboard** load balancer.

```
<span><span># Create ceph dashboard load balancer</span><span></span><br></span><span><span>kubectl create -f /tmp/rook/cluster/examples/kubernetes/ceph/dashboard-loadbalancer.yaml</span><br></span>
```

4.6.9. Access **Ceph Dashboard**.

```
<span><span># Find ceph-dashboard IP</span><span></span><br></span><span><span>kubectl get -n rook-ceph svc </span><span>|</span><span> </span><span>grep</span><span> rook-ceph-mgr-dashboard-loadbalancer</span><br></span><span><span></span><br></span><span><span></span><span># Find "admin" user password</span><span></span><br></span><span><span>kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o </span><span>jsonpath</span><span>=</span><span>"{['data']['password']}"</span><span> </span><span>|</span><span> base64 --decode </span><span>&amp;&amp;</span><span> </span><span>echo</span><br></span>
```

4.6.10. List Pods under rook-ceph namespace. It will take about **30 minutes** to get it ready.

```
<span><span># List Pods under rook-ceph namespace</span><span></span><br></span><span><span>kubectl -n rook-ceph get pod</span><br></span>
```

note

If you want to clean up the rook cluster, please follow ceph-teardown instructions [here](https://rook.io/docs/rook/v1.2/ceph-teardown.html).

### 4.7. Deploy a **Sample WordPress Blog**[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#47-deploy-a-sample-wordpress-blog "Direct link to 47-deploy-a-sample-wordpress-blog")

info

-   You **MUST** execute these commands on a **MASTER** node.
    
-   Make sure to follow these steps only when the both **MASTER** and **WORKER** nodes status becomes **READY**.
    
-   Make sure to execute `kubectl get po,svc --all-namespaces` on a master node and verify all pods are up and running.
    

4.7.1. Deploy a sample WordPress application using rook persistent volume claim.

```
<span><span># Create a MySQL container</span><span></span><br></span><span><span>kubectl create -f https://notebook.yasithab.com/gist/rook-ceph-mysql.yaml</span><br></span><span><span></span><br></span><span><span></span><span># Create an Apache WordPress container</span><span></span><br></span><span><span>kubectl create -f https://notebook.yasithab.com/gist/rook-ceph-wordpress.yaml</span><br></span>
```

### 4.8. Clean up Kubernates[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#48-clean-up-kubernates "Direct link to 4.8. Clean up Kubernates")

caution

-   The following commands are used to **RESET** your nodes and **WIPE OUT** all components installed.

4.8.1. Remove Kubernetes Components from Nodes

```
<span><span># The reset process does not clean CNI configuration. To do so, you must remove /etc/cni/net.d</span><span></span><br></span><span><span></span><span># The reset process does not reset or clean up iptables rules or IPVS tables.</span><span></span><br></span><span><span></span><span># If you wish to reset iptables, you must do so manually by using the "iptables" command.</span><span></span><br></span><span><span></span><span># If your cluster was setup to utilize IPVS, run ipvsadm --clear (or similar) to reset your system's IPVS tables.</span><span></span><br></span><span><span></span><br></span><span><span></span><span># Remove Kubernetes Components from Nodes</span><span></span><br></span><span><span>kubeadm reset --force</span><br></span><span><span></span><br></span><span><span></span><span># The reset process does not clean your kubeconfig files and you must remove them manually</span><span></span><br></span><span><span></span><span>rm</span><span> -rf </span><span>$HOME</span><span>/.kube/config</span><br></span>
```

4.8.2. Remove ROOK-CEPH data

info

-   This **MUST** be run on ALL **WORKER** nodes
-   You should perform this operation only after cleaning up Kubernates

```
<span><span># Remove rook data from worker nodes</span><span></span><br></span><span><span></span><span>rm</span><span> -rf /var/lib/rook</span><br></span>
```

## 5\. References[](https://blog.yasithab.com/centos/multi-master-kubernetes-cluster-setup-with-crio-and-ceph-block-storage-on-centos-8/#5-references "Direct link to 5. References")

1.  [Install and configure a multi-master Kubernetes cluster with kubeadm](http://dockerlabs.collabnix.com/kubernetes/beginners/Install-and-configure-a-multi-master-Kubernetes-cluster-with-kubeadm.html)
2.  [How to Deploy a HA Kubernetes Cluster with kubeadm on CentOS7](https://www.kubeclusters.com/docs/How-to-Deploy-a-Highly-Available-kubernetes-Cluster-with-Kubeadm-on-CentOS7)
3.  [Demystifying High Availability in Kubernetes Using Kubeadm](https://medium.com/velotio-perspectives/demystifying-high-availability-in-kubernetes-using-kubeadm-3d83ed8c458b)
4.  [Highly Available Control Plane with kubeadm](https://octetz.com/docs/2019/2019-03-26-ha-control-plane-kubeadm/)
5.  [Install and configure a multi-master Kubernetes cluster with kubeadm](https://blog.inkubate.io/install-and-configure-a-multi-master-kubernetes-cluster-with-kubeadm/)
6.  [HA Cluster vs. Backup/Restore](https://labs.consol.de/kubernetes/2018/05/25/kubeadm-backup.html)
7.  [Kubernetes HA Cluster installation guide](https://www.jordyverbeek.nl/nieuws/kubernetes-ha-cluster-installation-guide)
8.  [Creating Highly Available clusters with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability)
9.  [Deploy Kubernetes on vSphere](https://theithollow.com/2020/01/08/deploy-kubernetes-on-vsphere/)
10.  [vSphere Cloud Provider Configuration](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/existing.html)
11.  [Rook on Kubernetes](https://rook.io/docs/rook/v0.6/kubernetes.html)
12.  [Lab Guide - Kubernetes and Storage With the Vsphere Cloud Provider - Step by Step](https://www.definit.co.uk/2019/06/lab-guide-kubernetes-and-storage-with-the-vsphere-cloud-provider-step-by-step/)
13.  [Use vSphere Storage as Kubernetes persistent volumes](https://blog.inkubate.io/use-vsphere-storage-as-kubernetes-persistant-volumes/)
14.  [Dynamic Provisioning and StorageClass API](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/storageclass.html)
15.  [ROOK - Teardown Cluster](https://rook.io/docs/rook/v1.0/ceph-teardown.html)
16.  [What You Need to Know About MetalLB](https://www.objectif-libre.com/en/blog/2019/06/11/metallb/)
17.  [MetalLB Layer 2 Configuration](https://metallb.universe.tf/configuration/)
18.  [Bare-metal considerations](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/)
19.  [Kubernetes Ingress 101: NodePort, Load Balancers, and Ingress Controllers](https://blog.getambassador.io/kubernetes-ingress-nodeport-load-balancers-and-ingress-controllers-6e29f1c44f2d)
20.  [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
21.  [Kubernetes Storage on vSphere 101 – Failure Scenarios](https://cormachogan.com/2019/06/18/kubernetes-storage-on-vsphere-101-failure-scenarios/)
22.  [Moving a Stateful App from VCP to CSI based Kubernetes cluster using Velero](https://cormachogan.com/2019/10/10/moving-a-stateful-app-from-vcp-to-csi-based-kubernetes-cluster-using-velero/)
23.  [Verifying that DNS is working correctly within your Kubernetes platform](https://www.ibm.com/support/knowledgecenter/en/SSYGQH_6.0.0/admin/install/cp_prereq_kubernetes_dns.html)
24.  [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
25.  [CRI-O](https://cri-o.io/)
26.  [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes)
27.  [CRI-O as a replacement for Docker](https://prog.world/cri-o-as-a-replacement-for-docker-as-the-runtime-for-kubernetes-setting-up-on-centos-8)
28.  [How to install Kubernetes cluster on CentOS 8](https://upcloud.com/community/tutorials/install-kubernetes-cluster-centos-8)