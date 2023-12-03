using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        [Range(0f, 1f)]
        public float FogDensity = 1.0f;
        [Range(0f, 50f)]
        public float FogStart = 0f;
        [Range(0f, 2000f)]
        public float FogEnd = 20f;
        public float FogHeight = 200f;
        [Range(0f, 1000f)]
        public float FogNear = 30f;
        [Range(0f, 9000f)]
        public float FogFar = 120f;
        [Range(80f, 4000f)]
        public float NoiseUvScale = 160f;
        public Color FogColor = Color.white;
        public RenderPassEvent renderPassEvent;
        public Shader shader;
        public Material material;
    }
    public Settings settings = new Settings();
    class FogPass : ScriptableRenderPass
    {
        public Material material;
        private Matrix4x4 frustumCorners = Matrix4x4.identity;
        
        public float FogDensity, FogStart, FogEnd,FogNear,FogFar,FogHeight,NoiseUvScale;
        public Color FogColor;
        public FilterMode filterMode { get; set; }
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle tempTexture;
        //string m_ProfilerTag;
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            this.source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            tempTexture.Init("_TempTexture");
        }



        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("FogPass");


            Camera camera = renderingData.cameraData.camera;
            //获取摄像机
            Transform cameraTransform = camera.transform;

            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float far = camera.farClipPlane;
            float aspect = camera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop = cameraTransform.up * halfHeight;
            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            topLeft.Normalize();
            topLeft *= scale;
            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;
            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;
            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            material.SetMatrix("_FrustumCornersRay", frustumCorners);


            material.SetFloat("_FogDensity", FogDensity);
            material.SetFloat("_FogStart", FogStart);
            material.SetFloat("_FogEnd", FogEnd);
            material.SetColor("_FogColor", FogColor);
            material.SetFloat("_FogNear", FogNear);
            material.SetFloat("_FogFar", FogFar);
            material.SetFloat("_FogHeight", FogHeight);
            material.SetFloat("_NoiseUvScale", NoiseUvScale);
            //创建一张RT
            RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
            cameraTextureDesc.depthBufferBits = 0;
            cameraTextureDesc.msaaSamples = 1;
            //取消抗锯齿处理,抗锯齿会影响unity自动在DX与OpenGL间的坐标转换
            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDesc, filterMode);

            //将当前帧的colorRT用着色器（shader in material）渲染后输出到之前创建的贴图（辅助RT）上
            Blit(cmd, source, tempTexture.id, material, 0);
            //将处理后的辅助RT重新渲染到当前帧的colorRT上
            Blit(cmd, tempTexture.Identifier(), source);

            //执行渲染
            context.ExecuteCommandBuffer(cmd);
            //释放回收

            CommandBufferPool.Release(cmd);
        }


        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            cmd.ReleaseTemporaryRT(tempTexture.id);
        }
    }

    FogPass m_ScriptablePass;


    public override void Create()
    {
        m_ScriptablePass = new FogPass();

        m_ScriptablePass.renderPassEvent=settings.renderPassEvent;
        m_ScriptablePass.FogDensity = settings.FogDensity;
        m_ScriptablePass.FogColor = settings.FogColor;
        m_ScriptablePass.FogStart = settings.FogStart;
        m_ScriptablePass.FogNear = settings.FogNear;
        m_ScriptablePass.FogFar = settings.FogFar;
        m_ScriptablePass.FogEnd = settings.FogEnd;
        m_ScriptablePass.material = settings.material;
        m_ScriptablePass.FogHeight = settings.FogHeight;
        m_ScriptablePass.NoiseUvScale = settings.NoiseUvScale;
    }


    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {

        renderer.EnqueuePass(m_ScriptablePass);
    }
}


