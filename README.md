# lvrm

VRM loader for LÖVE 2D.

## dependencies

### json.lua
- https://github.com/rxi/json.lua

### cimgui-love
- https://github.com/apicici/cimgui-love

#### build instruction

cimgui-love/CMakeLists.txt
```cmake
	# FIND_PACKAGE(freetype REQUIRED PATHS ${FREETYPE_PATH})
    include(FetchContent)
    FetchContent_Declare(
      freetype2
      GIT_REPOSITORY https://github.com/aseprite/freetype2.git
      GIT_TAG VER-2-10-0
      GIT_PROGRESS TRUE)

    FetchContent_MakeAvailable(freetype2)
```

```sh
cimgui-love> cd cimgui/generator
cimgui-love/cimgui/generator> LUA_PATH=$(pwd)\\?.lua luajit generator.lua cl "internal freetype"
cimgui-love/cimgui/generator> cd ..
cimgui-love/cimgui> cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Release
cimgui-love/cimgui> cmake --build build
cimgui-love/cimgui> copy build/cimgui.dll %DST_DIR%

cimgui-love/cimgui> cd ..
cimgui-love/cimgui/generator> LUA_PATH=$(pwd)\\?.lua luajit generator.lua
```

