Shader "Unlit/strock"
{
   Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _ColorMap("ColorMap",2D)="white"{}
        _FlowMap("FlowMap",2D)="white"{}
        _Rotation ("Rotation Angle", Float) = 0
        _ClipRange("Clip",Range(0,1))=0.5
        _BaseColor("BaseColor",Color)=(1,1,1,1)
        _HideColor("HideColor",Color)=(1,1,1,1)
        _FogFactor("FogFactor",float)=1
        _LightMapColor("LightMapColor",2D)="white"{}
    }
    SubShader
    {

        Pass
        {
            Name "ForwardLit"
           // Tags {  "RenderType"="Transparent" "Queue"="Transparent"  "LightMode" = "UniversalForward" }
           Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry"}
            Blend SrcAlpha OneMinusSrcAlpha
        //    ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
             #include "../ShaderTools/RGBTrans.hlsl"
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup
            #pragma multi_compile _ LIGHTMAP_ON
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_ColorMap);
            SAMPLER(sampler_ColorMap);
            TEXTURE2D(_FlowMap);
            SAMPLER(sampler_FlowMap);

            TEXTURE2D(_LightMapColor);
            SAMPLER(sampler_LightMapColor);
            float4 _ColorMap_ST;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float _Rotation;
            float _StrokeOffset;
            float _StrokeScale;
            float _ClipRange;
            float3 _BaseColor;
            float3 _HideColor;
            float  _FogFactor;
            CBUFFER_END

#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
    struct Stroke
    {
         float3 Position;
         float3 Normals;
         float2 UV;
         float2 lightmapuv;
         float noise;
         uint matIndex;
         float Scale;
    };
    StructuredBuffer<Stroke> strokes;
#endif


            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normal: Normal;
                float2 uv : TEXCOORD0;
                float2 lightmapuv:TEXCOORD1;
                float2 uv2:TEXCOORD2;//reltime light map uv
                uint instanceID : SV_InstanceID;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float2 lightmapuv:TEXCOORD1;
                float2 uv2:TEXCOORD2;
                float2 Mapuv:TEXCOORD3;
                float4 positionHCS : SV_POSITION;
                uint instanceID : SV_InstanceID;
                float4 shadowCoords:TEXCOORD4;
                float3 positionWS:TEXCOORD5;
                float3 normal:Normal;
            };

            void setup(){}
// flip book
            float2 atlasUV(float2 baseUV, uint matIndex)
            {

                const float atlasCols = 2.0;
                const float atlasRows = 2.0;


                float col = fmod(matIndex, atlasCols);
                float row = floor(matIndex / atlasCols);

                float2 tileSize = 1.0 / float2(atlasCols, atlasRows);


                float2 uv = baseUV * tileSize + float2(col, atlasRows - 1 - row) * tileSize;
                return uv;
            }
//fresnel
                // float3 F_Schlick(float3 F0, float cosTheta)
                // {
                //     return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
                // }

            Varyings vert(Attributes IN)
            {

                Varyings OUT;
                OUT.Mapuv = TRANSFORM_TEX(IN.uv, _BaseMap);
              //  OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.uv=TRANSFORM_TEX(IN.uv, _ColorMap);
                OUT.instanceID = 0;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                
                float3 positionWS=TransformObjectToWorld(IN.positionOS);
                VertexPositionInputs positions = GetVertexPositionInputs(positionWS);
                float4 shadowCoordinates = GetShadowCoord(positions);
                OUT.shadowCoords=shadowCoordinates;
                OUT.normal= TransformObjectToWorldNormal(IN.normal);
                OUT.positionWS=positionWS;

                //light map uv
                OUTPUT_LIGHTMAP_UV(IN.lightmapuv,unity_LightmapST,OUT.lightmapuv);
                OUT.uv2 = IN.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                //real-time uv
              //  #if defined(DYNAMICLIGHTMAP_ON)
                OUT.uv2=
                IN.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
             //   #else
              //  OUT.uv2=float2(1,1);
              //  #endif

                #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
                OUT.instanceID = IN.instanceID;
                Stroke stroke = strokes[IN.instanceID];

                float2 FlowDir=_FlowMap.SampleLevel(sampler_FlowMap,stroke.UV,0);
                float3 N = normalize(stroke.Normals);
                float3 T = normalize(abs(N.y) < 0.999 ? cross(N, float3(0,1,0)) : cross(N, float3(1,0,0))); // 避免N和Up共线
                float3 B = normalize(cross(T, N));

                float angle = atan2(FlowDir.y, FlowDir.x);
                float cosA = cos(angle);
                float sinA = sin(angle);

                stroke.Position+=_StrokeOffset*stroke.Normals;
                OUT.positionWS=stroke.Position;
                IN.positionOS=IN.positionOS*stroke.Scale*_StrokeScale;

                float3 rotated= (T * cosA + B * sinA) * IN.positionOS.x +
                    (-T * sinA + B * cosA) * IN.positionOS.y +
                        N * IN.positionOS.z;
                float3 rotatedOS=rotated+stroke.Position;

             //   OUT.positionHCS = TransformObjectToHClip(rotatedOS);
                OUT.positionHCS= mul(UNITY_MATRIX_VP, float4(rotatedOS, 1.0));

                //shadow
                positions = GetVertexPositionInputs(stroke.Position);
                shadowCoordinates = GetShadowCoord(positions);
                OUT.shadowCoords = shadowCoordinates;
                OUT.normal=stroke.Normals;
                OUT.Mapuv=IN.uv;
                OUT.uv=stroke.UV;
            #endif
                return OUT;
            }


            half4 frag(Varyings IN) : SV_Target
            {

                half4 shape = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);
                 half4 color=SAMPLE_TEXTURE2D(_ColorMap,sampler_ColorMap,IN.uv);

            //    float3 lightMap=SAMPLE_TEXTURE2D(_LightMapColor,sampler_LightMapColor,IN.lightmapuv);
         //       lightMap=KeepHueOnly(lightMap,1,1);
                float3 lightMap=SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap, IN.lightmapuv);
                lightMap=KeepHueOnly(lightMap,1,1);
    //      float3 lightMap=SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap,samplerunity_Lightmap), 
         
    //      IN.uv2,half4(1,1,0,0),
    //    false,half4(1,1,1,1));
    //            return half4(IN.uv2,0,1);
        //      return half4(lightMap,1);
                #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED

                lightMap=SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap,strokes[IN.instanceID].lightmapuv);
                lightMap=KeepHueOnly(lightMap,0.8,1);
  
                IN.Mapuv=atlasUV(IN.Mapuv,strokes[IN.instanceID].matIndex);
                shape=SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.Mapuv);
                clip(shape.x-_ClipRange);

                Light light=GetMainLight();
                half shadow=saturate(dot(IN.normal,light.direction));
                //明暗交界线参数 明暗交界线为1 远离交界线逐渐退化到为0
                half darklightCross=1-abs(shadow-0.5)*2;
                half darkSideRange=step(0.5,shadow*shadowAmount);//暗部遮罩
                

                InputData inputData;
                inputData.positionWS=IN.positionWS;
                inputData.normalWS=strokes[IN.instanceID].Normals;
                half3 GI=SampleSH(inputData.normalWS);
           //     half3 GI=SampleLightmap(IN.lightmapuv,IN.normal);
                
           
           //fresnel
            float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS); // 摄像机方向
            float3 normalWS = normalize(strokes[IN.instanceID].Normals); // 世界空间法线
            float cosTheta = saturate(dot(viewDir, normalWS));
            float3 F0 = float3(0.04, 0.04, 0.04); // 通常用于非金属表面

                float3 fresnel = F_Schlick(F0, cosTheta);
            
                //明暗交界线添加环境光
                half3 basecolor=lerp(color*_BaseColor,half3(1,1,1),darklightCross*strokes[IN.instanceID].noise);
                half3 finalbaseColor=lerp(basecolor*(darkSideRange+lightMap),1-2*(1-color)*(1-light.color),darkSideRange);
                //fresnel添加透光
                half3 finalColor=lerp(finalbaseColor,_HideColor.xyz,fresnel.x*strokes[IN.instanceID].noise);
                //空气透视

                float depth = length(_WorldSpaceCameraPos - IN.positionWS);
                depth = saturate(depth*0.01)* _FogFactor;
                finalColor=lerp(finalColor,GI,depth);
            //    return half4(lightMap,1);
                return half4(finalColor,1);
                #endif
                half3 NoInstancingGI=SampleLightmap(IN.lightmapuv,IN.normal);
                return half4(NoInstancingGI,1);
            }

            ENDHLSL
        }
    }
}
