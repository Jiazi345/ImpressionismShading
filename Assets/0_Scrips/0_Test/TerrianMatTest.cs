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
   
        if (material != null) Debug.Log("���ʼ��سɹ���");
        else Debug.LogError("���ʶ�ʧ��");
    }

}
