using System.Collections;
using System.Collections.Generic;
using UnityEngine;


    public class GrassClumps : MonoBehaviour
    {
        struct GrassClump
        {
            public Vector3 position;
            public float lean;
            public float noise;
            public float fade;
            public GrassClump(Vector3 pos)
            {
                position.x = pos.x;
                position.y = pos.y;
                position.z = pos.z;
                lean = 0;
                noise = Random.Range(0.5f, 1) * 2 - 1;
                fade = Random.Range(0.5f, 1);
            }
        }
        int SIZE_GRASS_CLUMP = 6 * sizeof(float);

        private Mesh blade;

        //�����ģ����Ϣ
        [Range(0, 10)]
        public float Height = 2;

        public Material material;
        public ComputeShader shader;
        [Range(0, 1)]
        public float density = 0.8f;
        [Range(0.1f, 50)]
        public float scale = 0.2f;
        [Range(10, 45)]
        public float maxLean = 25;

        //wind
        [Range(0, 2)]
        public float windSpeed;
        [Range(0, 360)]
        public float windDirection;
        [Range(0, 1)]
        public float windScale;

        [Range(0, 2)]
        public float HeightAffect;

        ComputeBuffer clumpsBuffer;
        ComputeBuffer argsBuffer;
        GrassClump[] clumpsArray;
        uint[] argsArray = new uint[] { 0, 0, 0, 0, 0 };
        Bounds bounds;
        int timeID;
        int groupSize;
        int kernelLeanGrass;

        Transform PlayerTrans;
        Vector3 deltaPos = Vector3.zero;
        Vector3 playerPos1;
        public float MaxGrassDistance;
    //    public Mesh Blade;
        Mesh Blade
        {
            get
            {
                Mesh mesh;
                if (blade != null)
                {
                    mesh = blade;
                }
                else
                {
                    mesh = new Mesh();

                    float rowHeight = Height / 4;
                    float halfWidth = Height / 10;
                    Vector3[] Vertices = {
        new Vector3(-halfWidth, 0, 0),
        new Vector3 (halfWidth, 0, 0 ),
        new Vector3(-halfWidth,rowHeight,0),
        new Vector3(halfWidth,rowHeight,0),
        new Vector3(-halfWidth*0.8f, rowHeight*2, 0),
        new Vector3 (halfWidth*0.8f, rowHeight*2, 0 ),
        new Vector3(-halfWidth*0.6f,rowHeight*3,0),
        new Vector3(halfWidth*0.6f,rowHeight*3,0),
        new Vector3(0,rowHeight * 4,0)
        };

                    Vector3 normal = new Vector3(0, 0, 1);
                    Vector3[] Normals = {
            normal,
            normal,
            normal,
            normal,
            normal,
            normal,
            normal,
            normal,
            normal
        };
                    Vector2[] uvs = {
         new Vector2(0,0),
         new Vector2(1,0),
         new Vector2(0,0.25f),
         new Vector2(1,0.25f),
         new Vector2(0.05f,0.5f),
         new Vector2(0.95f,0.5f),
         new Vector2(0.1f,0.75f),
         new Vector2(0.9f,0.75f),
         new Vector2(0.5f,1)
        };

                    int[] indicies =
                        {
            0,1,2,1,3,2,
            2,3,4,3,5,4,
            4,5,6,5,7,6,
            6,7,8
        };

                    mesh.vertices = Vertices;
                    mesh.normals = Normals;
                    mesh.uv = uvs;
                    mesh.SetIndices(indicies, MeshTopology.Triangles, 0);
                }
                return mesh;
            }
        }
        public Mesh StrokePlane;
        void Start()
        {
//        PlayerTrans = GameObject.Find("Player").transform;
  //      if (PlayerTrans == null) Debug.Log("Not Found Player��");
 //       playerPos1 = PlayerTrans.position;

            bounds = new Bounds(Vector3.zero, new Vector3(1200,1200, 1200));
            blade = StrokePlane;
         //   blade = Blade;
        material.enableInstancing = true;
        InitShader();
            
        }

        void InitShader()
        {
            //Get bounds size
            MeshFilter mf = GetComponent<MeshFilter>();
            Bounds bounds = mf.sharedMesh.bounds;
            //       Debug.Log(mf.sharedMesh.name);
            Vector3 clumps = bounds.extents;

                  Debug.Log("clumps1 " + clumps.x + "," + clumps.z);
            Vector3 vec = (transform.localScale / 0.1f) * density;
            clumps.x *= vec.x;
            clumps.z *= vec.z;

            int total = (int)(clumps.x * clumps.z);
                Debug.Log("total" + total);
                Debug.Log("clumps2 " + clumps.x+","+ clumps.z);
            kernelLeanGrass = shader.FindKernel("LeanGrass1");

            uint threadGroupSize;
            shader.GetKernelThreadGroupSizes(kernelLeanGrass, out threadGroupSize,
                out _, out _);
            groupSize = Mathf.CeilToInt((float)total / (float)threadGroupSize);
            int count = groupSize * (int)threadGroupSize;
                Debug.Log("groupsize" + groupSize);
                Debug.Log("threadgroupsize" + threadGroupSize);
               Debug.Log("Extends x"+bounds.extents.x);
               Debug.Log("Extends z"+bounds.extents.z);

            InitPos(count, bounds);

            clumpsBuffer = new ComputeBuffer(count, SIZE_GRASS_CLUMP,ComputeBufferType.Structured);
            clumpsBuffer.SetData(clumpsArray);

            shader.SetBuffer(kernelLeanGrass, "clumpsBuffer", clumpsBuffer);
            timeID = Shader.PropertyToID("time");
            shader.SetFloat("maxLean", maxLean * Mathf.PI / 180);

            //wind direction. x,y is direction, z ins sppeed, w is wind scale
            float theata = windDirection / 180 * Mathf.PI;
            float windx = Mathf.Cos(theata);
            float windy = Mathf.Sin(theata);
            Vector4 wind = new Vector4(windx, windy, windSpeed, windScale);

            shader.SetVector("wind", wind);
            material.SetVector("wind", wind);

            material.SetBuffer("clumpsBuffer", clumpsBuffer);
            material.SetFloat("_Scale", scale);

            argsArray[0] = blade.GetIndexCount(0);//returns vertex count in the first sub mesh in mesh objects
            argsArray[1] = (uint)count;//number of instances
            argsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);

            argsBuffer.SetData(argsArray);

              uint[] debugArgs = new uint[5];
                argsBuffer.GetData(debugArgs);
                Debug.Log("argsBuffer: " + string.Join(",", debugArgs));

    }

        void InitPos(int count, Bounds bounds)
        {
            gameObject.AddComponent<MeshCollider>();

            clumpsArray = new GrassClump[count];

            RaycastHit hit;
            Vector3 v = new Vector3();
            v.y = bounds.center.y + bounds.extents.y;//����ռ�������ߵ�
            v = transform.TransformPoint(v);//ת������������
            float castY = v.y;
            v.Set(0, 0, 0);
            v.y = bounds.center.y - bounds.extents.y;
            v = transform.TransformPoint(v);
            float minY = v.y;
            float range = castY - minY;
            castY += 10;

            int loopcount = 0;
            int index = 0;

            while (index < count && loopcount < (count * 10))
            {
                loopcount++;
                //����mesh����λ��
                Vector3 pos = new Vector3(Random.value * bounds.extents.x * 2 -
                   bounds.extents.x + bounds.center.x, 0,
                   Random.value * bounds.extents.z * 2 -
                   bounds.extents.z + bounds.center.z);
                pos = transform.TransformPoint(pos);
                pos.y = castY;


                //      Debug.Log("castY" + pos.y+"minY"+minY);
                if (Physics.Raycast(pos, Vector3.down, out hit))
                {
                    pos.y = hit.point.y;
                    //  Debug.Log("castY" + pos.y + "minY" + minY);

                    float deltaHeight = ((pos.y - minY) / range * HeightAffect);
                    if (float.IsNaN(deltaHeight)) deltaHeight = 0;//�ж�һ���Ƿ�������0
                    if (Random.value > deltaHeight)
                    {
                        GrassClump clump = new GrassClump(pos);
                                   //         Debug.Log("ClumpPos" + pos.x + "," + pos.y + "," + pos.z);
                        clumpsArray[index++] = clump;
                                   //        Debug.Log("index" + index);
                    }
                }
            }

        }

        void updateWind()
        {
            float theata = windDirection / 180 * Mathf.PI;
            float windx = Mathf.Cos(theata);
            float windy = Mathf.Sin(theata);
            Vector4 wind = new Vector4(windx, windy, windSpeed, windScale);


            shader.SetVector("wind", wind);
            material.SetVector("wind", wind);

        }
        // Update is called once per frame

        void Update()
        {
//            deltaPos = PlayerTrans.position - playerPos1;
            updateWind();
            shader.SetFloat(timeID, Time.time);
           // shader.Dispatch(kernelLeanGrass, groupSize, 1, 1);
//            shader.SetVector("deltaPos", deltaPos);
//            playerPos1 = PlayerTrans.position;
            Graphics.DrawMeshInstancedIndirect(blade, 0, material, bounds, argsBuffer);
        }



        private void OnDestroy()
        {
            clumpsBuffer.Release();
            argsBuffer.Release();
        }
    }

