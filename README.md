# lvrm

VRM loader for LÖVE 2D.

## dependencies

### json.lua
- https://github.com/rxi/json.lua

### cimgui-love
- https://github.com/apicici/cimgui-love

# cimgui-love build instruction

## cimgui[internal, freetype] generate

add '-DIMGUI_USE_WCHAR32=1' for imWchar to uint32_t from uint16_t(default).
```lua
if FREETYPE_GENERATION then
	CFLAGS = CFLAGS .. " -DIMGUI_ENABLE_FREETYPE -DIMGUI_USE_WCHAR32=1"
end
```

```sh
cimgui-love> cd cimgui/generator
cimgui-love/cimgui/generator> LUA_PATH=$(pwd)\\?.lua luajit generator.lua cl "internal freetype"
```

## cimgui build
cimgui-love/CMakeLists.txt
```cmake
	# FIND_PACKAGE(freetype REQUIRED PATHS ${FREETYPE_PATH})
    include(FetchContent)
    FetchContent_Declare(
      freetype2
      GIT_REPOSITORY https://github.com/freetype/freetype.git
      GIT_TAG VER-2-13-2
      GIT_PROGRESS TRUE)
    FetchContent_MakeAvailable(freetype2)
```

```sh
cimgui-love/cimgui> cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Release -DIMGUI_FREETYPE=on -DCMAKE_CXX_FLAGS=-DIMGUI_USE_WCHAR32=1
cimgui-love/cimgui> cmake --build build
cimgui-love/cimgui> copy build/cimgui.dll %DST_DIR%
```

## cimgui-love generae

```sh
cimgui-love/cimgui/generator> LUA_PATH=$(pwd)\\?.lua luajit generator.lua
```
## fix cimgui/cdef.lua

```
FILE* => void*
```

