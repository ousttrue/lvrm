uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

vec4
position(mat4 transform_projection, vec4 vertex_position)
{
  return m_projection * m_view * m_model * vertex_position;
}
