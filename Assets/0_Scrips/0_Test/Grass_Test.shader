﻿Shader "Unlit/Test_GrassClumps"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _BotomColor("BotomColor",Color)=(1,1,1,1)
        _DryColor("DryColor",Color)=(1,1,1,1)
        _BaseMap ("Texture", 2D) = "white" {}
        _AlphaMap("Alpha",2D)="white"{}
        _ClipRange("Clip",Range(0,1))=0.5
        _SpecularColor ("SpecularColor", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        _MaxRotate("MaxRotate",Range(0,10))=3
        _ShadowColor("ShadowColor",Color)=(1,1,1,1)
        _InstanceOffestY("InstanceOffsetY",float)=0.5

    }
    SubShader
    {
 //       Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry"}

        Pass
        {
Tags { "LightMode" = "UniversalForward" }
Cull off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../1_Shaders/ShaderTools/NoiseLib.hlsl"
//��Ӱ
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS : NORMAL;
                float2 uv:TEXCOORD0;
                uint instanceID : SV_InstanceID;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewWS : TEXCOORD2;
                float3 positionWS:TEXCOORD3;
                float3 positionOS:TEXCOORD4;
                uint instanceID : SV_InstanceID;

                float4 shadowCoords : TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)
            half3 _BaseColor;
            half3 _BotomColor;
            half3 _DryColor;
            half4 _SpecularColor;
            half _Smoothness;
            half3 _ShadowColor;
            
            float _Scale;
            float4x4 _MartixX;//����ת����
            float4x4 _MartixY;//����ת��
            float3 _Position;
            float4 wind;
            float _MaxRotate;
            float _InstanceOffestY;

            float _ClipRange;
            CBUFFER_END

            TEXTURE2D(_AlphaMap); SAMPLER(sampler_AlphaMap);

            float4x4 create_martix(float3 pos, float theta)
            {
                float c=cos(theta);
                float s=sin(theta);
                return float4x4(
                 c,-s,0,pos.x,   
                 s,c,0,pos.y,
                0,0,1,pos.z,
                0,0,0,1   );    
            }
float4x4 RotateAroundY( float theta)
{
                float c=cos(theta);
                float s=sin(theta);
                return float4x4(
                 c,0,s,0,   
                 0,1,0,0,
                 -s,0,c,0,
                0,0,0,1   );  
}
float4x4 RotateAroundX(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return float4x4(
        1,  0,  0,  0,
        0,  c, -s,  0,
        0,  s,  c,  0,
        0,  0,  0,  1
    );
}

            #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
            struct GrassClump   
            {
                float3 position;
                float lean;
                float noise;
                float fade;
            };
            StructuredBuffer<GrassClump> clumpsBuffer;
            #endif

            void setup()
            {

             }
            

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);  
                OUT.positionWS=positionWS;
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewWS = GetWorldSpaceViewDir(positionWS);
                OUT.uv=IN.uv;
                OUT.positionOS=IN.positionOS;
                OUT.shadowCoords = float4(1,1,1,1);
                OUT.instanceID=0;

                #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                GrassClump clump=clumpsBuffer[IN.instanceID];
                _Position=clump.position;
                _MartixX=RotateAroundX(clump.noise*_MaxRotate*0.5);//ת���� ֻ��z��
                _MartixY=RotateAroundY(clump.noise*_MaxRotate*0.5);//ת���� ֻ��z��


                 IN.positionOS.xyz=mul(mul(_MartixY,_MartixX),IN.positionOS);
              
                 IN.positionOS.xyz*=_Scale;
                 //shadow
                VertexPositionInputs positions = GetVertexPositionInputs(_Position);
                float4 shadowCoordinates = GetShadowCoord(positions);
                OUT.shadowCoords = shadowCoordinates;
                
                IN.positionOS.xyz+=_Position;
                IN.positionOS.y+=_InstanceOffestY;
               

                positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS=positionWS;
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                OUT.viewWS = GetWorldSpaceViewDir(positionWS);
                OUT.instanceID=IN.instanceID;
OUT.positionOS=IN.positionOS;


                #endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {

    half mask = SAMPLE_TEXTURE2D(_AlphaMap, sampler_AlphaMap, IN.uv).r;
               clip(mask-_ClipRange);

               half3 GrassColor=lerp(_BaseColor,_BotomColor,IN.uv.y);
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);
#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
               GrassClump clump=clumpsBuffer[IN.instanceID];
               GrassColor=lerp(GrassColor,_DryColor,clump.fade);

#endif
               Light light = GetMainLight();
               half3 lightColor = light.color * light.distanceAttenuation;
               half smoothness = exp2(10 * _Smoothness + 1);
               half3 normalWS = normalize(IN.normalWS);
               half3 viewWS =  SafeNormalize(IN.viewWS);

              
               half3 totalColor = lerp((_ShadowColor+shadowAmount)*GrassColor,GrassColor,shadowAmount); 
                
          
               return half4(totalColor,1);
            }

            ENDHLSL
        }

//��Ӱpass
//pass
//    {
//Name "ShadowCaster"
//Tags {"LightMode"="ShadowCaster"}
//HLSLPROGRAM
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//#pragma vertex vert
//#pragma fragment frag
////#pragma shader_feature_ALPHATEST_ON
//struct a2v{
//float4 vertex:POSITION;
//float2 uv:TEXCOORD0;
//};

//struct ShadowVaryings{
//float4 vertex:SV_POSITION;
//float2 uv:TEXCOORD0;}
//;

//ShadowVaryings vert(a2v v)
//{
//    ShadowVaryings o=(ShadowVaryings)0;
//    o.vertex=TransformObjectToHClip(v.vertex.xyz);
//    o.uv=v.uv;
//        return o;
//}
//real4 frag(ShadowVaryings i):SV_Target
//{
//        return 0;
//}
//ENDHLSL
//}
}
}
