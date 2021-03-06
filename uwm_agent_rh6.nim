###############################
#### scarlett@monitorhack.com
#### Aportación especial : 
#### https://github.com/juancarlospaco

#### Requeriments:
# - None for OS tested:

#### Requeriments for compile:
# nim gcc mingw64-gcc git
# PSUTIL without bugs
# nimble install https://github.com/juancarlospaco/psutil-nim

#### Compile commands:
# nim c -r uwb_agent.nim
# strip -s uwb_agent.nim


# Tested on:
# - CentOS7 (15/09/2108)

# Version 0.01 (15/09/2108)
# - Send JSON to URL

import os, osproc, strutils, math, terminal, json, times, nativesockets, ospaths, posix, httpclient, psutil

const agent_version = 0.01
var data = parseJson("{}")

proc pretty_float(feo: string): JsonNode =
  result = %round(feo.parse_float,2)

let id = paramStr(1)
let token = paramStr(2)


var mem_total_gb, mem_free_gb, mem_avaliable_gb, mem_used, mem_used_no_cached,
  mem_buffers_gb, mem_cached_gb, swap_total_gb, swap_free_gb, mem_total_kb,
  mem_free_kb, mem_avaliable_kb, mem_buffers_kb, mem_cached_kb, swap_total_kb,
  swap_free_kb, swap_used, uptime_server, cpu_percent: float
var cpu_5min, cpu_15min, cpu_1min : JsonNode
var cores, total_proces: int

for a in lines("/proc/meminfo"):
  if a.contains("MemTotal:"):
    var mem_total = a.splitWhitespace()
    mem_total_gb = mem_total[1].parse_float/1024.00/1024.00
    mem_total_kb = mem_total[1].parse_float
  if a.contains("MemFree:"):
    var mem_free = a.splitWhitespace()
    mem_free_gb = mem_free[1].parse_float/1024.00/1024.00
    mem_free_kb = mem_free[1].parse_float
  if a.contains("MemAvailable:"):
    var mem_avaliable = a.splitWhitespace()
    mem_avaliable_gb = mem_avaliable[1].parse_float/1024.00/1024.00
    mem_avaliable_kb = mem_avaliable[1].parse_float
  if a.contains("Buffers:"):
    var mem_buffers = a.splitWhitespace()
    mem_buffers_gb = mem_buffers[1].parse_float/1024.00/1024.00
    mem_buffers_kb = mem_buffers[1].parse_float
  if a.contains("Cached:"):
    var mem_cached = a.splitWhitespace()
    mem_cached_gb = mem_cached[1].parse_float/1024.00/1024.00
    mem_cached_kb = mem_cached[1].parse_float
  if a.contains("SwapTotal:"):
    var swap_total = a.splitWhitespace()
    swap_total_gb = swap_total[1].parse_float/1024.00/1024.00
    swap_total_kb = swap_total[1].parse_float
  if a.contains("SwapFree:"):
    var swap_free = a.splitWhitespace()
    swap_free_gb = swap_free[1].parse_float/1024.00/1024.00
    swap_free_kb = swap_free[1].parse_float


mem_used = ((mem_total_kb-mem_free_kb)*100)/mem_total_kb
mem_used_no_cached = (((((mem_total_kb-mem_free_kb))-(mem_buffers_kb+mem_cached_kb))*100)/mem_total_kb)
swap_used = 100-(swap_free_kb*100)/swap_total_kb

for a in lines("/proc/loadavg"):
  var uptime_array = a.splitWhitespace()
  cpu_1min = uptime_array[0].pretty_float
  cpu_5min = uptime_array[1].pretty_float
  cpu_15min = uptime_array[2].pretty_float
  var process_array = uptime_array[3].split("/")
  total_proces = process_array[1].parse_int

for a in lines("/proc/uptime"):
  var uptime_array = a.splitWhitespace()
  uptime_server = uptime_array[0].parse_float

cores = execCmdEx("/usr/bin/nproc --all").output.strip.parse_int

data.add("internal_id", %id)
data.add("internal_token", %token)
data.add("internal_hostOS", %hostOS)
data.add("internal_hostCPU", %hostCPU)
data.add("internal_agentinfo_version", %agent_version)
data.add("internal_agentinfo_NimVersion", %NimVersion)
data.add("internal_agentinfo_CompileTime", %CompileTime)
data.add("internal_agentinfo_getpid", %getpid())
data.add("internal_agentinfo_getHomeDir", %getHomeDir())
data.add("internal_time", %($now()))
data.add("internal_epochtime", %int(boot_time()))
data.add("uptime", %int(uptime_server))
data.add("internal_cores", %cores)
data.add("cpu_1min", %cpu_1min)
data.add("cpu_5min", %cpu_5min)
data.add("cpu_15min", %cpu_15min)
data.add("cpu_perc", %cpu_percent(interval=1.0))
#data.add("mem_total_gb", %round(mem_total_gb,2))
#data.add("mem_free_gb", %round(mem_free_gb,2))
#data.add("mem_avaliable_gb", %round(mem_avaliable_gb,2))
data.add("mem_used", %round(mem_used,2))
data.add("mem_used_no_cached", %round(mem_used_no_cached,2))
data.add("swap_total_gb", %round(swap_total_gb,2))
data.add("swap_used", %round(swap_used,2))
data.add("total_proces", %total_proces)

var df_result = execCmdEx("df -P | sed '1d'").output.strip.splitLines
for a in df_result:
  var filesystem = "filesystem_"&a.splitWhitespace[5]
  var filesystem_per = a.splitWhitespace[4].replace("%", "").parse_int
  data.add($filesystem, %filesystem_per)

echo data.pretty

let client = newHttpClient(timeout=9000)
client.headers = newHttpHeaders({ "Content-Type": "application/json" })
let response = client.request("http://www.uwebmonitor.com/site/api/api.php", httpMethod = HttpPost, body = $data)
echo "HTML : "&response.body
echo "CODE RESPONSE : "&response.status

