# НАСТРОЙКА РОУТИНГА МЕЖДУ МАРШУРТИЗАТОРОАМИ И ASA.
## НЕ ЗАБЫВАЕМ, ЧТО NAT - НАХУЙ НЕ НУЖЕН!
### Делаем обычный маршрут со стороны маршрутизатора:
`ip route <адрес_сети_куда_хотим> <маска> [Крайний порт, ИЛИ ip, что смотрит на нас!` 
### проверяем пинги, должны быть.

# ЕСЛИ ОНИ РЕАЛЬНО ЕБАНУЛИСЬ, ТО ДЕЛАЕМ ЭТО:
***
Шаг 1 настройка Interesting Traffic
### 192_168_6_1

`ip access-list extended VPN-TO-SPB`
 `permit ip 192.168.6.0 0.0.0.255 192.168.53.0 0.0.0.255`
### SPB-ASA

` access-list VPN-TO-BAU extended permit ip 192.168.53.0 255.255.255.0 192.168.6.0 255.255.255.0` 
## NAT Exclusion
### 192_168_6_1

ip access-list extended acl_nat_rules
 deny   ip 192.168.6.0 0.0.0.255 192.168.0.0 0.0.255.255
 permit ip 192.168.6.0 0.0.0.255 any
ip nat inside source list acl_nat_rules interface FastEthernet8 overload
### SPB-ASA

object network LAN
 subnet 192.168.53.0 255.255.255.0
object network REMOTE_VPN
 subnet 192.168.0.0 255.255.0.0
nat (inside,outside) source static LAN LAN destination static REMOTE_VPN REMOTE_VPN route-lookup
## Шаг 2 настройка Phase 1 (ISAKMP - ikev1)
### 192_168_6_1

crypto isakmp policy 20
 authentication pre-share
 encryption aes 256
 hash sha
 group 5
 lifetime 86400
### SPB-ASA

`crypto ikev1 enable outside`
`crypto ikev1 policy 5`
` authentication pre-share`
` encryption aes-256`
` hash sha`
` group 5`
 `lifetime 86400`
Определяем tunnel-group и её аналог на Router
### 192_168_6_1

`crypto keyring SPBVPNKEY`
 `pre-shared-key address 84.52.78.112 key secresskey1`
`crypto isakmp profile staticL2L`
 `keyring SPBVPNKEY`
 `match identity address 84.52.78.112 255.255.255.255`
 
### SPB-ASA
`tunnel-group 62.117.66.194 type ipsec-l2l`
`tunnel-group 62.117.66.194 ipsec-attributes`
 `ikev1 pre-shared-key secresskey1`
 
## Шаг 3 настройка Phase 2 (IPSEc)
### 192_168_6_1

`crypto ipsec transform-set ESP-AES-256 esp-aes 256 esp-sha-hmac`
!
`crypto map outside_map 10 ipsec-isakmp`
 `set peer 84.52.78.112`
 `set transform-set ESP-AES-256`
` set isakmp-profile staticL2L`
` match address VPN-TO-SPB`
!
`interface FastEthernet8`
` crypto map outside_map`
### SPB-ASA

`crypto map outside_map 200 match address VPN-TO-BAU`
`crypto map outside_map 200 set peer 62.117.66.194`
`crypto map outside_map 200 set ikev1 transform-set ESP-AES-256-SHA`
`crypto map outside_map interface outside`
Проверка
Для проверки прямо с устройств Policy based routing требует пинговать с заданием source.
К сожалению ASA не умеет пинговать с заданием Source, поэтому проверять будет на роутере.

Также по умолчанию ASA не позволяет пинговать свой внутренний интерфейс со стороны VPN. Но эту проблему решить можно:
проследить что прописано route-lookup на ASA в NAT Exception:

`nat (inside,outside) source static LAN LAN destination static REMOTE_VPN REMOTE_VPN route-lookup`
Дать команду:

`management-access inside`
Проверяем пинг от роутера:

Проверяем пинг от роутера:
` ping 192.168.53.23 source 192.168.6.1 `
необходимо время для построения туннеля IPSec.
Проверяем ike:
`show crypto isakmp sa`
Здесь находим нас интересующие пару адресов. Если показывает QM_IDLE - значит всё нормально.
И наконец можно проверить что трафик успешно шифруется:
`show crypto ipsec sa peer 84.52.78.112`
Счетчики #pkts encrypt и #pkts decrypt должны увеличиваться.
