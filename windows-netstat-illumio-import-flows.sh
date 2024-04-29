#windows-netstat-illumio-import-flows.sh
#https://github.com/code7a/windows-netstat-illumio-import-flows
#
#Licensed under the Apache License, Version 2.0 (the "License"); you may not
#use this file except in compliance with the License. You may obtain a copy of
#the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#License for the specific language governing permissions and limitations under
#the License.
#
#version="0.0.1"
#
#This script executes a netstat command, with the numerical form parameter, then imports the flows into illumio via the agent bulk traffic flows api.
#Intended for legacy unsupported operating systems, such as Windows Server 2003.
#
#Dependencies:
#illumio.config file with illumio variables
#Example:
#export user=api_135450a1288aa3466
#export key=55182a5fa20f04faa12345678921507aa55c3bab65f1234567896345333949b2
#export fqdn=hotel.snc.24.1.0.pslab.click
#export port=8443
#export org=1
#
#Git for Windows
#https://git-scm.com/download/win
#Easily allows for curl and bash binaries in legacy Windows Operating Systems.
#
#Scheduled Task
#The following creates a scheduled task that execute every minute.
#Note/change git and script directories.
#schtasks /create /sc minute /mo 1 /ru system /tn import-flows /tr "C:\PortableGit\bin\sh.exe -c \"bash 'C:\Documents and Settings\Administrator\windows-netstat-illumio-import-flows.sh'\""
#
#Reference:
#https://docs.illumio.com/core/23.5/API-Reference/index.html
#
source "C:\Documents and Settings\Administrator\illumio.config"
netstat_response=$(netstat -n)
#for each line in the netstat response
while IFS= read -r line; do
    #ignore/continue on table header
    if [[ $line == *"Active Connections"* ]]; then continue; fi
    proto=$(echo $line | cut -d' ' -f1)
    dest=$(echo $line | cut -d' ' -f2)
    source=$(echo $line | cut -d' ' -f3)
    dest_ip=$(echo $dest | cut -d: -f1)
    dest_port=$(echo $dest | cut -d: -f2)
    source_ip=$(echo $source | cut -d: -f1)
    #ignore/continue if line is empty, table header, or localhost 127.0.0.1 traffic
    if [ -z "$source_ip" ]; then continue
    elif [[ $source_ip == "Address" ]]; then continue
    elif [ "$source_ip" == "127.0.0.1" ] && [ "$dest_ip" == "127.0.0.1" ]; then continue
    #transform protocol to protocol number
    elif [ "$proto" == "TCP" ]; then proto_int=6
    elif [ "$proto" == "UDP" ]; then proto_int=17
    fi
    #illumio agent bulk traffic flow api, depends on sourcing illumio.config variables
    curl -k https://$user:$key@$fqdn:$port/api/v2/orgs/$org/agents/bulk_traffic_flows --data-raw "$source_ip,$dest_ip,$dest_port,$proto_int"
done <<< "$netstat_response"
