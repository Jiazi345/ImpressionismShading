using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ESCExit : MonoBehaviour
{

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            // �ڱ༭���в��˳������ڹ����������˳�
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }
    }
}
