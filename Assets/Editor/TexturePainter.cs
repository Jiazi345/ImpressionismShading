using UnityEngine;
using UnityEditor;
using System.IO;

public class TexturePainter : EditorWindow
{
    private Texture2D texture; // Ŀ����ͼ
    private Color drawColor = Color.black; // ��ǰ������ɫ
    private int brushSize = 5; // ���ʴ�С
    private Vector2 lastMousePos = Vector2.zero;

    [MenuItem("Tools/Texture Painter")]
    public static void ShowWindow()
    {
        GetWindow<TexturePainter>("Texture Painter");
    }

    private void OnGUI()
    {
        GUILayout.Label("Texture Painter", EditorStyles.boldLabel);

        // ѡ����ͼ
        texture = (Texture2D)EditorGUILayout.ObjectField("Texture", texture, typeof(Texture2D), false);

        // ������ɫ�ʹ�С����
        drawColor = EditorGUILayout.ColorField("Brush Color", drawColor);
        brushSize = EditorGUILayout.IntSlider("Brush Size", brushSize, 1, 50);

        if (texture != null)
        {
            GUILayout.Label("Draw on Texture Below:");
            GUILayout.Space(10);

            Rect textureRect = GUILayoutUtility.GetRect(texture.width, texture.height, GUILayout.ExpandWidth(false), GUILayout.ExpandHeight(false));
            EditorGUI.DrawPreviewTexture(textureRect, texture);

            // ������������
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

        // ���Ƶ�����
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

        // ����Ϊ PNG �ļ�
        string path = EditorUtility.SaveFilePanel("Save Texture", "", "Texture.png", "png");
        if (!string.IsNullOrEmpty(path))
        {
            byte[] pngData = texture.EncodeToPNG();
            File.WriteAllBytes(path, pngData);
            Debug.Log($"Texture saved to {path}");
        }
    }
}
