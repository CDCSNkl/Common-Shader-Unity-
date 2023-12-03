
Shader "NprShader/VolumeLight"
{
    Properties
    {
    	_MainTex("MainTex",2D)="white"{}
       _MaxDistance("Max Distance",Range(0.1,1000))=500
       _Intensity("Intensity",Range(0,2))=1
       _MainColor("MainColor",COLOR)=(1,1,1,1)
       _Steps("Steps",int)=255
       
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
		
		#pragma shader_feature_local _CUT_ON
		#pragma shader_feature_local _ADDLIGHT_ON
		#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
		#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
		#pragma multi_compile _ _ADDITIONAL_LGIHT_SHADOWS
		#pragma multi_compile _ _SHADOWS_SOFT

        #define random(seed) sin(seed * 641.5467987313875 + 1.943856175)
        
        CBUFFER_START(UnityPerMaterial)
        float4x4 _FrustumCornersRay;
        float4 _LightTex_TexelSize;
        float4 _MainTex_ST;
        float _MaxDistance;
        float _Intensity;
        int _Steps;
        
        half4 _MainColor;
        float _RandomNum;
        float _RandomRange;

        CBUFFER_END
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_CameraDepthTexture);	SAMPLER(sampler_CameraDepthTexture);
        TEXTURE2D(_LightTex);	SAMPLER(sampler_LightTex);
         struct a2v
         {
             float4 positionOS:POSITION;
             float3 normalOS:NORMAL;
             float2 uv:TEXCOORD;
             
          
         };
         struct v2f
         {
             float4 positionCS:SV_POSITION;
             float2 uv:TEXCOORD;
             float3 normalWS:NORMAL;
             float3 positionWS:TEXCOORD1;
             float2 uv_depth:TEXCOORD2;
			 float4 interpolatedRay:TEXCOORD3;             
         };
        ENDHLSL

        pass
        {
         Tags{

             "LightMode"="UniversalForward"
             "RenderType"="Opaque"
            }
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            v2f vert(a2v input)
            {
                v2f output;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                output.uv=TRANSFORM_TEX(input.uv,_MainTex);
                output.normalWS=TransformObjectToWorldNormal(input.normalOS);
                output.positionWS=TransformObjectToWorld(input.positionOS);
                
                output.uv_depth=input.uv;

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

            output.interpolatedRay=_FrustumCornersRay[index];

                return output;
            }
            real4 frag(v2f input):SV_TARGET
            {
               float linearDepth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,input.uv_depth),_ZBufferParams);
               float3 worldPos=_WorldSpaceCameraPos+linearDepth*input.interpolatedRay.xyz;
               
               half4 tex=saturate(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv));
               
               half volumeLimit=min(_MaxDistance,length(worldPos-_WorldSpaceCameraPos));
               
               //raydir
               float3 rayDir=normalize(linearDepth*input.interpolatedRay.xyz);
               float3 currentPos=_WorldSpaceCameraPos;
               //Loop Settings
               float totalSize=0;
               half4 finalColor=0;
               float4 shadowCoord=0;
               half shadow=0;
               float stepSize=volumeLimit/_Steps;
               //Random Seed
               float seed = random((_ScreenParams.y * worldPos.y + worldPos.x) * _ScreenParams.x + _RandomNum);
               Light mLight=GetMainLight();
               float lightY=abs(1-normalize(mLight.direction).y);

               float midDepth=LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,float2(0.5,0.5)),_ZBufferParams);
               float3 cameraDir=normalize(midDepth*input.interpolatedRay.xyz);                      
                  //step loop
                  stepSize*=0.5;
                  for(int i=0;i<_Steps;i++)
                  {
                     seed=random(seed);
                    stepSize+=0.1*stepSize;
                    totalSize+=stepSize;
                    if(totalSize<volumeLimit)
                    {
                        currentPos+=rayDir*stepSize+float3(seed,seed,seed)*_RandomRange;
                        shadowCoord = TransformWorldToShadowCoord(currentPos);
                        shadow = MainLightRealtimeShadow(shadowCoord);
                        finalColor+=_MainColor*_Intensity*shadow*lightY/_Steps*(dot(cameraDir,normalize(mLight.direction))*0.5+0.5);
                    }
                  }
                
             
              finalColor*=2*finalColor;
              return finalColor;
              
            }
            ENDHLSL
         }
         pass
         {
            Tags{

             "LightMode"="UniversalForward"
             "RenderType"="Opaque"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            v2f vert(a2v input)
            {
                v2f output;
                output.uv=input.uv;
                output.positionCS=TransformObjectToHClip(input.positionOS);
                return output;
            }
            half4 frag(v2f input):SV_TARGET
            {
                float4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float4 lightTex=SAMPLE_TEXTURE2D(_LightTex,sampler_LightTex,input.uv);
                //KAWASE BLUR
                lightTex += SAMPLE_TEXTURE2D(_LightTex,sampler_LightTex,input.uv+float2(-1,-1)*_LightTex_TexelSize.xy*2);
                lightTex += SAMPLE_TEXTURE2D(_LightTex,sampler_LightTex,input.uv+float2(1,-1)*_LightTex_TexelSize.xy*2);
                lightTex += SAMPLE_TEXTURE2D(_LightTex,sampler_LightTex,input.uv+float2(1,1)*_LightTex_TexelSize.xy*2);
                lightTex += SAMPLE_TEXTURE2D(_LightTex,sampler_LightTex,input.uv+float2(-1,1)*_LightTex_TexelSize.xy*2);
                lightTex/=5;
                return mainTex+lightTex;
            }
            ENDHLSL
         }
        
     
     }
}