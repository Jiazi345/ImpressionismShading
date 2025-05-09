using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrianMatTest : MonoBehaviour
{
    private void Awake()
    {
     
     Debug.Log(Shader.Find("Terrian/triplanar"));
        
    }
    void Start()
    {
        var material = Resources.Load<Material>("Land");
   
        if (material != null) Debug.Log("材质加载成功！");
        else Debug.LogError("材质丢失！");
    }

}
