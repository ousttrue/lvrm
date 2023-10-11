local function add_package_path(path)
  package.path = package.path
    .. string.format(";%s/?.lua;%s/?/init.lua", path, path)
end
add_package_path "libs"

local ffi = require "ffi"
local glfw = require "glfw"
local gl = require "gl"
local stb_image = require "stb_image"

ffi.cdef [[
typedef struct {
  float x, y;
  float r, g, b;
} Vertex;
]]
local vertices = ffi.new(
  "Vertex[3]",
  { -0.6, -0.4, 1., 0., 0. },
  { 0.6, -0.4, 0., 1., 0. },
  { 0., 0.6, 0., 0., 1. }
)

local vertex_shader_text = [[
#version 110
uniform mat4 MVP;
attribute vec3 vCol;
attribute vec2 vPos;
varying vec3 color;
void main()
{
    gl_Position = MVP * vec4(vPos, 0.0, 1.0);
    color = vCol;
}
]]

local fragment_shader_text = [[
#version 110
varying vec3 color;
void main()
{
    gl_FragColor = vec4(color, 1.0);
};
]]

-- static void error_callback(int error, const char *description) {
--   fprintf(stderr, "Error: %s\n", description);
-- }

local function main()
  --   glfwSetErrorCallback(error_callback);
  --   glfwInitHint(GLFW_COCOA_MENUBAR, GLFW_FALSE);

  glfw.init()

  glfw.hint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 2)
  glfw.hint(glfw.GLFW_CONTEXT_VERSION_MINOR, 0)
  glfw.hint(glfw.GLFW_VISIBLE, glfw.GLFW_FALSE)

  local window = glfw.Window(640, 480, "Simple example", nil, nil)
  if not window then
    glfw.terminate()
    os.exit(1)
  end

  window:makeContextCurrent()

  gl.load(glfw)

  local vertex_buffer = ffi.new "GLuint[1]"
  gl.glGenBuffers(1, vertex_buffer)
  gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vertex_buffer[0])
  gl.glBufferData(
    gl.GL_ARRAY_BUFFER,
    ffi.sizeof(vertices),
    vertices,
    gl.GL_STATIC_DRAW
  )

  local array = ffi.new "const char*[1]"
  array[0] = vertex_shader_text
  local vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER)
  gl.glShaderSource(vertex_shader, 1, array, nil)
  gl.glCompileShader(vertex_shader)

  local fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER)
  array[0] = fragment_shader_text
  gl.glShaderSource(fragment_shader, 1, array, nil)
  gl.glCompileShader(fragment_shader)

  local program = gl.glCreateProgram()
  gl.glAttachShader(program, vertex_shader)
  gl.glAttachShader(program, fragment_shader)
  gl.glLinkProgram(program)

  local mvp_location = gl.glGetUniformLocation(program, "MVP")
  local vpos_location = gl.glGetAttribLocation(program, "vPos")
  local vcol_location = gl.glGetAttribLocation(program, "vCol")

  gl.glEnableVertexAttribArray(vpos_location)
  gl.glVertexAttribPointer(
    vpos_location,
    2,
    gl.GL_FLOAT,
    gl.GL_FALSE,
    ffi.sizeof(vertices[0]),
    nil
  )
  gl.glEnableVertexAttribArray(vcol_location)
  gl.glVertexAttribPointer(
    vcol_location,
    3,
    gl.GL_FLOAT,
    gl.GL_FALSE,
    ffi.sizeof(vertices[0]),
    ffi.cast("void*", (ffi.sizeof "float") * 2)
  )

  local width, height = window:getFramebufferSize()
  local ratio = width / height

  gl.glViewport(0, 0, width, height)
  gl.glClear(gl.GL_COLOR_BUFFER_BIT)

  local mvp =
    ffi.new("float[16]", 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)

  gl.glUseProgram(program)
  gl.glUniformMatrix4fv(mvp_location, 1, gl.GL_FALSE, mvp)
  gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3)
  gl.glFinish()

  local buffer = ffi.new("char[?]", 4 * width * height)
  gl.glReadPixels(0, 0, width, height, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, buffer)

  stb_image.stbi_write_png("offscreen.png", width, height, 4, buffer, width * 4)

  glfw.terminate()
end

main()
