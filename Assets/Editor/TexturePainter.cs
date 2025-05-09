using UnityEngine;
using UnityEditor;
using System.IO;

public class TexturePainter : EditorWindow
{
    private Texture2D texture; // 目标贴图
    private Color drawColor = Color.black; // 当前画笔颜色
    private int brushSize = 5; // 画笔大小
    private Vector2 lastMousePos = Vector2.zero;

    [MenuItem("Tools/Texture Painter")]
    public static void ShowWindow()
    {
        GetWindow<TexturePainter>("Texture Painter");
    }

    private void OnGUI()
    {
        GUILayout.Label("Texture Painter", EditorStyles.boldLabel);

        // 选择贴图
        texture = (Texture2D)EditorGUILayout.ObjectField("Texture", texture, typeof(Texture2D), false);

        // 画笔颜色和大小设置
        drawColor = EditorGUILayout.ColorField("Brush Color", drawColor);
        brushSize = EditorGUILayout.IntSlider("Brush Size", brushSize, 1, 50);

        if (texture != null)
        {
            GUILayout.Label("Draw on Texture Below:");
            GUILayout.Space(10);

            Rect textureRect = GUILayoutUtility.GetRect(texture.width, texture.height, GUILayout.ExpandWidth(false), GUILayout.ExpandHeight(false));
            EditorGUI.DrawPreviewTexture(textureRect, texture);

            // 检测鼠标点击绘制
            if (Event.current.type == EventType.MouseDown || Event.current.type == EventType.MouseDrag)
            {
                Vector2 mousePos = Event.current.mousePosition;
                if (textureRect.Contains(mousePos))
                {
                    Vector2 localPos = mousePos - new Vector2(textureRect.x, textureRect.y);
                    DrawOnTexture((int)localPos.x, (int)localPos.y);
                }
            }
        }

        if (GUILayout.Button("Save Texture"))
        {
            SaveTexture();
        }
    }

    private void DrawOnTexture(int x, int y)
    {
        if (texture == null) return;

        // 绘制到纹理
        for (int i = -brushSize; i <= brushSize; i++)
        {
            for (int j = -brushSize; j <= brushSize; j++)
            {
                if (i * i + j * j <= brushSize * brushSize)
                {
                    int px = Mathf.Clamp(x + i, 0, texture.width - 1);
                    int py = Mathf.Clamp(y + j, 0, texture.height - 1);
                    texture.SetPixel(px, texture.height - py - 1, drawColor);
                }
            }
        }

        texture.Apply();
        Repaint();
    }

    private void SaveTexture()
    {
        if (texture == null)
        {
            Debug.LogWarning("No texture to save!");
            return;
        }

        // 保存为 PNG 文件
        string path = EditorUtility.SaveFilePanel("Save Texture", "", "Texture.png", "png");
        if (!string.IsNullOrEmpty(path))
        {
            byte[] pngData = texture.EncodeToPNG();
            File.WriteAllBytes(path, pngData);
            Debug.Log($"Texture saved to {path}");
        }
    }
}
