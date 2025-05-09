#ifndef NOISE_LIB
#define NOISE_LIB

#include "HashLib.hlsl"

float valueNoise(float2 uv)
{
    float2 intPos = floor(uv); //uv����, ȡ uv ����ֵ
    float2 fracPos = frac(uv); //ȡ uv С��ֵ

    //��ά��ֵȨ�أ�һ������smoothstep�ĺ�������Hermit��ֵ������Ҳ��S���ߣ�S(x) = -2 x^3 + 3 x^2
    //����Hermit��ֵ���ԣ������ڱ�֤��������Ļ����ϱ�֤��ֵ�����ĵ����ڲ�ֵ����Ϊ0���������ṩ��ƽ����
    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos); 

    //�ķ�ȡ�㣬����intPos�ǹ̶��ģ�����դ���ˣ�ͬһ�������ĵ�ֵ��ͬ��ֻ��С�����ֲ�ͬ������ֵ��
    float va = hash2to1( intPos + float2(0.0, 0.0) ); 
    float vb = hash2to1( intPos + float2(1.0, 0.0) );
    float vc = hash2to1( intPos + float2(0.0, 1.0) );
    float vd = hash2to1( intPos + float2(1.0, 1.0) );

    //lerp��չ����ʽ����ȫ������lerp(a,b,c)Ƕ��ʵ��
    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;
    float value = k0 + k1 * u.x + k2 * u.y + k4 * u.x * u.y;

    return value;
}

float2 hash2d2(float2 uv)
{
    const float2 k = float2( 0.3183099, 0.3678794 );
    uv = uv * k + k.yx;
    return -1.0 + 2.0 * frac( 16.0 * k * frac( uv.x * uv.y*(uv.x+uv.y)));
}

float perlinNoise(float2 uv)
{
    float2 intPos = floor(uv);
    float2 fracPos = frac(uv);

    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos);  

    float2 ga = hash2d2(intPos + float2(0.0,0.0)); 
    float2 gb = hash2d2(intPos + float2(1.0,0.0));
    float2 gc = hash2d2(intPos + float2(0.0,1.0));
    float2 gd = hash2d2(intPos + float2(1.0,1.0));

    float va = dot(ga, fracPos - float2(0.0,0.0));
    float vb = dot(gb, fracPos - float2(1.0,0.0));
    float vc = dot(gc, fracPos - float2(0.0,1.0));
    float vd = dot(gd, fracPos - float2(1.0,1.0));

    float value = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd);

    return value;
}
float simpleNoise(float2 uv)
{
    //transform from triangle to quad
    const float K1 = 0.366025404; // (sqrt(3)-1)/2; //quad ת 2���������� �Ĺ�ʽ����
    //transform from quad to triangle
    const float K2 = 0.211324865; // (3 - sqrt(3))/6;

    float2 quadIntPos = floor(uv + (uv.x + uv.y)*K1);
    float2 vecFromA = uv - quadIntPos + (quadIntPos.x + quadIntPos.y) * K2;

    float IsLeftHalf = step(vecFromA.y,vecFromA.x);  //�ж�����
    float2  quadVertexOffset = float2(IsLeftHalf,1.0 - IsLeftHalf);

    float2  vecFromB = vecFromA - quadVertexOffset + K2;
    float2  vecFromC = vecFromA - 1.0 + 2.0 * K2;

    //˥������
    float3  falloff = max(0.5 - float3(dot(vecFromA,vecFromA), dot(vecFromB,vecFromB), dot(vecFromC,vecFromC)), 0.0);

    float2 ga = hash22(quadIntPos + 0.0);
    float2 gb = hash22(quadIntPos + quadVertexOffset);
    float2 gc = hash22(quadIntPos + 1.0);

    float3 simplexGradient = float3(dot(vecFromA,ga), dot(vecFromB,gb), dot(vecFromC, gc));
    float3 n = falloff * falloff * falloff * falloff * simplexGradient;
    return dot(n, float3(70,70,70));
}
float voronoiNoise(float2 uv)
{
    float dist = 16;
    float2 intPos = floor(uv);
    float2 fracPos = frac(uv);

    for(int x = -1; x <= 1; x++) //3x3�Ź������
    {
        for(int y = -1; y <= 1 ; y++)
        {
            //hash22(intPos + float2(x,y)) �൱��offset������Ϊ����Χ9�������е�ĳһ��������
            //float2(x,y) �൱����Χ�Ÿ���root
            //��û�� offset����ô�����ǹ����ľ��볡
            //���û�� root���൱�����Լ��ľ���Χ�����������㣬һ�����Ӿ��оŸ�������
            float d = distance(hash22(intPos + float2(x,y)) +  float2(x,y), fracPos); //fracPos��Ϊ�����㣬hash22(intPos)��Ϊ���ɵ㣬������dist
            dist = min(dist, d);
        }
    }
    return dist;
}
float FBMvalueNoise(float2 uv)
{
    float value = 0;
    float amplitude = 0.5;
    float frequency = 0;

    for (int i = 0; i < 8; i++) 
    {
        value += amplitude * valueNoise(uv); //ʹ����򵥵�value���������Σ�����ͬ��
        uv *= 2.0;
        amplitude *= .5;
    }
    return value;
}
#endif