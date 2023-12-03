Shader "NprShader/CharactorShader"
{
    Properties
    {
    	_MainTex("MainTex",2D)="white"{}
        [Toggle(ENABLE_NORMAL_MAP)]_EnableNormalMap("Enable NormalMap",float)=0
        _NormalMap("Normal Map",2D)="bump"{}
        [Toggle(ENABLE_MATCAP)]_EnableMatcap("Enable Matcap",float)=0
        _MatCap("Matcap",2D)="white"{}
        [Toggle(ENABLE_RMO_TEXTURE)]_EnableRmoTexture("Enable RMA Texture",float)=0
        _RmoTexture("RMA Texture",2D)="white"{}
        
        [Header(Basic Settings)]
        [Space(10)]
        _NormalScale("Normal Scale",Range(0,1))=0.5
        [Space(10)]
        _MatCapScale("Matcap Scale",Range(0,1))=0.5
        _Metallic("Metallic",Range(0,1))=0.5
        _Smoothness("Smoothness",Range(0,1))=0.5
        _BaseColor("Base Color",COLOR)=(1,1,1,1)        
        _DarkRange("Dark Range",Range(0,1))=0.5
        _SmoothRange("Smooth Range",Range(0,1))=0.1
        _DarkColor("Dark Color",COLOR)=(0.5,0.5,0.5,1)
        [Space(10)]
        _NprFactor("NPR Factor",Range(0,1))=0

        
        [Space(30)]
        [Toggle(ENABLE_SSS)]_EnableSSS("Enable SSS Effect",float)=0        
        [Space(10)]        
        _LUTMAP("LUT Map",2D)="white"{}
        _SSSFactor("SSS Factor",Range(0,1))=1
        _SSSTone("SSS Tone",COLOR)=(1,1,1,1)                
        
        
        [Header(Enable Outline)]
        [Space(20)]
        [Toggle(ENABLE_OUTLINE)]_EnableOutline("Enable Outline",float)=0
        [Toggle(ENABLE_OUTLINE_ATTENUATE)]_EnableOutlineAttenuate("Enable Outline Attenuate",float)=1
        _OutlineColor("Outline Color",COLOR)=(0,0,0,0)
        _OutlineBias("Outline Bias",Range(0,0.02))=0.02
        _OutlineMaxDistance("Outline MaxDistance",Range(1,30))=10

        [Header(Enable RimLight)]
        [Space(20)]
        [Toggle(ENABLE_RIMLIGHT)]_EnableRimLight("Enable RimLight",float)=0
        [HDR]_RimLightColor("RimLight Color",COLOR)=(1,1,1,1)
        _RimPower("RimPower",Range(0,0.4))=5
        _RimLightIntensity("RimLight Intensity",Range(0,1))=0.5
        _RimEdge("RimLight Edge",Range(0,1))=0.5
        _RimLightWidth("RimLight Smooth",Range(0,1))=0.1
        
        [Space(20)]
        [Toggle(IS_FACE)]_IsFace("Is Face",float)=0
        [Toggle(ENABLE_HAIRCASTER)]_EnableHairCaster("Enable HairCaster",float)=0
        [Header(override the facepart for 2)]
        [Space(10)]
        _HairStencil("HairStencil",int)=3
        _CastColor("Cast Color",COLOR)=(1,1,1,1)
        _CastBias("Cast Bias",Range(0,0.1))=0.1

        [Space(10)]
        [Toggle(ENABLE_DUAL_LOBE)]_EnableDualLobe("Enable DualLobeSpecular",float)=0
        _Lobeweight("LobeWeight",Range(0,1))=1
        //Need A Mask Map
        _Mask("Mask",Range(0,1))=1

        [Space(10)]
        [Toggle(ENABLE_STRANDSPECULAR)]_EnableStrandSpecular("Enable Strand Specular",float)=0
        _Exponent("Exponent",Range(0,255))=10
        _StrandScale("Strand Scale",Range(0,1))=1

        [Space(10)]
        _SystemFogFactor("System FogFactor",Range(0,1))=1

        [Space(10)]
        [Header(Shadow Recieve)]
        [Space(10)]
        [Toggle(ENABLE_RECIEVE_SHADOW)]_Enable_Recieve_Shadow("Enable Recieve Shadow",float)=1
        _FadeStart("Fade StartDistance",Range(0,100))=40
        _ShadowDistance("Shadow Distance",Range(0,200))=80
        _ShadowFactor("Shadow Factor",Range(0,1))=0.8

    }
    SubShader
    {
        Tags{
        "RenderPipeline"="UniversalRenderPipeline"
        "Queue"="Geometry"
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "myPBR_Function.hlsl"

        #pragma shader_feature_local ENABLE_SSS
        #pragma shader_feature_local ENABLE_RMO_TEXTURE
        #pragma shader_feature_local ENABLE_NORMAL_MAP
        #pragma shader_feature_local ENABLE_MATCAP
        #pragma shader_feature_local ENABLE_OUTLINE
        #pragma shader_feature_local ENABLE_OUTLINE_ATTENUATE
        #pragma shader_feature_local ENABLE_RIMLIGHT
        #pragma shader_feature_local IS_FACE
        #pragma shader_feature_local ENABLE_HAIRCASTER
        #pragma shader_feature_local ENABLE_DUAL_LOBE
        #pragma shader_feature_local ENABLE_STRANDSPECULAR        
        #pragma shader_feature_local ENABLE_RECIEVE_SHADOW

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LGIHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _NormalMap_ST;
        float4 _MatCap_ST;
        float4 _RmoTexture_ST;
        float4 _LUTMAP_ST;

        float _NormalScale;
        float _MatCapScale;
        float _Metallic;
        float _Smoothness;
        half4 _BaseColor;
       

        float _DarkRange;
        float _NprFactor;
        float _SmoothRange;

        float4 _DarkColor;
        float _SSSFactor;
        float4 _SSSTone;

        half4 _RimLightColor;
        float _RimPower;
        float _RimLightIntensity;
        float _RimEdge;
        float _RimLightWidth;

        float4 _CastColor;
        float _CastBias;
        int _HairStencil;

        float _AnisotropyFactor;
        
        float _OutlineBias;
        half4 _OutlineColor;;
        float _OutlineMaxDistance;

        float _Lobeweight;
        float _Mask;

        float _Exponent;
        float _StrandScale;

        float _ShadowDistance;
        float _FadeStart;
        float _ShadowFactor;

        float _SystemFogFactor;
        CBUFFER_END
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap);    SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MatCap);    SAMPLER(sampler_MatCap);
        TEXTURE2D(_RmoTexture);    SAMPLER(sampler_RmoTexture);
        TEXTURE2D(_LUTMAP);    SAMPLER(sampler_LUTMAP);
      
         struct a2v
         {
             float4 positionOS:POSITION;
             float3 normalOS:NORMAL;
             float2 texcoord:TEXCOORD;
             float4 tangentOS:TANGENT;         
             
             
          
         };
         struct v2f
         {
             float4 positionCS:SV_POSITION;
             float2 texcoord:TEXCOORD;
             float3 normalWS:NORMAL;
             float3 positionWS:TEXCOORD1;     
             
             float4 tangentWS:TEXCOORD2;
             float4 BtangentWS:TEXCOORD3;

             real fogFactor:TEXCOORD4;

         };
         float GetDistanceFade(float3 positionWS)
			{
			    float4 posVS = mul(GetWorldToViewMatrix(), float4(positionWS, 1));
			    
			#if UNITY_REVERSED_Z
			    float vz = -posVS.z;
			#else
			    float vz = posVS.z;
			#endif
			    float fade = 1 - smoothstep(_FadeStart, _ShadowDistance, vz);
			    return fade;
			}

        ENDHLSL

        pass
        {
        Tags{
             "LightMode"="UniversalForward"
             "RenderType"="Opaque"
            }
            //for hairCaster
            Stencil
            {
            Ref [_HairStencil]
            Comp Always
            Pass Replace
            }
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            v2f vert(a2v input)
            {
                v2f output;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.texcoord=TRANSFORM_TEX(input.texcoord,_MainTex);
                output.normalWS=TransformObjectToWorldNormal(input.normalOS);
                output.positionWS=TransformObjectToWorld(input.positionOS);

                output.tangentWS.xyz=normalize(TransformObjectToWorldDir(input.tangentOS));
                output.BtangentWS.xyz=cross(output.normalWS.xyz,output.tangentWS.xyz)*input.tangentOS.w*unity_WorldTransformParams.w;

                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                
                         
                return output;
            }
            real4 frag(v2f input):SV_TARGET
            {
                float4 shadowCoord=TransformWorldToShadowCoord(input.positionWS);
                Light myLight=GetMainLight(shadowCoord);
                float3 L=normalize(myLight.direction);

                
                #ifdef IS_FACE
                    L.y=0;
                    L=normalize(L);
                #else
                    //Consider the Night Influence,so inverse the Y axis when it turns night. you can modify the brightness on youself; 
                    L.y=abs(L.y);
                #endif                

                float3 N=input.normalWS;

                //Enable NormalMap
                #ifdef ENABLE_NORMAL_MAP
                    float4 nortex=SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,input.texcoord);
                    float3 norTS=UnpackNormalScale(nortex,_NormalScale);
                    norTS.z=sqrt(1-saturate(dot(norTS.xy,norTS.xy)));
                    float3x3 T2W={input.tangentWS.xyz,input.BtangentWS.xyz,input.normalWS.xyz};
                    T2W = transpose(T2W);
                    N=NormalizeNormalPerPixel(mul(T2W,norTS));
                #endif

                float3 V=normalize(_WorldSpaceCameraPos-input.positionWS);
                float3 H=normalize(L+V);

                float NdotH=max(0.001,dot(N,H));
                float NdotL=max(0.001,dot(N,L));
                float NdotV=max(0.001,dot(N,V));
                float HdotL=max(0.001,dot(H,L));

                //Albedo
                real4 albedo=_BaseColor*SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.texcoord);

                    float metallic=0;
                    float roughness=0;
                    float a=0;
                    float ao=1;

                //Enable RMO Texture
                #ifdef ENABLE_RMO_TEXTURE
                    float4 rmoTexture=SAMPLE_TEXTURE2D(_RmoTexture,sampler_RmoTexture,input.texcoord);
                    metallic=rmoTexture.b;
                    roughness=1-rmoTexture.a;
                    a=roughness*roughness;
                    ao=rmoTexture.g;
                #else
                    metallic=_Metallic;
                    roughness=1-_Smoothness;
                    a=roughness*roughness;                    
                #endif

                //DirectionLight
                float D=D_Func(a,NdotH);
                float G=GGX_Func(NdotL,a)*GGX_Func(NdotV,a);

                float3 F0=lerp(float3(0.04,0.04,0.04),albedo.rgb,metallic);
                float3 F=F_Func(F0,HdotL);

                float3 Kd=(1-F)*(1-metallic);

                    //DualLobe Specular
                    real3 Fdirect;

                    #ifdef ENABLE_DUAL_LOBE
                        float3 dualLobeSpecu=DirectBDRF_DualLobeSpecular(roughness,F0,N,L,V,_Mask,_Lobeweight);

                        Fdirect=Kd*albedo*real4(myLight.color,1)*NdotL+dualLobeSpecu*PI*real4(myLight.color,1);
                    #else
                        Fdirect=Kd*albedo*real4(myLight.color,1)*NdotL+D*G*F/(4*NdotL*NdotV)*real4(myLight.color,1)*NdotL*PI;
                    #endif

                    //Strand SPECULAR
                    #ifdef ENABLE_STRANDSPECULAR
                        float strandSpec=StrandSpecular(input.BtangentWS,H,_Exponent,_StrandScale);
                        Fdirect=Kd*albedo*real4(myLight.color,1)*NdotL+strandSpec*real4(myLight.color,1)*PI;
                    #endif

                //IndirectLight
                float3 FIndir=F_IndirFunc(F0,NdotV,a);
                float3 KdIndir=(1-FIndir)*(1-metallic);
                
                float3 ShColor=SH_IndirectionDiff(N);
                float3 SpeCubeColor=Indir_SpeCube(N,V,a,1);
                float3 BRDFSpeSection=D*G*F/(4*NdotL*NdotV);
                float3 IndirFactor=IndirSpeFactor(a,1-roughness,BRDFSpeSection,F0,NdotV);
                
                float3 IndirDiff=ShColor*KdIndir*albedo;
                float3 IndirSpe=SpeCubeColor*IndirFactor;

                //NPR
                
                float halfLambert=NdotL*0.5+0.5;
                
                halfLambert=smoothstep(_DarkRange,_DarkRange+_SmoothRange,halfLambert);
                real4 nprDiffuse=halfLambert*albedo+(1-halfLambert)*_DarkColor*albedo;
               
                //mix
                real4 pbrColor=real4(Fdirect+IndirDiff+IndirSpe,1);
                real4 mixColor=lerp(pbrColor,nprDiffuse,_NprFactor);
                
                 #ifdef ENABLE_SSS
                //BSDF
                    real4 sssColor=SAMPLE_TEXTURE2D(_LUTMAP,sampler_LUTMAP,float2(NdotL*0.5+0.5,NdotH))*_SSSTone;
                    mixColor=lerp(mixColor,sssColor*mixColor,_SSSFactor);
                #endif
                //MATCAP 
                #ifdef ENABLE_MATCAP
                    float2 matcapUV = normalize(mul(UNITY_MATRIX_V, N)).xy * 0.5 + 0.5;
                    float4 matcapColor=SAMPLE_TEXTURE2D(_MatCap,sampler_MatCap,matcapUV);
                    matcapColor=max(mixColor,matcapColor);
                    mixColor=lerp(mixColor,matcapColor,_MatCapScale);
                #endif

                //RimLight
                #ifdef ENABLE_RIMLIGHT
                    float rimPow=_RimPower+(1-_RimPower)*pow(1-NdotV,5);
                    rimPow=smoothstep(_RimEdge,_RimEdge+_RimLightWidth*(1-_RimEdge),rimPow);
                    half4 rimColor=rimPow*_RimLightIntensity*_RimLightColor*half4(myLight.color,1)*NdotL;
                    mixColor+=rimColor;
                #endif
                //Fog Calculate
                         mixColor.rgb=MixFog(mixColor.rgb,input.fogFactor*_SystemFogFactor);

                //Recieve Shadow
                #ifdef ENABLE_RECIEVE_SHADOW
                float shadow=myLight.shadowAttenuation;
                float shadowFadeOut=GetDistanceFade(input.positionWS);
                shadow=lerp(1,shadow,shadowFadeOut);
                float4 shadowColor=lerp(mixColor,min(mixColor,float4(IndirDiff,1)),_ShadowFactor);
               
                return lerp(shadowColor,mixColor,shadow);
                #else
                return mixColor;
                #endif 
            }
            ENDHLSL
         }
         pass
			{
				Tags
				{
					"LightMode"="ShadowCaster"
				}
				CULL Off
				ZWrite on
                				
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				
				half3 _LightDirection;
				v2f vert(a2v i)
				{
					v2f o;
										
					o.positionWS=TransformObjectToWorld(i.positionOS);
					o.normalWS=normalize(TransformObjectToWorldNormal(i.normalOS));                    

					o.positionCS=TransformWorldToHClip(ApplyShadowBias(o.positionWS,o.normalWS,_LightDirection));
                    
                    #if UNITY_REVERSE_Z
                    o.positionCS.z=max(o.positionCS.z,o.positionCS.w*UNITY_NEAR_CLIP_VALUE);
                    #else
                    o.positionCS.z=min(o.positionCS.z,o.positionCS.w*UNITY_NEAR_CLIP_VALUE);
                    #endif					
				
					return o;
				}
				half4 frag(v2f i):SV_TARGET
				{
					
					return 0;
				}
				ENDHLSL
			} 
       pass
			{
				Tags
				{
					"LightMode"="Outline"
				}
				CULL Front
				ZWrite on
				
				HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				half3 _LightDirection;
				v2f vert(a2v i)
				{
					v2f o;
										
                    o.positionCS=TransformObjectToHClip(i.positionOS);
					o.positionWS=TransformObjectToWorld(i.positionOS);
					o.normalWS=normalize(TransformObjectToWorldNormal(i.normalOS));
                    #ifdef ENABLE_OUTLINE
                        #ifdef ENABLE_OUTLINE_ATTENUATE
                        o.positionWS+=o.normalWS*_OutlineBias*min(_OutlineMaxDistance,o.positionCS.w);  
                        #else
					    o.positionWS+=o.normalWS*_OutlineBias*o.positionCS.w;   
                        #endif
                    #endif
					
                    o.positionCS=TransformWorldToHClip(o.positionWS);
				
					return o;
				}
				half4 frag(v2f i):SV_TARGET
				{
					
					return _OutlineColor;
				}
				ENDHLSL
			} 
        pass
        {
            Tags
            {
                "LightMode"="HairCast"
            }
            Stencil
            {
            Ref 2
            Comp Equal
            Pass Keep
            }
            ZTest On
            ZWrite off
            BLEND SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag
                v2f vert(a2v i)
				{
					v2f o;
										
                    o.positionWS=TransformObjectToWorld(i.positionOS);
                    Light mLight=GetMainLight();
                    float3 lightDir=normalize(mLight.direction);
                    o.positionCS=TransformWorldToHClip(o.positionWS-float3(lightDir.xy,0)*_CastBias);
				
					return o;
				}
                float4 frag(v2f i):SV_TARGET
                {
                    #ifdef ENABLE_HAIRCASTER
                    float4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);
                    return _CastColor*tex;
                    #else
                    return 0;
                    #endif
                }
            ENDHLSL
        }
            
     }
}