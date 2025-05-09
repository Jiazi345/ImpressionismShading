Shader "TWShader/Skybox"
{
    Properties
    {
    [NoScaleOffset] _SunZenithGrad ("Sun-Zenith gradient", 2D) = "white" {}
    [NoScaleOffset] _ViewZenithGrad ("View-Zenith gradient", 2D) = "white" {}
    [NoScaleOffset] _SunViewGrad ("Sun-View gradient", 2D) = "white" {}
    [NoScaleOffset] _CloudTex ("Cloud", 2D) = "white" {}
    [NoScaleOffset] _CloudNoise1 ("CloudNoise1", 2D) = "white" {}
    [NoScaleOffset] _CloudNoise2 ("CloudNoise2", 2D) = "white" {}
    [NoScaleOffset] _Cloudflow ("CloudFlow", 2D) = "white" {}
    _NoiseScale ("NoiseScale",float)=1
    _CloudClampmut ("CloudClampmut",float)=1
    _CloudClampadd ("CloudClampadd",float)=1
    _CloudSpeed("CloudSpeed",range(0,10))=1
    _CloudColor1("CloudColor1",COLOR)=(1,1,1,1)
    _CloudColor2("CloudColor2",COLOR)=(1,1,1,1)
    _CloudCut("CloudCut",range(0,1))=0.5
    _Fuzziness("Fuzziness",float)=1
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 posOS    : POSITION;
                float3 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS        : SV_POSITION;
                float3 uv:TEXCOORD0;
                float3 viewDirWS    : TEXCOORD1;
                float3 posWS:TEXCOORD2;
            };

            v2f Vertex(Attributes IN)
            {
                v2f OUT = (v2f)0;
    
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.posOS.xyz);
    
                OUT.posCS = vertexInput.positionCS;
                OUT.posWS=vertexInput.positionWS;
                OUT.viewDirWS = vertexInput.positionWS;
                OUT.uv=IN.uv;
                return OUT;
            }

TEXTURE2D(_SunZenithGrad);      SAMPLER(sampler_SunZenithGrad);
TEXTURE2D(_ViewZenithGrad);     SAMPLER(sampler_ViewZenithGrad);
TEXTURE2D(_SunViewGrad);        SAMPLER(sampler_SunViewGrad);
TEXTURE2D(_CloudTex);        SAMPLER(sampler_CloudTex);
TEXTURE2D(_CloudNoise1);        SAMPLER(sampler_CloudNoise1);
TEXTURE2D(_CloudNoise2);        SAMPLER(sampler_CloudNoise2);
TEXTURE2D(_Cloudflow);        SAMPLER(sampler_Cloudflow);
            float3 _SunDir, _MoonDir;
            float _NoiseScale;
            float  _CloudClampmut;
            float  _CloudClampadd;
            float _CloudSpeed;
            float4  _CloudColor1;
            float4  _CloudColor2;
            float _CloudCut;
            float _Fuzziness;
            float4 Fragment (v2f IN) : SV_TARGET
            {
                float3 viewDir = normalize(IN.viewDirWS);

                float sunViewDot = dot(_SunDir, viewDir);
                float sunZenithDot = _SunDir.y;
                float viewZenithDot = viewDir.y;
                float sunMoonDot = dot(_SunDir, _MoonDir);

                float sunViewDot01 = (sunViewDot + 1.0) * 0.5;
                float sunZenithDot01 = (sunZenithDot + 1.0) * 0.5;

                float3 sunZenithColor = SAMPLE_TEXTURE2D(_SunZenithGrad, sampler_SunZenithGrad, float2(sunZenithDot01, 0.5)).rgb;

                float3 viewZenithColor = SAMPLE_TEXTURE2D(_ViewZenithGrad, sampler_ViewZenithGrad, float2(sunZenithDot01, 0.5)).rgb;
                float vzMask = pow(saturate(1.0 - viewZenithDot), 4);

                float3 sunViewColor = SAMPLE_TEXTURE2D(_SunViewGrad, sampler_SunViewGrad, float2(sunZenithDot01, 0.5)).rgb;
                float svMask = pow(saturate(sunViewDot), 4);

//Cloud
float2 skyUV= IN.posWS.xz/IN.posWS.y;    
//flowMap
float3 flowmap=SAMPLE_TEXTURE2D(_Cloudflow,sampler_Cloudflow,IN.uv*_NoiseScale);
float2 flowdir=flowmap.xy*2-1;
float prase0=frac(_Time*_CloudSpeed);
float prase1=frac(_Time*_CloudSpeed+0.5);
float cloudLerp=abs((0.5-prase0)/0.5);

float3 baseNoise_0=SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,skyUV*_NoiseScale+prase0*flowdir);
float3 noise1_0=SAMPLE_TEXTURE2D(_CloudNoise1,sampler_CloudNoise1,skyUV*_NoiseScale+prase0*flowdir);
float3 noise2_0=SAMPLE_TEXTURE2D(_CloudNoise2,sampler_CloudNoise2,skyUV*_NoiseScale+prase0*flowdir);

float3 baseNoise_1=SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,skyUV*_NoiseScale+prase1*flowdir);
float3 noise1_1=SAMPLE_TEXTURE2D(_CloudNoise1,sampler_CloudNoise1,skyUV*_NoiseScale+prase1*flowdir);
float3 noise2_1=SAMPLE_TEXTURE2D(_CloudNoise2,sampler_CloudNoise2,skyUV*_NoiseScale+prase1*flowdir);


float3 baseNoise_3=SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,skyUV-prase0*flowdir);
float3 baseNoise_4=SAMPLE_TEXTURE2D(_CloudTex,sampler_CloudTex,skyUV-prase1*flowdir);

float3 cloud=lerp(noise2_0,noise2_1,cloudLerp);
float cloudrange=saturate(IN.uv.y* _CloudClampmut+ _CloudClampadd);
cloud= cloud*cloudrange;
//底层的云
float3 Lowercloud=saturate(smoothstep(_CloudCut,_CloudCut+_Fuzziness,cloud));
//return float4(cloud,1);

//return float4(cloud,1);
float3 finalCloud=cloud+Lowercloud;

//从上到下渐变
float3 CloudColor=lerp(_CloudColor1,_CloudColor2,IN.uv.y);

                float3 skyColor = sunZenithColor + vzMask * viewZenithColor + svMask * sunViewColor;
                skyColor=lerp(skyColor,CloudColor.xyz,finalCloud);
                float3 col = skyColor;
                //float3 col = saturate(float3(step(0.9,dot(_SunDir, viewDir)), step(0.9,dot(_MoonDir, viewDir)), 0));
//return float4(IN.uv.y,0,0,1);                
return float4(col, 1);
            }
            ENDHLSL
        }
    }
}