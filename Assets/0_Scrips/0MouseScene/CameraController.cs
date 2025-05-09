using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class CameraController : MonoBehaviour
{
    public GameObject target;//Ŀ������
    public Vector2 Angle;
    Vector3 offset;//��������ƫ����
    void Start()
    {
        //��֤���������Ŀ�����壬��z����ת����0
        transform.LookAt(target.transform.position);
        
      //  transform.eulerAngles = new Vector3(transform.eulerAngles.x, transform.eulerAngles.y, 0);
        transform.eulerAngles = new Vector3(Angle.x, Angle.y, 0);
        //�õ������������֮��ĳ�ʼƫ����
        offset = target.transform.position - transform.position;
    }

    void LateUpdate()
    {
        Rotate();
        Rollup();
        Follow();
    }

    //��������桢�������Ź���:

    public float zoomSpeed = 1f; // ��Ұ�������ٶ�
    float zoom;//���ֹ�����
    void Follow()
    {
        //��Ұ����
        zoom = Input.GetAxis("Mouse ScrollWheel") * zoomSpeed; // ��ȡ���ֹ�����
        if (zoom != 0) // ����й���
        {
            offset -= zoom * offset;
        }
        //��ͷ����
        transform.position = target.transform.position - offset;
    }

    //������ת��������ת����:

    public float rotationSpeed = 500f;//�������ת�ٶ�
    private bool isRotating, lookup = false;
    float mousex, mousey;
    void Rotate()
    {
        if (Input.GetMouseButtonDown(1))//��������Ҽ�
        {
            isRotating = true;
        }
        if (Input.GetMouseButtonUp(1))
        {
            isRotating = false;
        }
        if (isRotating)
        {
            //�õ����x�����ƶ�����
            mousex = Input.GetAxis("Mouse X") * rotationSpeed * Time.deltaTime;
            //��ת���λ����Ŀ�����崦����������������ϵ��y��
            transform.RotateAround(target.transform.position, Vector3.up, mousex);
            //ÿ����ת�����ƫ����
            offset = target.transform.position - transform.position;
        }
    }
    void Rollup()
    {
        if (Input.GetMouseButtonDown(2))//��������м�
        {
            lookup = true;
        }
        if (Input.GetMouseButtonUp(2))
        {
            lookup = false;
        }
        if (lookup)
        {
            //�õ����y�����ƶ�����
            mousey = Input.GetAxis("Mouse Y") * rotationSpeed * Time.deltaTime;
            //��ת���λ����Ŀ�����崦���������������x��
            transform.RotateAround(target.transform.position, transform.right, mousey);
            //ÿ����ת�����ƫ����
            offset = target.transform.position - transform.position;
        }

    }
}
