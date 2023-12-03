Shader "NprShader/CloudShader"
{
  Properties
  {
	_MainTex("MainTex",2D)="white"{}
	_Cutoff("Cutoff",Range(0.001,1))=0.1
	_NoiseMap("NoiseMap",2D)="white"{}

	
	[Header(Cloud Settings)]
	[Space(5)]
	[Header(DayColor)]
	[Space(8)]
	[HDR]_CloudColorA("Cloud ColorA",COLOR)=(1,1,1,1)
	_CloudColorB("Cloud ColorB",COLOR)=(1,1,1,1)

	[Header(NightColor)]
	[Space(8)]
	_CloudColorC("Cloud ColorC",COLOR)=(1,1,1,1)
	_CloudColorD("Cloud ColorD",COLOR)=(1,1,1,1)

	_SpecColor("SpecularColor",COLOR)=(1,1,1,1)
	_DarkColor("DarkColor",COLOR)=(1,1,1,1)
	[Space(5)]
	[HDR]_EdgeColor("Edge Color",COLOR)=(1,1,1,1)
	[Space(5)]
	_SunDirection("Sun Direction",Vector)=(0,0,0,0)
	_NoiseSpeed("Noise Speed",Range(0,1))=0
	_SDFRate("SDF Rate",Range(0,1))=0.1
	_SDFRange("SDF Range",Range(0,1))=0.1
	_SDFSpeed("SDF Speed",Range(1,10))=1

	_ColorStep1("Step1",Range(0,1))=0.1
	_ColorStep2("Step2",Range(0,1))=0.2
	_AOFactor("AO",Range(0,1))=0.1
  }
  SubShader
  {
		Tags
		{
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Transparent"
			"IgnoreProjector"="True"
			"Opaque"="Transparent"
		}
		ZTest LEqual
		ZWrite off
		BLEND SrcAlpha OneMinusSrcAlpha
		
	HLSLINCLUDE

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

	CBUFFER_START(UnityPerMaterial)
	float4 _MainTex_ST;
	float4 _NoiseMap_ST;
	float _Cutoff;

	half4 _CloudColorA;
	half4 _CloudColorB;
	half4 _CloudColorC;
	half4 _CloudColorD;

	half4 _SpecColor;
	half4 _DarkColor;

	half4 _EdgeColor;

	float4 _SunDirection;
	float _NoiseSpeed;

	float3 _LightDirection;
	float _SDFRate;
	float _SDFRange;
	float _SDFSpeed;
	float _ColorStep1;
	float _ColorStep2;
	float _AOFactor;
	CBUFFER_END
	TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
	TEXTURE2D(_NoiseMap);	SAMPLER(sampler_NoiseMap);

	struct a2v
	{
		float4 positionOS:POSITION;
		float2 uv:TEXCOORD0;
		float3 normal:NORMAL;
	};
	struct v2f
	{
		float4 positionCS:SV_POSITION;
		float2 uv:TEXCOORD0;
		float3 normal:NORMAL;
		float2 uv_Noise:TEXCOORD1;
		float3 positionWS:TEXCOORD2;
		float3 viewWS:TEXCOORD3;
	};
	half reramp(half x,half t1,half t2,half s1,half s2)
	{
		return (x-t1)/(t2-t1)*(s2-s1)+s1;
	}
	v2f vert(a2v input)
	{
		v2f output;
		output.positionCS=TransformObjectToHClip(input.positionOS);
		output.positionWS=TransformObjectToWorld(input.positionOS);
		output.uv=TRANSFORM_TEX(input.uv,_MainTex);
		output.uv_Noise=TRANSFORM_TEX(input.uv,_NoiseMap);
		output.normal=-TransformObjectToWorldNormal(input.normal);
		output.viewWS=normalize(_WorldSpaceCameraPos-output.positionWS);

		output.uv_Noise=output.uv+_Time.x*_NoiseSpeed;

		return output;
	}
	real4 frag(v2f input):SV_TARGET
	{
		
		

		//light Caculate
		float lambert=saturate(dot(_LightDirection,input.normal));
		lambert=lambert*0.5+0.5;

		//Day/Night
		float dayNight=smoothstep(-0.3,0.3,_LightDirection.y);
		
		half4 dayColor=lerp(_CloudColorB,_CloudColorA,lambert);
		half4 nightColor=lerp(_CloudColorD,_CloudColorC,lambert);
		
		//viewDir
		float3 halfDir=normalize(input.viewWS+_LightDirection);
		float transmission=pow(saturate(dot(halfDir,input.normal)),3);
		half4 transColor=_SpecColor*transmission;

		//noiseTurbol
		float4 noiseTex=SAMPLE_TEXTURE2D(_NoiseMap,sampler_NoiseMap,input.uv_Noise);
		float UVdisturbance=reramp(noiseTex.r,0,1,0,0.01);
		float ScaleDisturb=reramp(noiseTex.r,0,1,0.98,1);
		input.uv=input.uv*_MainTex_ST.xy*ScaleDisturb+_MainTex_ST.zw;
		real4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv+UVdisturbance);
		clip(tex.a-_Cutoff);
		
		
		float cloudAO=smoothstep(_ColorStep1,_ColorStep2,tex.r);
		cloudAO=reramp(cloudAO,0,1,_AOFactor,1);

		dayColor*=lerp(_DarkColor,_SpecColor,cloudAO);
		nightColor*=cloudAO;
		half4 dayNightColor=lerp(nightColor,dayColor,dayNight);

		

		//SDF Sample
		float2 sdfNoise=float2(input.positionWS.x+input.positionWS.z,input.positionWS.y+input.positionWS.z)/100;
		sdfNoise.x+=_Time.y/_SDFSpeed;
		sdfNoise.y+=_Time.y/_SDFSpeed;
		sdfNoise=sin(sdfNoise/3);
		sdfNoise=sdfNoise*0.5+0.5;
		
		float smo=smoothstep(_SDFRate,_SDFRate+sdfNoise*_SDFRange,tex.b);
		

		//Edge Color
		half4 edgeColor=_EdgeColor*tex.g*(lambert-0.2);
		edgeColor*=smo;

		half4 finalColor=dayNightColor+edgeColor+transColor;
		
		return real4(finalColor.rgb,pow(smo,3));
				
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
		
		ENDHLSL
	}
	
  }
  
}
