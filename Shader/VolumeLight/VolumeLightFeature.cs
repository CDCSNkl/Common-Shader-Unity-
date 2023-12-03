using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VOLight : ScriptableRendererFeature
{
    [System.Serializable]
    public class settings
    {
        [Range(0.1f, 1000)]
        public float maxDistance = 500;
        [Range(0, 2)]
        public float intensity = 1;
        public Color mainColor = Color.white;
        public int steps = 255;

        public Material material;
        public Shader shader;
        public RenderPassEvent renderPassEvent;
        [Range(0, 0.2f)]
        public float RandRange;
    }
    public settings setting = new settings();
    class VOPass : ScriptableRenderPass
    {
        public Material material;
        public Shader shader;

        public float maxDistance, intensity;
        public int steps;
        public Color mainColor;
        public RenderPassEvent renderPassEvent;

        public float RandRange;
        private Matrix4x4 frustumCorners = Matrix4x4.identity;

        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle tempTexture;
        private RenderTargetHandle tempTexture2;
        public FilterMode filterMode { get; set; }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            this.source = renderingData.cameraData.renderer.cameraColorTargetHandle;
            tempTexture.Init("b1");
            tempTexture2.Init("b2");
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("VO_Pass");

            Camera camera = Camera.main;
            //»ñÈ¡ÉãÏñ»ú
            Transform cameraTransform = camera.transform;
            //RandomSeed
            float ram = Random.Range(-300f, 300f);

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
            
            material.SetFloat("_MaxDistance", maxDistance);
            material.SetFloat("_Intensity", intensity);

            material.SetInt("_Steps", steps);
            material.SetColor("_MainColor", mainColor);
            material.SetFloat("_RandomNum", ram);
            material.SetFloat("_RandomRange", RandRange);
            //get RT
            RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;

            cameraTextureDesc.depthBufferBits = 0;
            cameraTextureDesc.msaaSamples = 1;

            cmd.GetTemporaryRT(tempTexture2.id, cameraTextureDesc, filterMode);
            cameraTextureDesc.width /= 4;
            cameraTextureDesc.height /= 4;
            cmd.GetTemporaryRT(tempTexture.id, cameraTextureDesc, filterMode);


            Blit(cmd, source, tempTexture.id, material, 0);
            cmd.SetGlobalTexture("_LightTex", tempTexture.id);

            Blit(cmd, source, tempTexture2.id, material, 1);



            Blit(cmd, tempTexture2.id, source);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }


        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            cmd.ReleaseTemporaryRT(tempTexture.id);
            cmd.ReleaseTemporaryRT(tempTexture2.id);
        }
    }

    VOPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new VOPass();

        m_ScriptablePass.material = setting.material;
        m_ScriptablePass.shader = setting.shader;
        m_ScriptablePass.intensity = setting.intensity;
        m_ScriptablePass.maxDistance = setting.maxDistance;

        m_ScriptablePass.steps = setting.steps;
        m_ScriptablePass.mainColor = setting.mainColor;


        m_ScriptablePass.renderPassEvent = setting.renderPassEvent;
        m_ScriptablePass.RandRange = setting.RandRange;
    }


    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


