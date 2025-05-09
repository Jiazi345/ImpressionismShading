Shader "My/URP_Shadow" {
    Properties {
        _BaseMap("Texture", 2D) = "white" {} //����ͼ
        _BaseColor("Tint Color", Color) = (1, 1, 1, 1) //�����ɫ

        _Specular("Specular", Color) = (1, 1, 1, 1) //�߹ⷴ����ɫ
        _Gloss("Gloss", Range(8.0, 256)) = 20 //�߹������С

        _Cutoff("Cutoff", float) = 0.5
    }

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline" //��������URPר��shader
            "Queue" = "Geometry" //URP�в��پ�����Ⱦ˳��(��ǰ�����ԽСԽ����Ⱦ), ��������һ�����id
            "RenderType" = "Opaque"
        }
        LOD 100

        //����pass���������
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //�������Զ�Ҫ���浽CBuffer��, �������ܼ���SRP Batcher
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _Specular;
            float _Gloss;
            float _Cutoff;
        CBUFFER_END

        ENDHLSL

        Pass {
            Tags { "LightMode" = "UniversalForward" } //��Ⱦpass, URP����һ��pass����Ⱦ���й�Դ, ���������ù��ߵ�ÿ����Դһ��pass

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS //����Դ��Ӱ
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE //������Ӱ(������Ӱ��ͼ, �����ֱ��ʸ�, Զ���ֱ��ʵ�)
            #pragma multi_compile _ _SHADOWS_SOFT //��Ӱ�����

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert //ָ��������ɫ������
            #pragma fragment frag //ָ��ƬԪ��ɫ������

            struct Attributes { //�����붥����ɫ��������
                float4 positionOS : POSITION; //��ģ�Ϳռ䶥���������ñ���
                float4 normalOS : NORMAL; //��ģ�Ϳռ䷨�߷������ñ���
                float2 uv : TEXCOORD0; //��ģ�͵ĵ�һ����������(uv)���ñ���
            };

            struct Varings { //������ɫ������ƬԪ��ɫ��������
                float4 positionCS : SV_POSITION; //�ñ�������˲ü��ռ�Ķ�������
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varings vert(Attributes IN) { //������ɫ��
                Varings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz); //���������ģ�Ϳռ�ת�����ռ�
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;

                OUT.viewDirWS = GetCameraPositionWS() - positionInputs.positionWS; //�ӽǷ���

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
                OUT.normalWS = normalize(normalInputs.normalWS); //���߷���

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap); //Ӧ����ͼ��tiling��offset
                return OUT;
            }

            float4 frag(Varings IN) : SV_Target { //ƬԪ��ɫ��(������)
                //��������
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS.xyz); //��Ӱ����
                Light light = GetMainLight(shadowCoord);
                float3 lightDirWS = light.direction;
                half3 diffuse = LightingLambert(light.color, lightDirWS, IN.normalWS); //lambert�������������乱�ױ���
                half3 specular = LightingSpecular(light.color, lightDirWS, normalize(IN.normalWS), normalize(IN.viewDirWS), _Specular, _Gloss); //Blinn-Phong��������߹�

                //���㸽�ӹ���
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex) {
                    Light light = GetAdditionalLight(lightIndex, IN.positionWS);
                    diffuse += LightingLambert(light.color, light.direction, IN.normalWS);
                    specular += LightingSpecular(light.color, light.direction, normalize(IN.normalWS), normalize(IN.viewDirWS), _Specular, _Gloss);
                }

                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv); //�������������ȡ������ɫ
                half3 albedo = texColor.rgb * _BaseColor.rgb; //���屾����ɫ���������
                half3 c = albedo * diffuse * light.shadowAttenuation + specular;
                clip(texColor.a - _Cutoff);
                return float4(c, 1);
            }
            ENDHLSL
        } // end of Pass

        //Pass {
        //    Name "ShadowCaster"
        //    Tags { "LightMode" = "ShadowCaster" } //������passΪ��ӰͶ��pass

        //    ZWrite On //���д��
        //    ZTest LEqual //��Ȳ���, ��ǰzֵ<=�����е�ֵʱͨ��
        //    Cull[_Cull] //�޳�

        //    HLSLPROGRAM
        //    #pragma prefer_hlslcc gles //Ĭ��glesû��HLSLcc����, gles 2.0Ҫ��urp��׼��, ҲҪ��HLSLcc����
        //    #pragma exclude_renderers d3d11_9x //directX��renderer��ʹ���ⲿ��URP pass
        //    #pragma target 2.0

        //    // -------------------------------------
        //    // Material Keywords
        //    #pragma shader_feature _ALPHATEST_ON
        //    #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

        //    //--------------------------------------
        //    // GPU Instancing
        //    #pragma multi_compile_instancing

        //    #pragma vertex ShadowPassVertex
        //    #pragma fragment ShadowPassFragment

        //    //������δ������������Լ���CBUFFER����������Ҫ�Ĳ�һ������������ע�͵���
        //    //#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
        //    //��������������2��hlsl�ļ�
        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

        //    #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        //    ENDHLSL
        //} // end of Pass
UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    } // end of SubShader

}