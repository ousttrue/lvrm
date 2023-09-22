---@meta
--
-- representation from [glTF JSON Schema](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0/schema)
-- to [LuaCATS](https://luals.github.io/wiki/annotations/)
--

---https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/asset.schema.json
---@class GltfAsset
---@field copyright string
---@field generator string
---@field version string
---@field minVersion string

---@class ChildOfRootProperty
---@field name string?

---https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/buffer.schema.json
---@class GltfBuffer: ChildOfRootProperty
---@field uri string?
---@field byteLength integer

---https://github.com/KhronosGroup/glTF/blob/main/specification/2.0/schema/bufferView.schema.json
---@class GltfBufferView: ChildOfRootProperty
---@field buffer integer
---@field byteOffset integer?
---@field byteLength integer
---@field byteStride integer?
---@field target integer?

---@enum GltfAccessor_ComponentType
local GltfAccessor_ComponentType = {
  BYTE = 5120,
  UBYTE = 5121,
  SHORT = 5122,
  USHORT = 5123,
  UINT = 5125,
  FLOAT = 5126,
}

---@enum GltfAccessor_Type
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
---@class GltfAccessor: ChildOfRootProperty
---@field bufferView integer?
---@field byteOffset integer?
---@field componentType GltfAccessor_ComponentType
---@field normalized boolean?
---@field count integer
---@field type GltfAccessor_Type
---@field max number[]?
---@field min number[]?
---@field sparse table?

---@class GltfAttributes
---@field POSITION integer
---@field NORMAL integer?
---@field TEXCOORD_0 integer?
---@field TEXCOORD_1 integer?
---@field TANGENT integer?
---@field COLOR_0 integer?
---@field JOINTS_0 integer?
---@field WEIGHTS_0 integer?

---@class GltfPrimitive
---@field attributes GltfAttributes
---@field indices integer?{
---@field material integer?

---@class GltfMesh
---@field primitives GltfPrimitive[]

---@class GltfNode
---@field name string?
---@field children integer[]?
---@field matrix number[]?
---@field rotation number[]?
---@field scale number[]?
---@field translation number[]?
---@field mesh integer?
---@field skin integer?

---@class GltfTextureInfo
---@field index integer

---@class GltfPbrMetallicRoughness
---@field baseColorFactor number[]?
---@field baseColorTexture GltfTextureInfo?
---@field metallicFactor number?
---@field roughnessFactor number?
---@field metallicRoughnessTexture GltfTextureInfo?

---@class GltfMaterial
---@field name string?
---@field pbrMetallicRoughness GltfPbrMetallicRoughness?
---@field normalTexture GltfTextureInfo?
---@field occlusionTexture GltfTextureInfo?
---@field emissiveTexture GltfTextureInfo?
---@field emissiveFactor number[]?
---@field alphaMode string ["OPAQUE", "MASK", "BLEND"]?
---@field alphaCutoff number?
---@field doubleSided boolean?

---@class GltfSampler
---@field magFilter integer [9728:NEAREST, 9729:LINEAR]
---@field minFilter integer [9728:NEAREST, 9729:LINEAR, 9984:NEAREST_MIPMAP_NEAREST, 9985:LINEAR_MIPMAP_NEAREST, 9986:NEAREST_MIPMAP_LINEAR, 9987:LINEAR_MIPMAP_LINEAR]
---@field wrapS integer [33071:CLAMP_TO_EDGE, 33648:MIRRORED_REPEAT, 10497:REPEAT]
---@field wrapT integer [33071:CLAMP_TO_EDGE, 33648:MIRRORED_REPEAT, 10497:REPEAT]

---@class GltfImage
---@field name string?
---@field uri string?
---@field mimeType string?
---@field bufferView integer?

---@class GltfTexture
---@field name string?
---@field sampler integer?
---@field source integer

---@class Gltf
---@field asset GltfAsset
---@field buffers GltfBuffer[]
---@field bufferViews GltfBufferView[]
---@field accessors GltfAccessor[]
---@field meshes GltfMesh[]
---@field nodes GltfNode[]
---@field materials GltfMaterial[]
---@field textures GltfTexture[]
---@field samplers GltfSampler[]
---@field images GltfImage[]
