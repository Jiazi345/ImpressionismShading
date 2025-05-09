Shader "Custom/ToonWithFog"
{
    Properties
    {
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _BaseColor2("Base Color", Color) = (1,1,1,1)
        _ShadowThreshold("Shadow Threshold", Range(0, 1)) = 0.5
        _FogColor("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
        _FogPara("FogPara",Float)=0.5
        _fogMove("FogMove",Float)=0
        _FogStart("Fog Start", Float) = 5
        _FogEnd("Fog End", Float) = 50
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        Pass
        {
            Name "ToonPass"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _BaseColor2;
            float _ShadowThreshold;

            float4 _FogColor;
            float _FogStart;
            float _FogEnd; 
            float _FogPara;
            float _fogMove;
             CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.positionWS = positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float lightDot = dot(normal, mainLight.direction);

                // Step function for toon shadow edge
             

                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float lit = step(_ShadowThreshold, albedo.x*lightDot);
                float3 color = clamp(albedo.r,0.8,1) * ((lit+_FogColor));

                // Compute fog factor based on linear depth
           //     float depth = IN.positionHCS.z / IN.positionHCS.w;
            //    float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
            //    float fogFactor = saturate((linearDepth - _FogStart) / (_FogEnd - _FogStart));

                float3 finalColor = lerp(color, _FogColor.rgb, (1-saturate(IN.positionWS.y))*_FogPara+_fogMove);

                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
