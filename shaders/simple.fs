
vec4
effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
{
  vec4 texcolor = Texel(t, texture_coords);
  return texcolor;
  // return vec4(1, 1, 1, 1);
}
