using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ESCExit : MonoBehaviour
{

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            // 在编辑器中不退出，但在构建后正常退出
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }
    }
}
