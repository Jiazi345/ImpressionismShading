Shader "My/URP_Shadow" {
    Properties {
        _BaseMap("Texture", 2D) = "white" {} //主贴图
        _BaseColor("Tint Color", Color) = (1, 1, 1, 1) //混合颜色

        _Specular("Specular", Color) = (1, 1, 1, 1) //高光反射颜色
        _Gloss("Gloss", Range(8.0, 256)) = 20 //高光区域大小

        _Cutoff("Cutoff", float) = 0.5
    }

    SubShader {
        Tags {
            "RenderPipeline" = "UniversalPipeline" //声明这是URP专属shader
            "Queue" = "Geometry" //URP中不再决定渲染顺序(以前是序号越小越先渲染), 而仅仅是一个类别id
            "RenderType" = "Opaque"
        }
        LOD 100

        //所有pass共享的声明
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //所有属性都要缓存到CBuffer中, 这样才能兼容SRP Batcher
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _Specular;
            float _Gloss;
            float _Cutoff;
        CBUFFER_END

        ENDHLSL

        Pass {
            Tags { "LightMode" = "UniversalForward" } //渲染pass, URP中在一个pass中渲染所有光源, 而不是内置管线的每个光源一个pass

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS //主光源阴影
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE //级联阴影(多张阴影贴图, 近处分辨率高, 远处分辨率低)
            #pragma multi_compile _ _SHADOWS_SOFT //阴影抗锯齿

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert //指定顶点着色器函数
            #pragma fragment frag //指定片元着色器函数

            struct Attributes { //程序传入顶点着色器的数据
                float4 positionOS : POSITION; //用模型空间顶点坐标填充该变量
                float4 normalOS : NORMAL; //用模型空间法线方向填充该变量
                float2 uv : TEXCOORD0; //用模型的第一套纹理坐标(uv)填充该变量
            };

            struct Varings { //顶点着色器传入片元着色器的数据
                float4 positionCS : SV_POSITION; //该变量存放了裁剪空间的顶点坐标
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            Varings vert(Attributes IN) { //顶点着色器
                Varings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz); //顶点坐标从模型空间转其他空间
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;

                OUT.viewDirWS = GetCameraPositionWS() - positionInputs.positionWS; //视角方向

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
                OUT.normalWS = normalize(normalInputs.normalWS); //法线方向

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap); //应用贴图的tiling和offset
                return OUT;
            }

            float4 frag(Varings IN) : SV_Target { //片元着色器(逐像素)
                //计算主光
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS.xyz); //阴影坐标
                Light light = GetMainLight(shadowCoord);
                float3 lightDirWS = light.direction;
                half3 diffuse = LightingLambert(light.color, lightDirWS, IN.normalWS); //lambert方法计算漫反射贡献比例
                half3 specular = LightingSpecular(light.color, lightDirWS, normalize(IN.normalWS), normalize(IN.viewDirWS), _Specular, _Gloss); //Blinn-Phong方法计算高光

                //计算附加光照
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex) {
                    Light light = GetAdditionalLight(lightIndex, IN.positionWS);
                    diffuse += LightingLambert(light.color, light.direction, IN.normalWS);
                    specular += LightingSpecular(light.color, light.direction, normalize(IN.normalWS), normalize(IN.viewDirWS), _Specular, _Gloss);
                }

                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv); //根据纹理坐标获取像素颜色
                half3 albedo = texColor.rgb * _BaseColor.rgb; //物体本身颜色的最大反射率
                half3 c = albedo * diffuse * light.shadowAttenuation + specular;
                clip(texColor.a - _Cutoff);
                return float4(c, 1);
            }
            ENDHLSL
        } // end of Pass

        //Pass {
        //    Name "ShadowCaster"
        //    Tags { "LightMode" = "ShadowCaster" } //声明该pass为阴影投射pass

        //    ZWrite On //深度写入
        //    ZTest LEqual //深度测试, 当前z值<=缓存中的值时通过
        //    Cull[_Cull] //剔除

        //    HLSLPROGRAM
        //    #pragma prefer_hlslcc gles //默认gles没用HLSLcc编译, gles 2.0要用urp标准库, 也要用HLSLcc编译
        //    #pragma exclude_renderers d3d11_9x //directX的renderer不使用这部分URP pass
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

        //    //由于这段代码中声明了自己的CBUFFER，与我们需要的不一样，所以我们注释掉他
        //    //#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
        //    //它还引入了下面2个hlsl文件
        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

        //    #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        //    ENDHLSL
        //} // end of Pass
UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    } // end of SubShader

}