Shader "URPSkyBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SunRadius("SunRadius",Range(0,1))=0.3
        _MoonRadius("MoonRadius",Range(0,1))=0.1
        _MoonOffset("_MoonOffset",float)=1

        _DayBottomColor("_DayBottomColor",COLOR)=(1,1,1,1)
        _DayTopColor("_DayTopColor",COLOR)=(1,1,1,1)
        _NightBottomColor("_NightBottomColor",COLOR)=(1,1,1,1)
        _NightTopColor("_NightTopColor",COLOR)=(1,1,1,1)
        _HorizonColorDay("_HorizonColorDay",COLOR)=(1,1,1,1)

        _Stars("Stars",2D)="white"{}
        _StarsCutoff("StarsCutoff",Range(0,0.5))=0.1

        _Cloud("Cloud",2D)="white"{}
        _CloudCutoff("CloudCutOff",Range(0,0.5))=0.1
         [NoScaleOffset]_DistortTex("DistortTex",2D)="white"{}
        _DistortSpeed("DistortSpeed",float)=1
        _DistortScale("DistortScale",float)=1
         [NoScaleOffset]_CloudNoise("CloudNoise",2D)="white"{}
        _CloudSpeed("CloudSpeed",float)=1
        _CloudNoiseScale("CloudNoiseScale",float)=1
        _Fluffy("Fluffy",float)=1

    }
    SubShader
    {
        Tags { "Queue"="BackGround"  "RenderPipeline"="UniversalPipeline"}
        LOD 100

        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 Wpos:TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _SunRadius;
            float _MoonRadius;
            float _MoonOffset;

            float4 _DayTopColor;
            float4 _DayBottomColor;
            float4 _NightBottomColor;
            float4 _NightTopColor;
            float4 _HorizonColorDay;

            float _StarsCutoff;
            sampler2D _Stars;

            float _CloudCutoff;
            sampler2D _Cloud;
            sampler2D _DistortTex;
            float _DistortSpeed;
            float _DistortScale;
            sampler2D _CloudNoise;
            float _CloudSpeed;
            float _CloudNoiseScale;
            float _Fluffy;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.Wpos=mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
return float4(1,1,1,1);
                Light light=GetMainLight(TransformWorldToShadowCoord(i.Wpos));
//Ì«Ñô
                float sun=distance(i.uv.xy,_MainLightPosition.xy);
                float sunDisc=1-saturate(sun/_SunRadius);
                sunDisc=saturate(sunDisc*50);
//ÔÂÁÁ
                float moon=distance(i.uv.xyz,-light.direction);
                float moonDisc=1-saturate(moon/_MoonRadius);
                moonDisc=saturate(moonDisc*50);
//ÔÂÊ³
                float creasentMoon=distance(float2(i.uv.x+_MoonOffset,i.uv.y),-light.direction);
                float creasentMoonDisc=1-saturate(creasentMoon/_MoonRadius);
                creasentMoonDisc=saturate(creasentMoonDisc*50);
                moonDisc=saturate(moonDisc- creasentMoonDisc);

//Ìì¿ÕÑÕÉ«
                float3 gradientDay=lerp(_DayBottomColor,_DayTopColor,saturate(i.uv.y));
                float3 gradientNight=lerp(_NightBottomColor,_NightTopColor,saturate(i.uv.y));
                float3 skyGradients=lerp(gradientNight,gradientDay,saturate(light.direction.y));
              
                float horizon=abs(i.uv.y);
                float horizonGlow=saturate((1-horizon)*saturate(1-abs(light.direction.y)));
                float4 horizonGlowDay=horizonGlow*_HorizonColorDay;  
                
                

//ÐÇÐÇ
                float2 skyUV=i.Wpos.xz/i.Wpos.y;
                float3 stars=tex2D(_Stars,skyUV-_Time.x*0.5);
                stars*=i.uv.y;
                stars=step(_StarsCutoff,stars);

//ÔÆ
                float3 cloud=tex2D(_Cloud,skyUV-_Time.x);
                cloud*=i.uv.y;
                            
                float distort=tex2D(_DistortTex,skyUV+(_Time.x*_DistortSpeed)*_DistortScale);
                float noise=tex2D(_CloudNoise,((skyUV+distort)-(_Time.x*_CloudSpeed))*_CloudNoiseScale);
                float FinalNoise=saturate(noise)*saturate(i.uv.y);
                  cloud=step(_CloudCutoff,cloud*FinalNoise);
                  cloud=saturate(smoothstep(_CloudCutoff*cloud,_CloudCutoff*cloud+_Fluffy,FinalNoise));
                float4 result=float4(sunDisc.xxx+moonDisc.xxx+skyGradients+stars+cloud,1)+horizonGlowDay;
                return float4(1,0,0,0);
                return result;

            }
            ENDHLSL
        }

            //pass
            //{
            //Tags { "LightMode"="ForwardAdd" }
            //Blend One One
            //HLSLPROGRAM
            //#pragma vertex vert
            //#pragma fragment frag
            //#pragma multi_compile_fwdadd   
            //#include "UnityCG.cginc"
            //struct appdata
            //{
            //    float4 vertex : POSITION;
            //    float2 uv : TEXCOORD0;
            //};

            //struct v2f
            //{
            //    float2 uv : TEXCOORD0;
            //    float4 vertex : SV_POSITION;
            //    float3 Wpos:TEXCOORD1;
            //};
            //sampler2D _MainTex;
            //float4 _MainTex_ST;
            //v2f vert (appdata v)
            //{
            //    v2f o;
            //    o.vertex = UnityObjectToClipPos(v.vertex);
            //    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            //    o.Wpos=o.Wpos=mul(unity_ObjectToWorld,v.vertex);;
            //    return o;
            //}
            //float4 frag (v2f i) : SV_Target
            //{
            //      return float4(1,1,1,1);
            //}
            //ENDHLSL
            //}

    }
}
