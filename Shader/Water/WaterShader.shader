Shader "NprShader/WaterShader"
{
   Properties
    {
    	_MainTex("Foam Texture",2D)="white"{}
        _NormalMap1("NormalMap1",2D)="bump"{}
        _NormalMap2("NormalMap1",2D)="bump"{}

        [Header(Color Settings)]
        [Space(10)]
        _RampColorA("Ramp Color A",COLOR)=(1,1,1,1)
        _RampColorB("Ramp Color B",COLOR)=(1,1,1,1)
        _RimColor("Rim Color",COLOR)=(1,1,1,1)
        _SpecularColor("Specular Color",COLOR)=(1,1,1,1)

        [Header(Value Settings)]
         [Space(10)]
        _NormalScale("Normal Scale",Range(0,3))=0.5
        _RampThreshold("Ramp Threshold",Range(0,20))=1
        _AlphaDepth("Alpha Depth",Range(0,5))=1
        _FLowSpeed("Flow Speed",float)=1
        _SpecuIntensity("Specular Intensity",Range(0,3))=1
        _Gloss("Gloss Scale",Range(0.01,255))=80
        _Fresnel("Fresnel Scale",Range(0,1))=0.5
        _RimScale("Rim Scale",Range(-1,1))=0.5
        _NearClipValue("NearClip Value",float)=0
       [Toggle(ENABLE_STATIC_EDGE)]_EnableStaticEdge("Enable Static Edge",float)=0

       [Space(10)]
       [Toggle(ENABLE_PROBE_REFLECTION)]_EnableProbeReflection("Enable Probe Reflection",float)=0
       _BRDFSpeSection("BRDFSpeSection",Range(0,1))=0.5
       _Smoothness("Smoothness",Range(0,1))=0.5
       _Metalic("Metalic",Range(0,1))=0.5
       _ReflectionFactor("Reflection Factor",Range(0,1))=0.5
    }

    SubShader
    {
       Tags
       {
            "RenderPipeline"="UniversalRenderPipeline"
            "RenderType"="TransparentCutoff"
            "Queue"="Transparent"
       }
       Cull off
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        #pragma shader_feature_local ENABLE_STATIC_EDGE
        #pragma shader_feature_local ENABLE_PROBE_REFLECTION
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _NormalMap1_ST;
        float4 _NormalMap2_ST;
      

        half4 _RampColorA;
        half4 _RampColorB;
        half4 _RimColor;
        half4 _SpecularColor;

        float _NormalScale;
        float _FLowSpeed;
        float _SpecuIntensity;
        float _Gloss;
        float _Fresnel;
        float _RimScale;
        float _RampThreshold;
        float _AlphaDepth;

        float _NearClipValue;

        float _BRDFSpeSection;
        float _Smoothness;
        float _Metalic;
        float _ReflectionFactor;
        
        float3 _WorldSpaceLightPos0;
        CBUFFER_END
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap1);    SAMPLER(sampler_NormalMap1);
        TEXTURE2D(_NormalMap2);    SAMPLER(sampler_NormalMap2);
        TEXTURE2D(_CameraDepthTexture);    SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D(_CameraOpaqueTexture);    SAMPLER(sampler_CameraOpaqueTexture);

        struct a2v
        {
            float4 positionOS:POSITION;
            float3 normalOS:NORMAL;
            float2 uv:TEXCOORD0;
        };
        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float3 positionWS:TEXCOORD1;
            float4 screenPos:TEXCOORD2;
            float3 viewDir:TEXCOORD3;
            float3 normalWS:NORMAL;
            float2 uv:TEXCOORD0;
            
        };
       
        real3 IndirSpeFactor(float roughness,float smoothness,float3 BRDFspe,float3 F0,float NdotV)
        {
             #ifdef UNITY_COLORSPACE_GAMMA
             float SurReduction = 1 - 0.28 * roughness, roughness;
             #else
             float SurReduction = 1 / (roughness * roughness + 1);
             #endif
             #if defined(SHADER_API_GLES)//Lighting.hlsl 261行
             float Reflectivity = BRDFspe.x;
             #else
             float Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
             #endif
             half GrazingTSection = saturate(Reflectivity + smoothness);
            float Fre = Pow4(1 - NdotV);//lighting.hlsl第501行 
             //float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);//lighting.hlsl第501行 它是4次方 我是5次方 
             return lerp(F0, GrazingTSection, Fre) * SurReduction;
        }
        real3 Indir_SpeCube(float3 normalWS,float3 viewWS,float roughness,float AO)
        {
            float3 reflectDirWS=reflect(-viewWS,normalWS);
            roughness=roughness*(1.7-0.7*roughness);
            float MipLevel=roughness*6;
            float4 SpeColor=SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDirWS,MipLevel);
            #if !defined(UNITY_USE_NATIVE_HDR)
          
             return DecodeHDREnvironment(SpeColor,unity_SpecCube0_HDR) * AO;
             #else
             return SpeColor.xyz * AO;
             #endif
         }

        ENDHLSL
        pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            ZTest LEqual
            ZWrite Off
            BLEND SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            v2f vert(a2v input)
            {
                v2f output;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.positionWS=TransformObjectToWorld(input.positionOS);
                output.normalWS=TransformObjectToWorldNormal(input.normalOS);
                output.uv=TRANSFORM_TEX(input.uv,_MainTex);
                output.viewDir=normalize(_WorldSpaceCameraPos-output.positionWS);
                output.screenPos=ComputeScreenPos(output.positionCS);
                               
                return output;
            }
            float4 frag(v2f input):SV_TARGET
            {
                float4 screenPos=input.screenPos;
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,screenPos.xy/screenPos.w),_ZBufferParams);
                float partZ=screenPos.w-_NearClipValue;
                float diffZ=abs(sceneZ-partZ);
                diffZ=smoothstep(0,_RampThreshold,diffZ);
                float3 rampColor=lerp(_RampColorA,_RampColorB,diffZ);
                //NormalMap
                float2 velocity=float2(1,0)*0.005;
                float t=_Time.y*_FLowSpeed;
                float2 uv1=(input.uv+velocity.yx*t*1.2)*1.5;
                float2 uv2=input.uv+velocity.xy*t;
                float4 packnormal1=SAMPLE_TEXTURE2D(_NormalMap1,sampler_NormalMap1,uv1);
                float4 packnormal2=SAMPLE_TEXTURE2D(_NormalMap2,sampler_NormalMap2,uv2);
                float3 waterNormal1=UnpackNormal(packnormal1);
                float3 waterNormal2=UnpackNormal(packnormal2);
                waterNormal1=float3(waterNormal1.x*_NormalScale,waterNormal1.z,waterNormal1.y*_NormalScale);
                waterNormal2=float3(waterNormal2.x*_NormalScale,waterNormal2.z,waterNormal2.y*_NormalScale);
                float3 normalDir=normalize(waterNormal1+waterNormal2);
                //SPECULAR
                Light mLight=GetMainLight();
                float3 lightDir=normalize(mLight.direction);

                float3 fragView=normalize(_WorldSpaceCameraPos-input.positionWS);
                float3 halfDir=normalize(lightDir+fragView);
                float3 reflectDir=normalize(reflect(-fragView,input.normalWS));

                

                float ndotvWS=dot(fragView,input.normalWS);  //Values For RimColor
                float ndotv=dot(fragView,normalDir);   //Values For Fresnel
                float ndoth=dot(normalDir,halfDir);     //Values For Specular
                

                float3 specu=pow(saturate(ndoth),_Gloss)*_SpecuIntensity*_SpecularColor;
                float3 skyBox=SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,1);
                float fresnel=lerp(pow(1-ndotv,5),1,_Fresnel);
                skyBox=lerp(0,skyBox,fresnel);

                //Rim
                float rim=1-saturate(ndotvWS);
                rim*=rim*rim;
                rim=smoothstep(0,1,rim+_RimScale);
                rampColor=lerp(rampColor,_RimColor,rim);
                //foam
                float partZZ=screenPos.w-_NearClipValue;
                diffZ=abs(sceneZ-partZZ);
                float alpha=max(0.3,saturate(diffZ/_AlphaDepth)); //Get the alpha Value
               
               
                #ifdef ENABLE_STATIC_EDGE
                diffZ=1-smoothstep(0,1,diffZ/0.15);  //0.15 is the rimColor Range
                #else
                 diffZ=saturate(sin(1-smoothstep(0,1,diffZ/0.6)*12.28+_Time.y*2))*(1-smoothstep(0,1,diffZ/0.6));
                #endif

                 float3 foam=float3(diffZ,diffZ,diffZ);
                float4 foamTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv+_Time.x/12);
                foam*=foamTex.r*foamTex.r;
                //holo
                float3 sunDir=normalize(float3(lightDir.xz,0));
                float3 viewHolo=(float3(-fragView.xz,0));
                
                float holo=dot(sunDir,viewHolo);
                holo=smoothstep(0.9,1.1,holo);
                viewHolo=saturate(float3(holo,holo,holo));
                //refract
                float2 uvOffset=normalDir.xz*0.5/screenPos.w;
                float2 refractUV=abs(screenPos.xy/screenPos.w+uvOffset);

                //Remove Wrong Refraction
                float newDepth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture,refractUV),_ZBufferParams);
                if(newDepth<sceneZ)
                    refractUV=screenPos.xy/screenPos.w;
               
                float4 refractColor=SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,refractUV);

                float4 finalColor=saturate(float4((rampColor+skyBox*0.4+specu)*saturate(lightDir.y*0.5+0.55)+foam*2+viewHolo*step(0,_WorldSpaceLightPos0.y),alpha));

                #ifdef ENABLE_PROBE_REFLECTION
                float roughness=(1-_Smoothness)*(1-_Smoothness);
                float3 F0=lerp(float3(0.04,0.04,0.04),_RampColorA.rgb,_Metalic);
                real3 indirSpeFactor=IndirSpeFactor(roughness,_Smoothness,_BRDFSpeSection,F0,ndotv);
                real3 indirSpeCube=Indir_SpeCube(normalDir,fragView,roughness,1);
                float3 indirSpecu=indirSpeFactor*indirSpeCube;

                finalColor=lerp(finalColor,float4(indirSpeCube,1),_ReflectionFactor);
                #endif
                
                return lerp(refractColor,finalColor,alpha);
          
              
            }
            ENDHLSL
        }

    } 
}