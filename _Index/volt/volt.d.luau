-- Volt executor API definitions for luau-lsp.
-- Stored under _Index as a Luau custom-definition dependency.
-- Source: https://docs.voltbz.net/docs (last reviewed 2026-07-22).
-- This file intentionally types dynamic executor values as `any` where Volt's
-- public documentation does not specify their complete shape.

type VoltEnvironment = { [string]: any }
type VoltFunction = (...any) -> ...any
type VoltObject = any
type VoltKey = string | number
type VoltByteArray = { number }
type VoltPacketData = buffer | string | VoltByteArray

type DecompilerFormatter = {
	IndentWidth: number?,
	UseTabs: boolean?,
	[ string ]: any,
}

type DecompilerOptions = {
	ConditionalStructurer: boolean?,
	SmartVariableRenamer: boolean?,
	FunctionDeclarations: boolean?,
	GuardClauses: boolean?,
	DoBlockInsertionThreshold: number?,
	Formatter: DecompilerFormatter?,
	[ string ]: any,
}

type DebugInfo = {
	name: string?,
	namewhat: string?,
	source: string?,
	short_src: string?,
	what: string?,
	currentline: number?,
	linedefined: number?,
	lastlinedefined: number?,
	nups: number?,
	nparams: number?,
	isvararg: boolean?,
	func: VoltFunction?,
	[ string ]: any,
}

type ProtoProxy = {
	Closure: VoltFunction?,
	Index: number?,
	[ string ]: any,
}

type VoltConnection = {
	Connected: boolean,
	Disconnect: (self: VoltConnection) -> (),
}

type VoltSignal = {
	Connect: (self: VoltSignal, handler: (...any) -> ()) -> VoltConnection,
	Once: (self: VoltSignal, handler: (...any) -> ()) -> VoltConnection,
	Wait: (self: VoltSignal) -> ...any,
	Fire: (self: VoltSignal, ...any) -> (),
}

type VoltSignalConstructor = {
	new: () -> VoltSignal,
}

type WebSocketConnection = {
	OnMessage: VoltSignal,
	OnClose: VoltSignal,
	IsClosed: boolean,
	Send: (self: WebSocketConnection, data: string | buffer) -> (),
	Close: (self: WebSocketConnection) -> (),
}

type WebSocketLibrary = {
	connect: (url: string, headers: { [string]: string }?) -> WebSocketConnection,
}

type RakNetPacket = {
	AsBuffer: buffer,
	AsString: string,
	AsArray: VoltByteArray,
	PacketId: number,
	Priority: number,
	Reliability: number,
	OrderingChannel: number,
	Size: number,
	SetData: (self: RakNetPacket, data: VoltPacketData) -> (),
	Block: (self: RakNetPacket) -> (),
}

type RakNetSendHook = (packet: RakNetPacket) -> ()

type RakNetLibrary = {
	add_send_hook: (hook: RakNetSendHook) -> (),
	remove_send_hook: (hook: RakNetSendHook) -> (),
	send: (data: VoltPacketData, priority: number?, reliability: number?, orderingChannel: number?) -> (),
	is_enabled: () -> boolean,
}

type DrawingObject = {
	Visible: boolean,
	ZIndex: number,
	Transparency: number,
	Color: any,
	__OBJECT_EXISTS: boolean,
	Remove: (self: DrawingObject) -> (),
	Destroy: (self: DrawingObject) -> (),
	[ string ]: any,
}

type DrawingLibrary = {
	new: (kind: "Line" | "Circle" | "Square" | "Triangle" | "Text" | "Image" | "Quad") -> DrawingObject,
}

type HttpRequest = {
	Url: string,
	Method: string?,
	Headers: { [string]: string }?,
	Body: string?,
	Cookies: { [string]: string }?,
}

type HttpResponse = {
	Success: boolean,
	StatusCode: number,
	StatusMessage: string,
	Headers: { [string]: string },
	Body: string,
}

type CryptLibrary = {
	encrypt: (data: string, key: string, iv: string?, mode: string?) -> string,
	decrypt: (data: string, key: string, iv: string?, mode: string?) -> string,
	hash: (data: string, algorithm: string?) -> string,
	hmac: (data: string, key: string, algorithm: string?) -> string,
	random: (length: number) -> string,
	generatekey: () -> string,
	generatebytes: (length: number) -> string,
	base64encode: (data: string) -> string,
	base64decode: (data: string) -> string,
	lz4compress: (data: string) -> string,
	lz4decompress: (data: string) -> string,
}

type BitLibrary = {
	badd: (...number) -> number,
	bsub: (...number) -> number,
	bmul: (...number) -> number,
	bdiv: (...number) -> number,
	band: (...number) -> number,
	bor: (...number) -> number,
	bxor: (...number) -> number,
	bnot: (value: number) -> number,
	bswap: (value: number) -> number,
	ror: (value: number, count: number) -> number,
	rol: (value: number, count: number) -> number,
	lshift: (value: number, count: number) -> number,
	rshift: (value: number, count: number) -> number,
	arshift: (value: number, count: number) -> number,
	tohex: (value: number) -> string,
	tobit: (value: number) -> number,
}

type CacheLibrary = {
	replace: (original: VoltObject, replacement: VoltObject) -> (),
	invalidate: (instance: VoltObject) -> (),
	iscached: (instance: VoltObject) -> boolean,
}

type OthLibrary = {
	hook: (target: VoltFunction, callback: VoltFunction) -> VoltFunction,
	unhook: (target: VoltFunction) -> (),
	get_original_thread: () -> thread?,
	get_root_callback: (target: VoltFunction) -> VoltFunction?,
	is_hook_thread: () -> boolean,
}

type LuaStateProxy = {
	Id: number,
	IsActorState: boolean,
	Event: VoltSignal,
	Execute: (self: LuaStateProxy, source: string) -> ...any,
	GetActors: (self: LuaStateProxy) -> { VoltObject },
}

type LuaStateProxyConstructor = {
	new: () -> LuaStateProxy,
}

declare VoltSignal: VoltSignalConstructor
declare Signal: VoltSignalConstructor
declare WebSocket: WebSocketLibrary
declare websocket: WebSocketLibrary
declare Drawing: DrawingLibrary
declare raknet: RakNetLibrary
declare crypt: CryptLibrary
declare bit: BitLibrary
declare cache: CacheLibrary
declare oth: OthLibrary
declare LuaStateProxy: LuaStateProxyConstructor

-- Closures
declare function checkcaller(): boolean
declare function clonefunction(target: VoltFunction): VoltFunction
declare function getfunctionhash(target: VoltFunction): string
declare function hookfunction(target: VoltFunction, replacement: VoltFunction): VoltFunction
declare function hookmetamethod(target: VoltObject, method: string, replacement: VoltFunction): VoltFunction
declare function iscclosure(target: VoltFunction): boolean
declare function isexecutorclosure(target: VoltFunction): boolean
declare function isfunctionhooked(target: VoltFunction): boolean
declare function islclosure(target: VoltFunction): boolean
declare function isnewcclosure(target: VoltFunction): boolean
declare function newcclosure(target: VoltFunction): VoltFunction
declare function newlclosure(target: VoltFunction): VoltFunction
declare function restorefunction(target: VoltFunction): ()
declare function setstackhidden(target: VoltFunction, hidden: boolean): ()

-- Debug
declare debug: {
	getcallstack: () -> { DebugInfo },
	getconstant: (target: VoltFunction | number, index: number) -> any,
	getconstants: (target: VoltFunction | number) -> { any },
	getinfo: (target: VoltFunction | number, options: string?) -> DebugInfo,
	getproto: (target: VoltFunction, index: number, active: boolean?) -> ProtoProxy | VoltFunction,
	getprotos: (target: VoltFunction, active: boolean?) -> { ProtoProxy | VoltFunction },
	getstack: (level: number, index: number?) -> any,
	getupvalue: (target: VoltFunction, index: number) -> any,
	getupvalues: (target: VoltFunction) -> { any },
	setconstant: (target: VoltFunction, index: number, value: any) -> (),
	setinfo: (target: VoltFunction | number, key: string, value: any) -> (),
	setstack: (level: number, index: number, value: any) -> (),
	setupvalue: (target: VoltFunction, index: number, value: any) -> (),
	validlevel: (level: number) -> boolean,
	isvalidlevel: (level: number) -> boolean,
	[ string ]: any,
}
declare function getcallstack(): { DebugInfo }
declare function getconstant(target: VoltFunction | number, index: number): any
declare function getconstants(target: VoltFunction | number): { any }
declare function getinfo(target: VoltFunction | number, options: string?): DebugInfo
declare function getproto(target: VoltFunction, index: number, active: boolean?): ProtoProxy | VoltFunction
declare function getprotos(target: VoltFunction, active: boolean?): { ProtoProxy | VoltFunction }
declare function getstack(level: number, index: number?): any
declare function getupvalue(target: VoltFunction, index: number): any
declare function getupvalues(target: VoltFunction): { any }
declare function setconstant(target: VoltFunction, index: number, value: any): ()
declare function setinfo(target: VoltFunction | number, key: string, value: any): ()
declare function setstack(level: number, index: number, value: any): ()
declare function setupvalue(target: VoltFunction, index: number, value: any): ()
declare function validlevel(level: number): boolean
declare function isvalidlevel(level: number): boolean

-- Reflection and metatables
declare function gethiddenproperties(target: VoltObject): { [string]: any }
declare function gethiddenproperty(target: VoltObject, property: string): any
declare function getproperties(target: VoltObject): { [string]: any }
declare function getthreadidentity(): number
declare function isnetworkowner(part: VoltObject): boolean
declare function isscriptable(target: VoltObject, property: string): boolean
declare function sethiddenproperty(target: VoltObject, property: string, value: any): boolean
declare function setscriptable(target: VoltObject, property: string, enabled: boolean): boolean
declare function setsimulationradius(radius: number, maxRadius: number?): ()
declare function setthreadidentity(identity: number): ()
declare function getnamecallmethod(): string
declare function getrawmetatable(target: VoltObject): { [any]: any }
declare function isreadonly(target: { [any]: any }): boolean
declare function iswritable(target: { [any]: any }): boolean
declare function makereadonly(target: { [any]: any }): ()
declare function makewritable(target: { [any]: any }): ()
declare function setnamecallmethod(method: string): ()
declare function setrawmetatable(target: VoltObject, metatable: { [any]: any }): boolean
declare function setreadonly(target: { [any]: any }, readonly: boolean): ()

-- Environments and scripts
declare function filtergc(predicate: (value: any) -> boolean): { any }
declare function getallthreads(): { thread }
declare function getgc(includeTables: boolean?): { any }
declare function getgenv(): VoltEnvironment
declare function getreg(): { [any]: any }
declare function getrenv(): VoltEnvironment
declare function gettenv(target: thread): VoltEnvironment
declare function decompile(target: VoltObject, options: DecompilerOptions?): string
declare function getcallingscript(): VoltObject?
declare function getfunctionbytecode(target: VoltFunction): string
declare function getloadedmodules(): { VoltObject }
declare function getmodules(): { VoltObject }
declare function getrunningscripts(): { VoltObject }
declare function getscriptbytecode(target: VoltObject): string
declare function getscriptclosure(target: VoltObject): VoltFunction
declare function getscriptfromthread(target: thread): VoltObject?
declare function getscripthash(target: VoltObject): string
declare function getscripts(): { VoltObject }
declare function getscriptthread(target: VoltObject): thread?
declare function getsenv(target: VoltObject): VoltEnvironment
declare function isexecutorthread(target: thread?): boolean
declare function loadstring(source: string, chunkName: string?): VoltFunction

-- Instances, signals, and actors
declare function cloneref(target: VoltObject): VoltObject
declare function compareinstances(left: VoltObject, right: VoltObject): boolean
declare function fireclickdetector(target: VoltObject, distance: number?): ()
declare function fireproximityprompt(target: VoltObject, holdDuration: number?, skipPrompt: boolean?): ()
declare function firetouchinterest(part1: VoltObject, part2: VoltObject, state: number): ()
declare function getcallbackmember(target: VoltObject, member: string): any
declare function getcallbackvalue(target: VoltObject, member: string): any
declare function gethui(): VoltObject
declare function getinstancecache(): { VoltObject }
declare function getinstances(): { VoltObject }
declare function getnilinstances(): { VoltObject }
declare function getrendersteppedlist(): { VoltConnection }
declare function cansignalreplicate(signal: VoltObject): boolean
declare function firesignal(signal: VoltObject, ...: any): ()
declare function getconnections(signal: VoltObject): { VoltConnection }
declare function getsignalarguments(signal: VoltObject): { string }
declare function getsignalargumentsinfo(signal: VoltObject): { [string]: any }
declare function getsignalwhitelist(): { VoltObject }
declare function replicatesignal(signal: VoltObject, ...: any): ()
declare function create_comm_channel(name: string): VoltObject
declare function get_comm_channel(name: string): VoltObject?
declare function get_current_actor(): VoltObject?
declare function getactors(): { VoltObject }
declare function getactorstates(): { LuaStateProxy }
declare function getgamestate(): LuaStateProxy
declare function getluastate(target: VoltObject): LuaStateProxy?
declare function isparallel(): boolean
declare function on_actor_state_created(callback: (state: LuaStateProxy) -> ()): VoltConnection
declare function run_on_actor(actor: VoltObject, callback: VoltFunction, ...: any): ...any

-- Filesystem
declare function appendfile(path: string, data: string): ()
declare function delfile(path: string): ()
declare function delfolder(path: string): ()
declare function dofile(path: string): ...any
declare function getcustomasset(path: string): string
declare function isfile(path: string): boolean
declare function isfolder(path: string): boolean
declare function listfiles(path: string): { string }
declare function loadfile(path: string): VoltFunction?
declare function makefolder(path: string): ()
declare function readfile(path: string): string
declare function writefile(path: string, data: string): ()

-- Input and console
declare function iswindowactive(): boolean
declare function keyclick(key: VoltKey): ()
declare function keypress(key: VoltKey): ()
declare function keyrelease(key: VoltKey): ()
declare function mouse1click(): ()
declare function mouse1press(): ()
declare function mouse1release(): ()
declare function mouse2click(): ()
declare function mouse2press(): ()
declare function mouse2release(): ()
declare function mousemoveabs(x: number, y: number): ()
declare function mousemoverel(x: number, y: number): ()
declare function mousescroll(amount: number): ()
declare function rconsoleclear(): ()
declare function rconsoleerr(message: string): ()
declare function rconsolehidden(): boolean
declare function rconsolehide(): ()
declare function rconsoleinfo(message: string): ()
declare function rconsoleinput(): string
declare function rconsolename(name: string): ()
declare function rconsoleprint(message: string): ()
declare function rconsoleshow(): ()
declare function rconsoletoggle(): ()
declare function rconsoletop(): ()
declare function rconsolewarn(message: string): ()

-- Encoding, drawing, and general utilities
declare function base64decode(data: string): string
declare function base64encode(data: string): string
declare function lz4compress(data: string): string
declare function lz4decompress(data: string): string
declare function cleardrawcache(): ()
declare function getrenderproperty(target: DrawingObject, property: string): any
declare function isrenderobj(target: any): boolean
declare function setrenderproperty(target: DrawingObject, property: string, value: any): ()
declare DrawFont: { Register: (data: string, name: string?) -> any }
declare function DrawingImmediate(callback: () -> ()): VoltConnection
declare function clearqueueonteleport(): ()
declare function get_process_identifier(): number
declare function getfflag(name: string): string?
declare function getfpscap(): number
declare function gethwid(): string
declare function identifyexecutor(): (string, string)
declare function messagebox(message: string, title: string?, flags: number?): number
declare function queueonteleport(source: string): ()
declare function request(options: HttpRequest): HttpResponse
declare function saveinstance(options: { [string]: any }?): ()
declare function saveplace(options: { [string]: any }?): ()
declare function setclipboard(text: string): ()
declare function setfflag(name: string, value: string): boolean
declare function setfpscap(cap: number): ()
declare function setrbxclipboard(text: string): ()
