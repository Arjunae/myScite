-- Windows requires this for us to immediately see all lua output.
io.stdout:setvbuf("no")

defaultHome = props["SciteDefaultHome"]
package.path =  package.path ..";"..defaultHome.."\\Addons\\?.lua;".. ";"..defaultHome.."\\Addons\\lua\\lua\\?.lua;"
package.cpath = package.cpath .. ";"..defaultHome.."\\Addons\\lua\\c\\?.dll;"

---- SciTEStartup.lua gets called by extman, to ensure its available here.

--print("Called StartupScript")
--print(props['command.name.8.*'])
--scite_Command('Tic Tac Toe|TicTacToe|Ctrl+8')