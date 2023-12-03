Shader "NprShader/LeafShader"
{
    Properties
    {
       _MainTex("MainTex",2D)="white"{}
	   _Cutoff("Cutoff",Range(0,1))=0.5
       [Header(Color Settings)]
       [Space(10)]
       _TopColor("Top Color",COLOR)=(1,1,1,1)
	   _BotColor("Bot Color",COLOR)=(1,1,1,1)
	   _SpecularColor("Specular Color",COLOR)=(1,1,1,1)
	  // _ScatterColor("Scatter Color",COLOR)=(1,1,1,1)
       [HDR]_TransmissionColor("Transmission Color",COLOR)=(1,1,1,1)

       [Header(Value Settings)]
       [Space(10)]
       _RampScale("Ramp Scale",Range(0,1))=0
	   _Gloss("Gloss",Range(0.001,60))=2
	   _ShadowAttenuation("ShadowAttenuation",Range(0,1))=0
	   //_ScatterScale("Scatter Scale",Range(0,1))=0
	   _transmissionIntensity("transmission intensity",Range(0,1))=0.3
       _FresnelScale("Fresnel Scale",Range(0,1))=0.5
	   _FresnelFactor("Fresnel Factor",Range(0,0.5))=0
	   _LightIntensity("LightIntensity",Range(0,10))=1
	   
	   [Header(Wind Wave)]
       [Space(10)]
       _WaveSpeed("Wave Speed",range(0,10))=1
	   _WaveSize("Wave Size",range(0,10))=1
	   _WaveYaxis("Wave Yaxis",range(0,20))=0

	   [Space(10)]
	   [Toggle(ENABLE_SPHERE_NORMAL)]_EnableSphereNormal("Enable Sphere Normal",float)=1
	   _OriginHeight("Origin Height",Range(0,10))=0
	   [Space(5)]
	   [Toggle(ENABLE_EMISSION)]_EnableEmission("Enable Emission",float)=0
	   [HDR]_EmissionColor("Emission Color",COLOR)=(1,1,1,1)
	   _EmissionScale("Emission Scale",Range(0,3))=1

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
            #pragma shader_feature_local ENABLE_SPHERE_NORMAL
			#pragma shader_feature_local ENABLE_EMISSION

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
	        float _Cutoff;
	        half4 _TopColor;
	        half4 _BotColor;
	        half4 _SpecularColor;
	       // half4 _ScatterColor;
	        half4 _TransmissionColor;

	        float _Gloss;
	        float _RampScale;
	        float _ShadowAttenuation;
	       // float _ScatterScale;
	        float _transmissionIntensity;
	        float _FresnelScale;
	        float _FresnelFactor;

	        float _WaveSpeed;
	        float _WaveSize;
	        float _WaveYaxis;
			float _LightIntensity;

			float _OriginHeight;

			half4 _EmissionColor;
			float _EmissionScale;
			
        CBUFFER_END

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
	
            struct a2v
            {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float2 uv:TEXCOORD0;
				              
              UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct v2f
            {
                float4 positionCS:SV_POSITION;
                float3 normalWS:NORMAL;
                float2 uv:TEXCOORD0;
                float3 positionWS:TEXCOORD1;
				float3 sphereNormal:TEXCOORD2;
				
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            v2f vert(a2v input)
            {
				v2f output;
                UNITY_SETUP_INSTANCE_ID(input);
			    UNITY_TRANSFER_INSTANCE_ID(input,output);

                output.normalWS=TransformObjectToWorldNormal(input.normalOS);
		    	output.uv=TRANSFORM_TEX(input.uv,_MainTex);
		    	output.positionWS=TransformObjectToWorld(input.positionOS);
    
			    //Wave
			    float waveSin=_WaveSpeed*max(input.positionOS.y-_WaveYaxis,0)*_Time.x;
			    output.positionWS.x+=sin(waveSin+input.positionOS.x)*_WaveSize;
			    output.positionWS.z+=sin(waveSin+input.positionOS.x)*_WaveSize;

			    output.positionCS=TransformWorldToHClip(output.positionWS);

				output.sphereNormal=normalize(input.positionOS-float3(0,_OriginHeight,0));
					
                return output;
            }
            half4 frag(v2f input):SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
				clip(tex.a-_Cutoff);
				float4 shadowCoord=TransformWorldToShadowCoord(input.positionWS);
				Light mLight=GetMainLight(shadowCoord);
				float3 lightDir=normalize(mLight.direction);

				float lambert=dot(input.normalWS,lightDir)*0.5+0.5;
				float lambertY=dot(input.normalWS.y,lightDir)*0.5+0.5;
				float3 viewWS=normalize(_WorldSpaceCameraPos-input.positionWS);
				float3 halfDir=normalize(viewWS+lightDir);
				float specu=pow(saturate(dot(halfDir,input.normalWS)),_Gloss);
				half4 specuColor=specu*_SpecularColor;

				#ifdef ENABLE_SPHERE_NORMAL
				lambertY=dot(input.sphereNormal,lightDir)*0.5+0.5;
				#endif
				//Scatter:with special texture. its G tunnel contains RimColor Mask
				//float scatterMask=max(0,(1-tex.g)*lambert-_ScatterScale);
				//half4 scatterColor=scatterMask*_ScatterColor;
				//transmission
				float3 transHalf=normalize(input.normalWS+lightDir);
				float transmissionScale=lerp(0,1,saturate(dot(-transHalf,viewWS)));
				half4 transColor=transmissionScale*_TransmissionColor;

				//Fresnel
				float fresnel=_FresnelScale+(1-_FresnelScale)*pow(1-dot(viewWS,input.normalWS),5);
				#ifdef ENABLE_SPHERE_NORMAL
				fresnel=_FresnelScale+(1-_FresnelScale)*pow(1-dot(viewWS,input.sphereNormal),5);
				#endif
				fresnel=min(1,fresnel);
				half4 fresnelColor=_SpecularColor*fresnel;

				half4 baseColor=lerp(_BotColor,_TopColor,max(lambertY-_RampScale-min(0,lightDir.y+0.3),0))*lerp(1,mLight.shadowAttenuation,_ShadowAttenuation);

				float nightFactor=max(0.2,lightDir.y*0.5+0.5);

				baseColor=lerp(baseColor,baseColor+transColor,_transmissionIntensity*nightFactor);
				baseColor=max(baseColor,fresnelColor*_FresnelFactor*nightFactor);
				baseColor=max(baseColor,specuColor*nightFactor);
				half4 finalColor=tex*baseColor*_LightIntensity;

				#ifdef ENABLE_EMISSION
				finalColor+=_EmissionColor*_EmissionScale*lambertY;
				#endif
								
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
       pass
		{
			Tags
			{
				"LightMode"="ShadowCaster"
			}
			Cull off
			HLSLPROGRAM
			#pragma vertex vert2
			#pragma fragment frag2
			

			v2f vert2(a2v i)
			{
				v2f o;
				o.positionWS=TransformObjectToWorld(i.positionOS);
				o.normalWS=normalize(TransformObjectToWorldNormal(i.normalOS));
				Light mLight=GetMainLight();
				o.positionCS=TransformWorldToHClip(ApplyShadowBias(o.positionWS,o.normalWS,normalize(mLight.direction)));
				#if UNITY_REVERSE_Z
                    o.positionCS.z=max(o.positionCS.z,o.positionCS.w*UNITY_NEAR_CLIP_VALUE);
                    #else
                    o.positionCS.z=min(o.positionCS.z,o.positionCS.w*UNITY_NEAR_CLIP_VALUE);
                    #endif			
				o.uv=TRANSFORM_TEX(i.uv,_MainTex);
			
				return o;
			}
			half4 frag2(v2f i):SV_TARGET
			{
				
					float alpha=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).r;
					clip(alpha-_Cutoff);
				
					return 0;
			}
			ENDHLSL
		}
    }
}
