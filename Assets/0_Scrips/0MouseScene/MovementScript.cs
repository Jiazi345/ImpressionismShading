using UnityEngine;

public class MovementScript : MonoBehaviour
{
    /***������������***/
   public float walkSpeed = 5;
    float runSpeed = 10;
    Animator animator;//����һ��animator�����Դ���ֵ(��start()�����︳ֵ)
    public float turnSmoothTime = 0.13f;//�趨��ɫת��ƽ��ʱ��
    float turnSmoothVelocity;//ƽ��������Ҫ��ôһ��ƽ�����ٶ�, ����ҪΪ����ֵ, ������Ҫ�������������������
    public float speedSmoothTime = 0.13f;//����ƽ���ٶ�
    float speedSmoothVelocity;
    float currentSpeed;  

    

    public Transform cameraT;

    void Start()
    {
        animator = GetComponent<Animator>();
        //cameraT = Camera.main.transform;
    }

    void Update()
    {
        Shader.SetGlobalVector("_PlayerPositionWS", transform.position);
        //***WASD����***//
        Vector2 input = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));//��ȡ��������

        Vector2 inputDir = input.normalized;//�������Ƿ���һ����λ���ȵ��������

        //***��ɫ�ƶ�����***//
        bool running = Input.GetKey(KeyCode.LeftShift);//������shift��bool����running����1
        float targetSpeed = ((running) ? runSpeed : walkSpeed) * inputDir.magnitude;

        //Vector3 PlayerMovement = new Vector3(hor,0f,ver)*targetSpeed*Time.deltaTime;
        transform.Translate(transform.forward * targetSpeed * Time.deltaTime, Space.World);//����Ϸ��ɫλ���ƶ�
                                                                                           //transform.Translate(PlayerMovement,Space.Self);

        //***ת�򲿷�***//
        if (inputDir != Vector2.zero)
        //��������Ϊ�����Զ�����0, ��Ҳ������ʱ���ɫ�ͻ��Զ�����������, ���Լ�һ���ж�, ����Ϊ0�Ļ�����û����, ���ԾͲ�Ҫת��
        {//ƽ��ת�����
            float targetRotation = Mathf.Atan2(inputDir.x, inputDir.y) * Mathf.Rad2Deg + cameraT.eulerAngles.y;//����Ǹ�����Ҽ��������������Ŀ��ת��Ƕ�(y���)
            transform.eulerAngles = Vector3.up * Mathf.SmoothDampAngle(transform.eulerAngles.y, targetRotation, ref turnSmoothVelocity, turnSmoothTime);
            //�ϱ���������ǽǶȽ���, Ҳ���Խ�ƽ����, ���ref��ʲô��˼������, �Ժ�϶��ܽ��, �������turnSmoothVelocity��ʲô��˼�Ժ������֪��, ������һʱ<br>��������//���ref�������ò��� , ѧ��C#��֪���� , ����������ѷ����ڵ����ݸ��������
        }

        /***λ���˶�����***/
        //���inputDir�Ǹ���λ����,inputDir.magnitude�����ĳ���,���κ������ʱ��λ�����ĳ��ȶ���1, �ڼ���û�������ʱ��������Ⱦ���0
        //��ʵ֮���Գ���������Ⱦ���Ϊ���ܹ������û�������ʱ����ٶȱ��0
        //currentSpeed = Mathf.SmoothDamp(currentSpeed,targetSpeed,ref speedSmoothVelocity,speedSmoothTime);
        //�������������SmoothDamp�Լ��ϱߵ�SmoothDampAngleһ��, ���ǵĵ�һ��������ʵ�Ǳ���ֵ��, ֱ�Ӱѿղ�������ȥ, ���ܻ�ú��ʵ�ֵ



        float animationSpeedPercent = ((running) ? 0.75f : 0.25f) * inputDir.magnitude;//ͨ����������������״̬�����Ʊ�����ֵ
        animator.SetFloat("speedPercent", animationSpeedPercent, speedSmoothTime, Time.deltaTime);
        //1. ͨ������animator������setfloat���������״̬����speedPercent������ֵ
        //2. ����������ĸ�����, ���������Դ���ƽ������, ����ͨ�������������ֵ��ʵ�ֶ���״̬���Զ�ƽ������



    }
}


