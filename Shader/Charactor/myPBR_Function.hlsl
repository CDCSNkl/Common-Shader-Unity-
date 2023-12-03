#ifndef myPBR_Function_INCLUDE
#define	myPBR_Function_INCLUDE
float D_Func(float a,float NdotH)
{
	float nom=a*a;
	float denom=NdotH*NdotH*(nom-1)+1;
	denom*=denom*PI;
	return nom/denom;
}

float GGX_Func(float dot,float a)
{
	float k=pow(1+a*a,2)/8;
	return dot/(dot*(1-k)+k);
}

float GGX_iblFunc(float dot,float a)
{
	float k=a*a/2;
	return dot/(dot*(1-k)+k);
}

float3 F_Func(float3 F0,float HdotL)
{
	return F0+(1-F0)*pow(1-HdotL,5);
}

float3 F_IndirFunc(float3 F0,float NdotV,float a)
{
	
	return F0+(1-F0-a)*pow(1-NdotV,5);
}

real3 SH_IndirectionDiff(float3 normalWS)
         {
             real4 SHCoefficients[7];
             SHCoefficients[0] = unity_SHAr;
             SHCoefficients[1] = unity_SHAg;
             SHCoefficients[2] = unity_SHAb;
             SHCoefficients[3] = unity_SHBr;
             SHCoefficients[4] = unity_SHBg;
             SHCoefficients[5] = unity_SHBb;
             SHCoefficients[6] = unity_SHC;
             float3 Color = SampleSH9(SHCoefficients,normalWS);
             return max(0,Color);
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

    float3 DirectBDRF_DualLobeSpecular(float roughness,float3 F0,float3 N,float3 L,float3 V,float mask,float lobeWeight)
    {
        float3 H=normalize(L+V);
        float NdotH=saturate(dot(N,H));
        float HdotL=saturate(dot(L,H));

        float r=roughness*roughness;
        float r2=r-1;
        float normalizationTerm=roughness*4+2;

        float d=NdotH*NdotH*r2+1.0001;
        float NdotL=saturate(dot(N,L));
        float HdotL2=HdotL*HdotL;
        float sAO=saturate(NdotL*NdotL-0.3);
        sAO=lerp(pow(0.75,8),1,sAO);
        float specularTermGGX=r/((d*d)*max(0.1,HdotL2)*normalizationTerm);
        float specularTermBeckMann=2*r/(d*d*max(0.1,HdotL2)*normalizationTerm)*mask*lobeWeight;
        float specularTerm=(specularTermGGX/2+specularTermBeckMann)*sAO;

        return F0*specularTerm;
    }

    float StrandSpecular(float3 T, float3 H, float exponent,float scale)
{
	float dotTH=dot(T,H);
	float sinTH=sqrt(1-dotTH*dotTH);
    float dirAtten=smoothstep(-1,0,dotTH);

	return dirAtten*pow(sinTH,exponent)*scale;
}

#endif