---@meta
--
-- representation from [glTF JSON Schema](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0/schema)
-- to [LuaCATS](https://luals.github.io/wiki/annotations/)
--

--- https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/asset.schema.json
---@class gltf.Asset
---@field copyright string
---@field generator string
---@field version string
---@field minVersion string

---@class gltf.ChildOfRootProperty
---@field name string?

--- https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/buffer.schema.json
---@class gltf.Buffer: gltf.ChildOfRootProperty
---@field uri string?
---@field byteLength integer

--- https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/bufferView.schema.json
---@class gltf.BufferView: gltf.ChildOfRootProperty
---@field buffer integer
---@field byteOffset integer?
---@field byteLength integer
---@field byteStride integer?
---@field target integer?

---@enum gltf.Accessor_ComponentType
local GltfAccessor_ComponentType = {
  BYTE = 5120,
  UBYTE = 5121,
  SHORT = 5122,
  USHORT = 5123,
  UINT = 5125,
  FLOAT = 5126,
}

---@enum gltf.Accessor_Type
local GltfAccessor_Type = {
  SCALAR = "SCALAR",
  VEC2 = "VEC2",
  VEC3 = "VEC3",
  VEC4 = "VEC4",
  MAT2 = "MAT2",
  MAT3 = "MAT3",
  MAT4 = "MAT4",
}

---https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/accessor.schema.json
---@class gltf.Accessor: gltf.ChildOfRootProperty
---@field bufferView integer?
---@field byteOffset integer?
---@field componentType gltf.Accessor_ComponentType
---@field normalized boolean?
---@field count integer
---@field type gltf.Accessor_Type
---@field max number[]?
---@field min number[]?
---@field sparse table?

---@class gltf.Sampler
---@field magFilter integer [9728:NEAREST, 9729:LINEAR]
---@field minFilter integer [9728:NEAREST, 9729:LINEAR, 9984:NEAREST_MIPMAP_NEAREST, 9985:LINEAR_MIPMAP_NEAREST, 9986:NEAREST_MIPMAP_LINEAR, 9987:LINEAR_MIPMAP_LINEAR]
---@field wrapS integer [33071:CLAMP_TO_EDGE, 33648:MIRRORED_REPEAT, 10497:REPEAT]
---@field wrapT integer [33071:CLAMP_TO_EDGE, 33648:MIRRORED_REPEAT, 10497:REPEAT]

---@class gltf.Image
---@field name string?
---@field uri string?
---@field mimeType string?
---@field bufferView integer?

---@class gltf.Texture: gltf.ChildOfRootProperty
---@field sampler integer?
---@field source integer

---@class gltf.TextureInfo
---@field index integer

---@class gltf.PbrMetallicRoughness
---@field baseColorFactor number[]?
---@field baseColorTexture gltf.TextureInfo?
---@field metallicFactor number?
---@field roughnessFactor number?
---@field metallicRoughnessTexture gltf.TextureInfo?

---@class gltf.Material
---@field name string?
---@field pbrMetallicRoughness gltf.PbrMetallicRoughness?
---@field normalTexture gltf.TextureInfo?
---@field occlusionTexture gltf.TextureInfo?
---@field emissiveTexture gltf.TextureInfo?
---@field emissiveFactor number[]?
---@field alphaMode string ["OPAQUE", "MASK", "BLEND"]?
---@field alphaCutoff number?
---@field doubleSided boolean?

---@class gltf.Attributes
---@field POSITION integer
---@field NORMAL integer?
---@field TEXCOORD_0 integer?
---@field TEXCOORD_1 integer?
---@field TANGENT integer?
---@field COLOR_0 integer?
---@field JOINTS_0 integer?
---@field WEIGHTS_0 integer?

---@class gltf.Primitive
---@field attributes gltf.Attributes
---@field indices integer?{
---@field material integer?

---@class gltf.Mesh
---@field primitives gltf.Primitive[]

---@class gltf.Node
---@field name string?
---@field children integer[]?
---@field matrix number[]?
---@field rotation number[]?
---@field scale number[]?
---@field translation number[]?
---@field mesh integer?
---@field skin integer?

--- https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/scene.schema.json
---@class gltf.Scene: gltf.ChildOfRootProperty
---@field nodes integer[]?

--- https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/glTF.schema.json
---@class gltf.Root
---@field asset gltf.Asset
---@field buffers gltf.Buffer[]?
---@field bufferViews gltf.BufferView[]?
---@field accessors gltf.Accessor[]?
---@field images gltf.Image[]?
---@field samplers gltf.Sampler[]?
---@field textures gltf.Texture[]?
---@field materials gltf.Material[]?
---@field meshes gltf.Mesh[]?
---@field nodes gltf.Node[]?
---@field scenes gltf.Scene[]?
---@field scene integer?
