using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateStroke : MonoBehaviour
{
    public ComputeShader shader;
    public Material Material;
    [Range(0, 10)]
    public int MatCount;
    public float StrokeOffset;
    public float StrokeScale;
    public Texture2D flowMap;
     public float scaleParameter=1;
    struct Stroke
    {
        public Vector3 Position;
        public Vector3 Normals;
        public Vector2 UV;
        public Vector2 lightmapuv;
        public float noise;
        public uint matIndex;
        public float Scale;//depends on their distance with neighbor vertex 

        public Stroke(Vector3 pos,Vector3 normal,Vector2 uv,uint index,float scale,Vector2 uv2)
        {
            Position = pos;
            noise = Random.Range(0.5f, 1) * 2 - 1;
            Normals = normal;
            matIndex = index;
            UV=uv;
            lightmapuv=uv2;
            Scale=scale;
        }
    }
    
    int SIZE_STOCK =12 * sizeof(float)+sizeof(uint);
    public Mesh StrokeMesh;
  //  public Mesh ParentMesh;

    [SerializeField]
    private List<Mesh> ParentMeshs;
    ComputeBuffer strokesBuffer;
    ComputeBuffer argsBuffer;
    Stroke[] Strokes;
    uint[] argsArray = new uint[] { 0, 0, 0, 0, 0 };

    int groupSize;
    int kernelStroke;
    Bounds drawBounds;

    Stroke[] strokeArray;
    List<Stroke> strokeList;
    int strokeCount;
    Bounds bounds;
    private void Start()
    {
        strokeCount=0;
        bounds = new Bounds(Vector3.zero, new Vector3(2000, 2000, 2000));
        ParentMeshs=new List<Mesh>();
        MeshFilter[] meshs=GetComponentsInChildren<MeshFilter>();
        strokeList = new List<Stroke>();

        foreach(MeshFilter meshfilter in meshs)
        {
             Mesh mesh = meshfilter.sharedMesh;
             ParentMeshs.Add(meshfilter.mesh);
            if (mesh == null)
        {
            Debug.LogWarning("子物体 " + meshfilter.name + " 没有 mesh，跳过");
            continue;
        }
            InitStocks(meshfilter.mesh,meshfilter.transform);

        }
        InitBuffer();

    }

    
    void InitStocks(Mesh ParentMesh, Transform meshTransform)
    {
        if (ParentMesh.vertices == null || ParentMesh.normals == null || ParentMesh.uv == null||ParentMesh.uv2==null)
{
    Debug.LogError("Mesh 缺少 vertices/normals/uv");
    return;
}

        //Add neighbor vertex distance of parent mesh
        Dictionary<int, HashSet<int>> adjacencyMap = new Dictionary<int, HashSet<int>>();
        for (int i = 0; i < ParentMesh.triangles.Length; i += 3)
        {
            int i0 = ParentMesh.triangles[i];
            int i1 = ParentMesh.triangles[i + 1];
            int i2 = ParentMesh.triangles[i + 2];

            void AddNeighbor(int from, int to)
            {
                if (!adjacencyMap.ContainsKey(from))
                    adjacencyMap[from] = new HashSet<int>();
                adjacencyMap[from].Add(to);
            }

            AddNeighbor(i0, i1); AddNeighbor(i0, i2);
            AddNeighbor(i1, i0); AddNeighbor(i1, i2);
            AddNeighbor(i2, i0); AddNeighbor(i2, i1);
        }

        strokeCount += ParentMesh.vertexCount;
      //  strokeArray = new Stroke[strokesCount];
      int vertCount=ParentMesh.vertexCount;
       
        for(int i=0;i<vertCount;i++)
        {
            
            Vector3 pos =meshTransform.TransformPoint(ParentMesh.vertices[i]);//world space pos
            Vector3 normal = meshTransform.TransformDirection(ParentMesh.normals[i]);
            Debug.Log("Scale"+meshTransform.lossyScale);
            uint mat = (uint)Random.Range(0, MatCount);
            Vector2 uv=ParentMesh.uv[i];
            Vector2 uv2=ParentMesh.uv2[i];
    //        Color flowColor = flowMap.GetPixelBilinear(uv.x, uv.y); // sample in [0,1] 
//            Vector2 flowDir = new Vector2(flowColor.r, flowColor.g); // flow map

            float scale=1;
            float averdist=0;
            if(adjacencyMap.ContainsKey(i))               
           {         
                foreach (int neighbor in adjacencyMap[i])
                {
                    Vector3 v1 = ParentMesh.vertices[neighbor];
                    float dist = Vector3.Distance(ParentMesh.vertices[i], v1);
              //      Debug.Log($"Vertex {i} <-> {neighbor} distance: {dist}");
                    averdist+=dist;
                }
                averdist/=adjacencyMap[i].Count;
            }
            scale+=averdist*scaleParameter*1000;
            Stroke stroke = new Stroke(pos,normal,uv,mat,scale,uv2);
         //   strokeArray[i] = stroke;
         strokeList.Add(stroke);
         //   Debug.Log("Stroke Pos:"+pos.x +" " + pos.y + " " + pos.z);
        }

    }

    void InitBuffer()
    {
        strokeArray=strokeList.ToArray();
    strokesBuffer = new ComputeBuffer(strokeCount, SIZE_STOCK);
        Debug.Log("Init"+strokeCount);
         //  Debug.Log("strokemesh "+StrokeMesh.GetIndexCount(0));
        argsArray[0] =StrokeMesh.GetIndexCount(0);//returns vertex count in the first sub mesh in mesh objects
        argsArray[1] = (uint)strokeCount;//number of instances
        argsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(argsArray);

        strokesBuffer.SetData(strokeArray);
        Material.SetBuffer("strokes",strokesBuffer);   
        Material.enableInstancing = true;
    }

    private void Update()
    {
        Material.SetFloat("_StrokeOffset", StrokeOffset);
        Material.SetFloat("_StrokeScale", StrokeScale);
        Graphics.DrawMeshInstancedIndirect(StrokeMesh, 0, Material, bounds, argsBuffer);
    }
    private void OnDestroy()
    {
        argsBuffer.Release();
        strokesBuffer.Release();
    }
}
