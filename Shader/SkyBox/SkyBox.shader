Shader "NprShader/SkyBox"
{
    Properties
    {
       _StarTex("NightStar Texture",CUBE)=""{}
       _MoonTex("Moon Texture",2D)="white"{}
       //Control the Glitter of Star 
       _NoiseMap("Noise Map",2D)="white"{}
       
       [Header(Sun Settings)]
       [Space(15)]
       [HDR]_SunColor("Sun Color",COLOR)=(1,1,1,1)
       _SunRadius("Sun Radius",Range(0,1))=0.5
       _SunStrength("Sun Strength",Range(0,4))=1

       
       [Header(Color Settings)]
       [Space(10)]
       _DayTopColor("Day:Top Color",COLOR)=(1,1,1,1)
       _DayBotColor("Day:Bottom Color",COLOR)=(1,1,1,1)
       _NightTopColor("Night:Top Color",COLOR)=(1,1,1,1)
       _NightBotColor("Night:Bottom Color",COLOR)=(1,1,1,1)
       _HorizontalColor("Horizontal Color",COLOR)=(1,1,1,1)
       _ScatterColor("Scatter Color",COLOR)=(1,1,1,1)

       [Header(Star Settings)]
       [Space(5)]
       _GlitSpeed("Glitter Speed",float)=1
       _GlitIntensity("Glitter Intensity",Range(0,5))=1
       _NebulaColor("Nebula Color",COLOR)=(1,1,1,1)
       _NebulaIntensity("Nebula Intensity",Range(0,1))=1

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Background"
            "PreviewType"="Skybox"
            "Queue"="Background"
        }
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _StarTex_ST;
            float4 _MoonTex_ST;
            float4 _NoiseMap_ST;

            float _SunRadius;
            float _SunStrength;

            half4 _SunColor;
            half4 _DayTopColor;
            half4 _DayBotColor;
            half4 _NightTopColor;
            half4 _NightBotColor;
            half4 _HorizontalColor;
            half4 _ScatterColor;

            float3 _WorldSpaceLightPos0;

            float _GlitSpeed;
            float _GlitIntensity;
            float _NebulaIntensity;
            half4 _NebulaColor;
           
            float4x4 _RotationMatrix;
        CBUFFER_END
            TEXTURECUBE(_StarTex);    SAMPLER(sampler_StarTex);
            TEXTURE2D(_MoonTex);    SAMPLER(sampler_MoonTex);
            TEXTURE2D(_NoiseMap);   SAMPLER(sampler_NoiseMap);

            struct a2v
            {
                float4 positionOS:POSITION;
                float3 uv:TEXCOORD0;
            };
            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float3 uv:TEXCOORD0;
                float3 positionWS:TEXCOORD1;
            };
            v2f vert(a2v input)
            {
                v2f output;
                
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.uv=input.uv;
                output.positionWS=TransformObjectToWorld(input.positionOS);

                return output;
            }
            real4 frag(v2f input):SV_TARGET
            {
                //Sun 
                float sunDistance=distance(input.uv,_WorldSpaceLightPos0);                
                float sunFactor=1-(sunDistance/_SunRadius);
                sunFactor=saturate(sunFactor*_SunStrength);
                half4 sunColor=sunFactor*_SunColor;

                //Sky Ramp
                float4 gradientDay=lerp(_DayBotColor,_DayTopColor,saturate(input.uv.y+_WorldSpaceLightPos0.y));
                float4 gradientNight=lerp(_NightBotColor,_NightTopColor,saturate(input.uv.y-_WorldSpaceLightPos0.y));
                float dayNightFactor=_WorldSpaceLightPos0.y*0.5+0.5;
                dayNightFactor=pow(dayNightFactor,2);
                dayNightFactor=smoothstep(0.2,0.8,dayNightFactor);
                float4 skyGradient=lerp(gradientNight,gradientDay,dayNightFactor);

                //Horizontal Color
                float horizontalFactor=1-abs(input.uv.y);
                horizontalFactor=pow(horizontalFactor,5)*smoothstep(-0.5,0.3,_WorldSpaceLightPos0.y);
                float4 horizontalColor=horizontalFactor*_HorizontalColor;

                //Scatter:simulate the effect,not based on physical
                float scatterScale=saturate(dot(normalize(input.positionWS),_WorldSpaceLightPos0))*max(0.3,(1-_WorldSpaceLightPos0.y*_WorldSpaceLightPos0.y));
                scatterScale*=1-min(1,(input.uv.y-_WorldSpaceLightPos0.y));
                scatterScale=pow(scatterScale,1.5);
               
                float4 scatterColor=scatterScale*_ScatterColor;

                //Moon Texture:transfer the rotation of mainLight from C# to build the matrix. So you have to build a C# scrpits to transfer the value!
                float3 moonUV=mul(input.uv,_RotationMatrix);
                float2 MoonUV=moonUV.xy*_MoonTex_ST.xy+_MoonTex_ST.zw;
                //step(0,moonUV.z) is to prevent to generate 2 moons in the sky on two sides
                float4 moonTex=SAMPLE_TEXTURE2D(_MoonTex,sampler_MoonTex,MoonUV)*step(0,moonUV.z);

                //Star Texture
                float4 starTex=SAMPLE_TEXTURECUBE(_StarTex,sampler_StarTex,moonUV);
                float4 nebula=starTex;
                starTex*=max(0,-_WorldSpaceLightPos0.y);
                starTex=half4(starTex.r,starTex.r,starTex.r,1);

                float2 noiseUV=_NoiseMap_ST.xy*input.uv+_NoiseMap_ST.zw+_GlitSpeed*_Time.x;
                float4 noiseTex=SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,noiseUV);
                noiseTex*=noiseTex;
                noiseTex=step(0.5,noiseTex)*_GlitIntensity;
                starTex*=noiseTex.r;

                nebula=float4(nebula.g,nebula.g,nebula.g,1)*_NebulaColor;
                nebula*=_NebulaIntensity;
                starTex+=nebula;

                //Final Color
                float4 finalColor=max(sunColor,skyGradient);
                finalColor=finalColor+scatterColor*1.5;
                finalColor+=horizontalColor+moonTex+starTex;
               
                return finalColor;
            }
        ENDHLSL
        pass
        {
            Tags
            {
                
            }
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
            ENDHLSL
        }
    }
}
