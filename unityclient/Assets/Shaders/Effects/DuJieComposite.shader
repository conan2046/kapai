Shader "ProjectX/UI/DuJieComposite"
{
    Properties
    {
        [PerRendererData] _MainTex ("Effect Render Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Cull Off ZWrite Off ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct input { float4 position : POSITION; float2 uv : TEXCOORD0; fixed4 color : COLOR; };
            struct output { float4 position : SV_POSITION; float2 uv : TEXCOORD0; fixed4 color : COLOR; };
            sampler2D _MainTex;
            output vert(input i)
            {
                output o;
                o.position = UnityObjectToClipPos(i.position);
                o.uv = i.uv;
                o.color = i.color;
                return o;
            }
            fixed4 frag(output i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= i.color.rgb * i.color.a;
                c.a *= i.color.a;
                return c;
            }
            ENDCG
        }
    }
}
