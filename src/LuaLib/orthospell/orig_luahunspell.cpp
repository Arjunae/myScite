// Lua Interface for Hunspell - Matt White (pbsurf at gmail.com)
// 11 March 2010 - initial version
// 19 June 2012 - linux version

// Usage example:
//   require("hunspell")
//   hunspell.init("C:\\hunspell\\en_US.aff", "C:\\hunspell\\en_US.dic")
//   iswordrecogized = hunspell.spell("teh")
//   suggestions = hunspell.suggest("teh")
//#include "hunspell.h"

#include "hunspell.hxx"
#include <stdio.h>
#include <windows.h>

// Application must use a single instance of Lua, or heap
//  corruption will occur when using suggest() (indicated by
//  crash in ntdll.dll on garbage collection)  So, we must
//  link to the lua dll (or lua exports in SciTE).
// To use lua functions exported in SciTE.exe, SciTE.lib is needed.
// It can be obtained as part of SciteDebug
// (http://scitedebug.luaforge.net/), or generated by compiling
// SciTE, or as follows:
//  1. use borland `impdef SciTE.def SciTE.exe`,
//  - impdef is available with Borland C++ 5.5 (free download)
//  - do NOT use the -a option with impdef
//  2. delete the ordinal numbers (@1,...) in SciTE.def
//  3. use microsoft `lib /DEF:SciTE.def` to generate .lib

// Building for linux:
//  sudo aptitude install liblua5.1-dev libhunspell-dev
//  g++ -I /usr/include/hunspell/ -I /usr/include/lua5.1/ -shared
//    -lhunspell -o hunspell.so luahunspell.cpp
// The linux version uses the libhunspell shared system library, whereas the
//  windows version ----Edit: includes hunspell in the DLL #define LUA_BUILD_AS_DLL
// windows version statically links it:

#ifdef _WIN32
//#define LUA_BUILD_AS_DLL
//#define LUA_API __declspec(dllimport)
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT 
#endif

//#include <lua.hpp>
extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

Hunspell* pMS = NULL;

// hunspell.init(<affix file path>, <dict file path>)
static int l_init(lua_State *L)
{
  if(pMS) delete pMS;
  pMS = new Hunspell(lua_tostring(L, 1), lua_tostring(L, 2));
  return 0;  // number of results
}

// takes path to a dictionary file
static int l_add_dic(lua_State *L)
{
  if(pMS)
	  lua_pushboolean(L, pMS->add_dic( lua_tostring(L, 1) ));
  else
    lua_pushnil(L);
  return 1;  // number of results
}

static int l_close(lua_State *L)
{
  delete pMS;
  pMS = NULL;
  return 0;  // number of results
}

// returns true if word recognized, false if not, nil if not inited
static int l_spell(lua_State *L)
{
  if(pMS)
    lua_pushboolean(L, pMS->spell( lua_tostring(L, 1) ));
  else
    lua_pushnil(L);
  // spell returns 0 if word is not recognized
  return 1;  // number of results
}

// takes word, returns table of suggestions
static int l_suggest(lua_State *L)
{
  if(!pMS) {
    lua_pushnil(L);
    return 1;
  }
  // spell returns 0 if word is not recognized
  char** wlst;
  // returns number of suggestions
  int ns = pMS->suggest(&wlst, lua_tostring(L, 1));
  lua_newtable(L);
  for (int ii = 0; ii < ns; ii++) {
    lua_pushnumber(L, ii + 1);
    lua_pushstring(L, wlst[ii]);
    // both index and string are popped from Lua stack
    lua_settable(L, -3);
  }
  pMS->free_list(&wlst, ns);
  return 1;  // number of results
}

static const struct luaL_reg luafns[] =
{
  {"init", l_init},
  {"add_dic", l_add_dic},
  {"close", l_close},
  {"spell", l_spell},
  {"suggest", l_suggest},
  {NULL, NULL}
};

// We (have to) use a .def file to prevent an underscore from
//  being prepended to the exported function name


extern "C" DLLEXPORT int luaopen_hunspell(lua_State *L)
{
  luaL_openlib(L, "hunspell", luafns,0);
  return 0;
}

/* Lua version. */

extern "C" DLLEXPORT const char* lua_version(void)
{
  printf("called test");
	return "1.5.2";
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
  printf("load/unload my DLL\n");
  return TRUE;
}
