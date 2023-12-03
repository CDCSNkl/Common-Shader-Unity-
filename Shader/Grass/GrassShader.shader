Shader "NprShader/GrassShader"
{
    Properties
    {
        //This map is in order to control the single grass waver movement
        _NoiseMap("Noise Map",2D)="white"{}
        //This map is in order to control the whole grasses waver movement
        _WaveMap("Wave Map",2D)="white"{}

       [Header(Color Settings)]
       [Space(10)]
       _TopColor("Top Color",COLOR)=(1,1,1,1)
       _BotColor("Bottom Color",COLOR)=(1,1,1,1)
       //Give some region diffrent color 
       _RampColor("Ramp Color",COLOR)=(1,1,1,1)
       _RampDarkColor("Ramp DarkColor",COLOR)=(1,1,1,1)
       _RampSize("Ramp Size",Range(0.1,200))=20
       _RampFactor("Ramp Factor",Range(0,1))=1
       [HDR]_SpecuColor("Specular Color",COLOR)=(1,1,1,1)
       _Gloss("Gloss Scale",Range(0.1,36))=2
       _BaseColorThreshold("BaseColor Threshold",Range(0,1))=0.5
       
       [Header(Wave Settings)]
       [Space(10)]
       _WaveSize("Wave Size",Range(0,100))=1
       _WaveSpeed("Wave Speed",Range(0,2))=0.1
       _WaveIntensity("Wave Intensity",Range(0,0.5))=0.2
       _WaveMapIntensity("WaveMap Intensity",Range(0,2))=1
       _WaveMapSize("WaveMap Size",Range(0,120))=12
       _WaveMapSpeed("WaveMap Speed",Range(0,8))=1
       
       [Header(Player Interaction)]
       [Space(10)]
       [Toggle(ENABLE_DISTURB)]_EnableDisturb("Enable Disturb",float)=0 
       _DisturbRadius("Disturb Radius",Range(0,4))=1
       _DownDistance("Down Distance",Range(0,2))=0.5
       _DisturbFactor("Disturb Factor",Range(0,3))=0.5
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
        }
        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LGIHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
            #pragma shader_feature_local ENABLE_DISTURB
           
        CBUFFER_START(UnityPerMaterial)
          float4 _WaveMap_ST;

          half4 _TopColor;
          half4 _BotColor;
          half4 _RampColor;
          half4 _RampDarkColor;
          half4 _SpecuColor;

          float _Gloss;
          float _BaseColorThreshold;
          float _RampSize;
          float _RampFactor;
          float _WaveSize;
          float _WaveSpeed;
          float _WaveIntensity;
          float _WaveMapIntensity;
          float _WaveMapSize;
          float _WaveMapSpeed;                
          
          float4 _PlayerPos;
          float _DisturbRadius;
          float _DownDistance;
          float _DisturbFactor;
          
          float3 _WorldSpaceLightPos0;
        CBUFFER_END
            TEXTURE2D(_NoiseMap);    SAMPLER(sampler_NoiseMap);
            TEXTURE2D(_WaveMap);    SAMPLER(sampler_WaveMap);

            struct a2v
            {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float3 uv:TEXCOORD0;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float3 normalWS:NORMAL;
                float3 uv:TEXCOORD0;
                float3 positionWS:TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            v2f vert(a2v input)
            {
                v2f output;
                
                UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input,output);

                output.normalWS=TransformObjectToWorldNormal(input.normalOS);
                output.uv=input.uv;
                output.positionWS=TransformObjectToWorld(input.positionOS);

                float2 sampleUV=output.positionWS.xz/_WaveSize;
                sampleUV+=_Time.x*_WaveSpeed;
                float3 waveSample=SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap,sampleUV,0);

                float2 waveMapSampleUV=output.positionWS.zx/_WaveMapSize;
				waveMapSampleUV.x+=_Time.x*_WaveMapSpeed;
				float3 waveMapSample=SAMPLE_TEXTURE2D_LOD(_WaveMap,sampler_WaveMap,waveMapSampleUV,0);

                output.positionWS.x += sin(waveSample.r) * input.uv.y*_WaveIntensity;
				output.positionWS.z += sin(waveSample.r*waveMapSample.r) * input.uv.y*_WaveMapIntensity;

                #ifdef ENABLE_DISTURB
                float2 disturbDir=normalize(output.positionWS.xz-_PlayerPos.xz);
                float disturbDistance=distance(_PlayerPos,output.positionWS);
                float disFactor=max(1-disturbDistance/_DisturbRadius,0);
                float2 disturbXZ=disturbDir*disFactor;
                disturbXZ*=_DisturbFactor;
                float3 disturbWS=float3(disturbXZ.x,-disFactor*_DownDistance,disturbXZ.y)*input.positionOS.y;
                output.positionWS+=disturbWS;
                #else
                #endif
               			
                output.positionCS=TransformWorldToHClip(output.positionWS);

                return output;
            }
            half4 frag(v2f input):SV_TARGET
            {
               UNITY_SETUP_INSTANCE_ID(input);

               //Albedo Color
               half4 albedo=lerp(_BotColor,_TopColor,_BaseColorThreshold+input.uv.y);
               
               //Specular Color
               float4 shadowCoord=TransformWorldToShadowCoord(input.positionWS);
               Light mLight=GetMainLight(shadowCoord);
               float3 viewWS=normalize(_WorldSpaceCameraPos-input.positionWS);
               float3 halfDir=normalize(viewWS+normalize(mLight.direction));
               float specuColor=pow(saturate(dot(halfDir,input.normalWS)),_Gloss)*_SpecuColor;
               specuColor=lerp(0,specuColor,input.uv.y)*max(_WorldSpaceLightPos0.y*0.5+0.5,0.5);

               //Ramp Color
               half4 rampColor=SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,input.positionWS.xz/_RampSize*0.5);
               rampColor=lerp(_RampDarkColor,rampColor*_RampColor,_BaseColorThreshold+input.uv.y);
               albedo=lerp(albedo,rampColor,rampColor.r*_RampFactor)*max(_WorldSpaceLightPos0.y*0.5+0.5,0.3);
              
               half4 finalColor=albedo+specuColor;

               //nightShadow Factor
               float nightFactor=(mLight.shadowAttenuation+0.4)*(_WorldSpaceLightPos0.y*0.5+0.5)+1-(_WorldSpaceLightPos0.y*0.5+0.5);

               finalColor*=min(nightFactor,1);

               return finalColor;
            }
        ENDHLSL
        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Cull off
            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_instancing
                
            ENDHLSL
        }
     
    }
}
