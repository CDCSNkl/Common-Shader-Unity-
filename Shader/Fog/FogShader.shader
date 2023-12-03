Shader "NprShader/FogShader"
{
  Properties
  {
	_MainTex("Main Tex",2D)="white"{}
	_NoiseMap("NoiseMap",2D)="white"{}
	_NoiseMap2("NoiseMap2",2D)="white"{}

	[Header(Please Set Values in RenderFeature Panel)]
	[Space(10)]
	_FogDensity("Fog Density",Range(0,1))=1
	_FogColor("Fog Color",COLOR)=(1,1,1,1)
	_FogStart("Fog Start",Range(0,50))=0
	_FogEnd("Fog End",Range(0,2000))=5
	_FogHeight("Fog Height Clamp",float)=200
	_FogFar("Fog Far",Range(0,9000))=200
	_FogNear("Fog Near",Range(0,1000))=0
	_NoiseUvScale("NoiseUV Scale",Range(80,4000))=160
	
  }
  SubShader
  {
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
		}
		
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		CBUFFER_START(UnityPerMaterial)
		float4x4 _FrustumCornersRay;

		half4 _NoiseMap_ST;
		half4 _NoiseMap2_ST;
		half4 _MainTex_TexelSize;
		half _FogDensity;
		half4 _FogColor;
		float _FogStart;
		float _FogEnd;
		float _FogHeight;
		float _FogFar;
		float _FogNear;
		float _NoiseUvScale;
		float3 _WorldSpaceLightPos0;
		float3 _LightDirection;
		CBUFFER_END
		TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
		TEXTURE2D(_CameraDepthTexture);	SAMPLER(sampler_CameraDepthTexture);
		TEXTURE2D(_NoiseMap);	SAMPLER(sampler_NoiseMap);
		TEXTURE2D(_NoiseMap2);	SAMPLER(sampler_NoiseMap2);

		struct a2v
		{
			float4 positionOS:POSITION;
			float2 uv:TEXCOORD0;
		};
		struct v2f
		{
			float4 positionCS:SV_POSITION;
			float2 uv:TEXCOORD0;
			float2 uv_depth:TEXCOORD1;
			float4 interpolatedRay:TEXCOORD2;
			float2 uv_noise:TEXCOORD3;
			
		};
		v2f vert(a2v input)
		{
			v2f output;
			output.positionCS=TransformObjectToHClip(input.positionOS);
			output.uv=input.uv;
			output.uv_depth=input.uv;
			

			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_TexelSize.y<0)
				output.uv_depth.y=1-output.uv_depth.y;
			#endif

			int index=0;
			if(input.uv.x<0.5&&input.uv.y<0.5)
			{
				index=0;
			}
			else if(input.uv.x>0.5&&input.uv.y<0.5)
			{
				index=1;
			}
			else if(input.uv.x>0.5&&input.uv.y>0.5)
			{
				index=2;
			}
			else
				index=3;

			#if UNITY_UV_STARTS_AT_TOP
				if(_MainTex_TexelSize.y<0)
					index=3-index;
			#endif

			output.interpolatedRay=_FrustumCornersRay[index];

			return output;
		}
		half4 frag(v2f input):SV_TARGET
		{
			float linearDepth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,input.uv_depth),_ZBufferParams);
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * input.interpolatedRay.xyz;
			float fogDensity =(_FogEnd-worldPos.y+min(_WorldSpaceCameraPos.y,_FogHeight))/(_FogEnd-_FogStart+min(_WorldSpaceCameraPos.y,_FogHeight));
			
			fogDensity=fogDensity*_FogDensity;
			fogDensity=smoothstep(0,1.5,fogDensity);
			
			float disFactor=(length(linearDepth*input.interpolatedRay)-_FogNear)/(_FogFar-_FogNear);

			float2 noiseUV=float2(worldPos.x,worldPos.z)/_NoiseUvScale;
			float2 noiseUV2=worldPos.zy/(_NoiseUvScale/5);
			float noise=SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,noiseUV+_Time.x/4).r;
			float noise2=SAMPLE_TEXTURE2D(_NoiseMap2,sampler_NoiseMap2,noiseUV2+_Time.x/4).r;
			noise=pow(noise,0.4);
			noise2=pow(noise,2);
			half4 finalColor=saturate(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv));
			float factor=fogDensity*noise*disFactor*noise2;
			factor=smoothstep(0,1,factor);
			
			//Consider Color Change In Night
			half4 fogColor=lerp(_FogColor*0.5,_FogColor,_WorldSpaceLightPos0.y*0.5+0.5);
			finalColor.rgb=lerp(finalColor.rgb,fogColor,factor);
			
			return half4(finalColor.rgb,1);
			
		}
		ENDHLSL
		pass
		{
			ZWrite off
			
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			ENDHLSL
		}
  }
}
