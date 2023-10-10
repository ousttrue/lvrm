uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

#ifdef USE_SKINNING
attribute vec4 VertexJoints;
attribute vec4 VertexWeights;
uniform mat4 joints_matrices[150];
#endif

vec4
position(mat4 transform_projection, vec4 vertex_position)
{
#ifdef USE_SKINNING
  mat4 skin_matrix = mat4(0.0);
  skin_matrix += VertexWeights.x * joints_matrices[int(VertexJoints.x)];
  skin_matrix += VertexWeights.y * joints_matrices[int(VertexJoints.y)];
  skin_matrix += VertexWeights.z * joints_matrices[int(VertexJoints.z)];
  skin_matrix += VertexWeights.w * joints_matrices[int(VertexJoints.w)];
  vertex_position = skin_matrix * vertex_position;
#endif

  return m_projection * m_view * m_model * vertex_position;
}
