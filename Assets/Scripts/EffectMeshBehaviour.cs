using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class EffectMeshBehaviour : MonoBehaviour
{
	[SerializeField] private MeshRenderer _renderer;
	[SerializeField] private MeshFilter   _mesh;
	[SerializeField] private int          _circleSegments     = 32;
	[SerializeField] private float        _topRadius          = 0.1f;
	[SerializeField] private float        _bottomRadius       = 4f;
	[SerializeField] private float        _radiusStepRelative = 0.1f;
	[SerializeField] private int          _verticalSegments   = 16;
	[SerializeField] private float        _height             = 1f;
	[SerializeField] private int          _subMeshCount       = 4;
	[SerializeField] private float        _curvature          = 50f;
	[SerializeField] private float        _twist              = 1f;

	[System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
	private struct Vertex
	{
		public Vector3 Position;
		public Vector3 Normal;
		public Vector2 UV;
	}

	void Start()
	{
		GenerateMesh(_mesh.mesh);
	}
	
	private void GenerateMesh(Mesh mesh)
	{
		mesh.Clear();
		
		VertexAttributeDescriptor[] layout = new[]
		                                     {
			                                     new VertexAttributeDescriptor(VertexAttribute.Position,  VertexAttributeFormat.Float32, 3),
			                                     new VertexAttributeDescriptor(VertexAttribute.Normal,    VertexAttributeFormat.Float32, 3),
			                                     new VertexAttributeDescriptor(VertexAttribute.TexCoord0, VertexAttributeFormat.Float32, 2),
		                                     };

		int                 vertexCountPerSubMesh = (_circleSegments + 1) * _verticalSegments; 
		int                 vertexCount           = vertexCountPerSubMesh * _subMeshCount * 2;
		NativeArray<Vertex> vertices              = new (vertexCount, Allocator.Temp);

		int                 indexCountPerSubMesh = _circleSegments      * (_verticalSegments - 1) * 2 * 3;
		int                 indexCount           = indexCountPerSubMesh * _subMeshCount * 2;
		NativeArray<ushort> indices              = new(indexCount, Allocator.Temp);

		int vertex = 0;
		int index  = 0;
		for (int i = 0; i < _subMeshCount; ++i)
		{
			GenerateSubMesh(vertex, index, i, true, ref vertices, ref indices);
			vertex += vertexCountPerSubMesh;
			index  += indexCountPerSubMesh;

			GenerateSubMesh(vertex, index, i, false, ref vertices, ref indices);
			vertex += vertexCountPerSubMesh;
			index  += indexCountPerSubMesh;
		}

		mesh.SetVertexBufferParams(vertexCount, layout);
		mesh.SetVertexBufferData(vertices, 0, 0, vertexCount);

		mesh.SetIndexBufferParams(indexCount, IndexFormat.UInt16);
		mesh.SetIndexBufferData(indices, 0, 0, indexCount);
		
		mesh.subMeshCount = 1;
		mesh.SetSubMesh(0, new SubMeshDescriptor(0, indexCount, MeshTopology.Triangles));

		mesh.RecalculateBounds();
	}

	private void GenerateSubMesh(int baseVertex, int baseIndex, int subMesh, bool reverse, ref NativeArray<Vertex> vertices, ref NativeArray<ushort> indices)
	{
		// vertex buffer
		int                 index    = baseVertex;
		for (int majorSegment = 0; majorSegment < _circleSegments + 1; ++majorSegment)
		{
			float majorSegmentAngle = Mathf.PI * 2f * majorSegment / _circleSegments;
			
			for (int minorSegment = 0; minorSegment < _verticalSegments; ++minorSegment)
			{
				Vector3 ringCenter = new(
					0f,
					_height / (_verticalSegments - 1) * minorSegment,
					0f
				);
				
				Vector2 uv = new((float) majorSegment / _circleSegments, (float) minorSegment / (_verticalSegments - 1));

				uv.x += uv.y * _twist + (float)subMesh / _subMeshCount;
				
				float radius = Mathf.Lerp(_bottomRadius, _topRadius, 1f - Mathf.Pow(1f - uv.y, _curvature));
				radius += radius * _radiusStepRelative * subMesh;
		
				Vector3 position = new(
					ringCenter.x + Mathf.Cos(majorSegmentAngle) * radius,
					ringCenter.y,
					ringCenter.z + Mathf.Sin(majorSegmentAngle) * radius
				);
				
				vertices[index++] = new Vertex
				                    {
					                    Position = position,
					                    Normal   = (position - ringCenter).normalized,
					                    UV = uv,
				                    };
			}
		}

		// index buffer
		index    = baseIndex;
		for (int majorSegment = 0; majorSegment < _circleSegments; ++majorSegment)
		{
			int nextMajorSegment = majorSegment + 1;
			
			for (int minorSegment = 0; minorSegment < _verticalSegments - 1; ++minorSegment)
			{
				int nextMinorSegment = minorSegment + 1;
				
				int index00 = baseVertex + majorSegment     * _verticalSegments + minorSegment;
				int index01 = baseVertex + majorSegment     * _verticalSegments + nextMinorSegment;
				int index10 = baseVertex + nextMajorSegment * _verticalSegments + minorSegment;
				int index11 = baseVertex + nextMajorSegment * _verticalSegments + nextMinorSegment;

				if (reverse)
				{
					// first triangle
					indices[index++] = (ushort) index00;
					indices[index++] = (ushort) index11;
					indices[index++] = (ushort) index01;

					// second triangle
					indices[index++] = (ushort) index00;
					indices[index++] = (ushort) index10;
					indices[index++] = (ushort) index11;
				}
				else
				{
					// first triangle
					indices[index++] = (ushort) index00;
					indices[index++] = (ushort) index01;
					indices[index++] = (ushort) index11;

					// second triangle
					indices[index++] = (ushort) index00;
					indices[index++] = (ushort) index11;
					indices[index++] = (ushort) index10;
				}
			}
		}
	}
}