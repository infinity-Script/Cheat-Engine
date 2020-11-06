(function() local modules = {} local require = function(module) return modules[module]() end  modules = {["..src.memory-utils"] = function() local function read_byte(addr)     return readBytes(addr, 1, false) end local function write_byte(addr, byte)     writeBytes(addr, { byte }) end local function byte_to_str(byte)      if byte == nil then return "00" end     local str=""     if byte <= 256 then         str=str..c_ref1[math.floor(byte/16)+1]         str=str..c_ref1[math.floor(byte%16)+1]     end     return str end local function addr_to_bytes(addr)     assert(addr~=nil, 'Nil address used in addr_to_bytes')     local bytes = {0,0,0,0}          for i=0,3 do         bytes[3-i]=(addr>>(i*8))%256     end     return bytes end local function addr_to_str(addr)     assert(addr~=nil, 'Nil address used in addr_to_str')     local str="";     local bytes = addr_to_bytes(addr)     for i=0,3 do          str = str..byte_to_str(bytes[i])     end     return str end local function str_to_hex(str)     if (string.len(str) ~= 2) then         return 0     end     local byte=0     for i=1,16,1 do         if (str:sub(1,1)==c_ref1[i]) then             byte=byte+(c_ref2[i]*16)         end         if (str:sub(2,2)==c_ref1[i]) then             byte=byte+i         end     end     return byte end  local function readsb(addr, len)     local str = ""     for i=1,len do         str=str..byte_to_str(read_byte(addr))     end     return str end local function get_prologue(addr)     local func_start = addr;     while not (read_byte(func_start) == 0x55 and read_byte(func_start + 1) == 0x8B and read_byte(func_start + 2) == 0xEC) do         func_start = func_start - 1;     end     return func_start; end local function get_next_prologue(addr)     local func_start = addr;     while not (read_byte(func_start) == 0x55 and read_byte(func_start + 1) == 0x8B and read_byte(func_start + 2) == 0xEC) do         func_start = func_start + 1;     end     return func_start; end return {     read_byte = read_byte,     write_byte = write_byte,     byte_to_str = byte_to_str,     addr_to_str = addr_to_str,     addr_to_bytes = addr_to_bytes,     str_to_hex = str_to_hex,     readsb = readsb,     get_prologue = get_prologue,     get_next_prologue = get_next_prologue, } end,["entry"] = function()   local utils = require('..src.ce-utils') local mem_utils = require('..src.memory-utils') local read_byte = mem_utils.read_byte local write_byte = mem_utils.write_byte local byte_to_str = mem_utils.byte_to_str local addr_to_str = mem_utils.addr_to_str local addr_to_bytes = mem_utils.addr_to_bytes local str_to_hex = mem_utils.str_to_hex local readsb = mem_utils.readsb local get_prologue = mem_utils.get_prologue local get_next_prologue = mem_utils.get_next_prologue local roblox_pid = utils.process.get_pid_by_name("RobloxPlayerBeta.exe") utils.process.open(roblox_pid)  local base = utils.addresses.get(enumModules(roblox_pid)[1].Name) local functions = {} local nfunctions = 0 local bytecode_body = utils.http.get("https://raw.githubusercontent.com/thedoomed/Cheat-Engine/master/bytecode_example.bin") local bytecode_size = string.len(bytecode_body) local bytecode_loc = utils.memory.allocate(bytecode_size) local bytecode = {} for i=1, bytecode_size do     writeBytes(bytecode_loc + (i-1), { bytecode_body:byte(i, i) }) end writeInteger(bytecode_loc + bytecode_size + (bytecode_size + (4%4)), bytecode_size) c_ref1 = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"} c_ref2 = { 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15} local function log_info(text)     print('info: '..text) end log_info('size of bytecode '.. addr_to_str(bytecode_size)) log_info('bytecode '.. addr_to_str(bytecode_loc))       local str_spawn_ref = addr_to_bytes(utils.addresses.get(AOBScan("537061776E20","-C-W",0,"")[0]));   local str_spawn_bytes = byte_to_str(str_spawn_ref[3])..byte_to_str(str_spawn_ref[2])..byte_to_str(str_spawn_ref[1])..byte_to_str(str_spawn_ref[0]);  local r_spawn       = utils.addresses.get(AOBScan(str_spawn_bytes,"-C-W",0,"")[0]); local r_deserialize = utils.addresses.get(AOBScan("0F????83??7FD3??83??0709","-C-W",0,"")[0]); local r_gettop      = utils.addresses.get(AOBScan("558BEC8B??088B????2B??????????5DC3","-C-W",0,"")[0]); local r_newthread   = utils.addresses.get(AOBScan("72??6A01??E8????????83C408??E8","-C-W",0,"")[0]); r_deserialize      = get_prologue(r_deserialize); r_spawn            = get_prologue(r_spawn); r_newthread        = get_prologue(r_newthread);    local arg_data = utils.memory.shared_allocation(4096); assert(arg_data~=nil, 'Failed to allocate shared memory...') local ret_location = (arg_data + 64); function getReturn()     return readInteger(ret_location); end  local rL = 0; local gettop_old_bytes = readBytes(r_gettop + 6, 6, true);    local gettop_hook_loc = arg_data + 0x400; local hook_at = gettop_hook_loc; local trace_loc = arg_data + 0x3FC; local jmp_pointer_to = arg_data + 0x3F8; local jmp_pointer_back = arg_data + 0x3F4; writeInteger(jmp_pointer_to, gettop_hook_loc); writeInteger(jmp_pointer_back, r_gettop + 12);  writeBytes(hook_at,	{ 0x60, 0x89, 0x0D });	hook_at = hook_at + 3; writeInteger(hook_at, 	trace_loc);		hook_at = hook_at + 4; write_byte(hook_at,	0x61);			hook_at = hook_at + 1; writeBytes(hook_at,	gettop_old_bytes); 	hook_at = hook_at + 6; writeBytes(hook_at,	{ 0xFF, 0x25 }); 	hook_at = hook_at + 2; writeInteger(hook_at, 	jmp_pointer_back);  bytes_jmp = addr_to_bytes(jmp_pointer_to); local gettop_hook = { 0xFF, 0x25, bytes_jmp[3], bytes_jmp[2], bytes_jmp[1], bytes_jmp[0] }; log_info("gettop hook: " .. addr_to_str(gettop_hook_loc)) end,["..src.ce-utils"] = function()  local utils = {} utils.http = {}  function utils.http.get(url)     local client = getInternet()     local response = client.getURL(url)     client.destroy()     return response end utils.process = {}   function utils.process.get_pid_by_name(processname)     return getProcessIDFromProcessName(processname) end     function utils.process.open(processname)     return openProcess(processname) end utils.memory = {}  function utils.memory.allocate(size)     return allocateMemory(size) end      function utils.memory.shared_allocation(name, size)     return allocateSharedMemory(name, size) end utils.addresses = {}      function utils.addresses.get(addr_str, _local)     return getAddress(addr_str, _local) end return utils end,}  modules.entry() end)()