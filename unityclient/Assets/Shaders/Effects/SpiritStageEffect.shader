// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "ProjectX/Effects/SpiritStageEffect" {
    Properties {
        [Enum(UnityEngine.Rendering.BlendMode)] _RTAlphaSrc ("RT Alpha Source", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _RTAlphaDst ("RT Alpha Destination", Float) = 1
		[HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		[Enum(UnityEngine.Rendering.BlendMode)] SrcBlend("SrcBlend", Float) = 5//SrcAlpha
		[Enum(UnityEngine.Rendering.BlendMode)] DstBlend("DstBlend", Float) = 1//One
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 0
		[Enum(off,0,On,1)] _ZWrite ("ZWrite", float) = 0
		[Space(10)]
		[Toggle(IsCoustom)]_IsCoustom("IsCoustom",int) = 0
		[Space(10)]
		[HDR] _BaseColor ("Base Color", Color) = (1,1,1,1)
		[Space(10)]
        _BaseMap ("Base Map", 2D) = "white" {}
		[Toggle(DeBlackBG)]_DeBlackBG("DeBlackBG",int) = 0
        _BaseMapBrightness ("BaseMap Brightness", Float ) = 1
        _BaseMapPower ("BaseMap Power", Float ) = 1
		_BaseMapPannerX ("BaseMapPannerX",Float) = 0
		_BaseMapPannerY ("BaseMapPannerY",Float) = 0
		[Space(10)]
        _TurbulenceTex ("Turbulence Tex", 2D) = "white" {}
        _TurbulenceTexPannerX ("Turbulence Tex Panner X", Float ) = 0
        _TurbulenceTexPannerY ("Turbulence Tex Panner Y", Float ) = 0
		_TurbulenceStrength ("TurbulenceStrength", Float ) = 0
		[Space(10)]
		_MaskTex ("Mask Tex", 2D) = "white" {}
        _MaskTexPannerX ("Mask Tex Panner X", Float ) = 0
        _MaskTexPannerY ("Mask Tex Panner Y", Float ) = 0
		[Space(10)]
		_DissolveTex ("Dissolve Tex", 2D) = "white" {}
        _DissolvePannerX ("Dissolve Tex Panner X", Float ) = 0
        _DissolvePannerY ("Dissolve Tex Panner Y", Float ) = 0
		_DisSoftness ("DisSoftness",range (0.1,2)) = 0.1
		_AnDissolve ("AnDissolve",range (-3,3)  ) = -3
		[Space(10)]
		[Toggle(IsFresnel)]_IsFresnel("IsFresnel",int) = 0
		[HDR] _FColor ("FColor",Color) = (1,1,1,1)
		_FScale ("FScale",Float ) = 1
		[Space(10)]
		[Toggle(IsDoubleFace)]_IsDoubleFace("IsDoubleFace",int) = 0
		[HDR] _FaceInColor ("FaceInColor",Color) = (1,1,1,1)
		[HDR] _FaceOurColor ("FaceOurColor",Color) = (1,1,1,1)
		[Space(10)]
		_PointMove ("PointMove",vector ) =(0,0,0,0)
		//[Enum(UnityEngine.Rendering.CompareFunction)]  _ZTest ("ZTest ",float) = 0
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="Universal2D"
            }
			Blend [SrcBlend] [DstBlend], [_RTAlphaSrc] [_RTAlphaDst]
            Cull [_Cull]
            ZWrite [_ZWrite]
            //ZTest [_ZTest]
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityCG.cginc"
			#pragma shader_feature  DeBlackBG
			#pragma shader_feature  IsFresnel
			#pragma shader_feature  IsCoustom
			#pragma shader_feature  IsDoubleFace
			#pragma target 3.0

				uniform sampler2D _BaseMap;
				uniform sampler2D _TurbulenceTex;
				uniform sampler2D _MaskTex;
				uniform sampler2D _DissolveTex;

				uniform float4 _BaseColor;
				uniform float4 _BaseMap_ST;
	            uniform float _BaseMapBrightness;
				uniform float _BaseMapPower;
				uniform float _BaseMapPannerX;
				uniform float _BaseMapPannerY;
				uniform float4 _TurbulenceTex_ST;
                uniform float _TurbulenceTexPannerX;
                uniform float _TurbulenceTexPannerY;
				uniform float _TurbulenceStrength;
				uniform float4 _MaskTex_ST;
	            uniform float _MaskTexPannerX;
	            uniform float _MaskTexPannerY;
				uniform float4 _DissolveTex_ST;
	            uniform float _DissolvePannerX;
	            uniform float _DissolvePannerY;
				uniform float _DisSoftness;
				uniform float _AnDissolve;
				uniform float4 _PointMove;
				uniform float _FScale;
				uniform float4 _FColor;
				uniform float4 _FaceInColor;
				uniform float4 _FaceOurColor;




            struct VertexInput {
                float4 vertex : POSITION;
                fixed2 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 vertexColor : COLOR;
				float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 vertexColor : COLOR;
				float3 normal : TEXCOORD2;
				float4 posWS : TEXCOORD3;
            };


            VertexOutput vert (VertexInput v) {
				//Point move
				float4 move = float4(v.texcoord0 + float2 (_Time.y  * _TurbulenceTexPannerX, _Time.y * _TurbulenceTexPannerY),0,0);
				float4 turCol = tex2Dlod (_TurbulenceTex,move) - _PointMove.w;
				v.vertex.xyz += float3(turCol.x * _PointMove.x, turCol.y * _PointMove.y,turCol.y * turCol.x * _PointMove.z) ;

                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos( v.vertex.xyz);
				o.posWS =  mul(unity_ObjectToWorld, v.vertex.xyz);;
				o.normal = v.normal;

                return o;
            }


            float4 frag(VertexOutput i , fixed facing : VFACE) : COLOR {
				//DoubleFace
				float3 FaceColor = (1,1,1) ;
				#if IsDoubleFace
				float DoubleFace = (facing >= 0 ?  1 : 0);
					 FaceColor = (DoubleFace * _FaceOurColor + (1 - DoubleFace) *_FaceInColor ).rgb;
				# endif
				//Fresnel
				float3  N = normalize( UnityObjectToWorldNormal(i.normal));
				float3  V = normalize(_WorldSpaceCameraPos - i.posWS);
				float4  F = pow(( 1 - saturate( dot( N , V))),_FScale) * _FColor ;
				//MASK
				float2 _MaksUV = (i.uv0+float2(_MaskTexPannerX*_Time.g, _MaskTexPannerY*_Time.g));
                float4 _MaskTex_var = tex2D(_MaskTex,  TRANSFORM_TEX(_MaksUV, _MaskTex));
				float _MaskOut = _MaskTex_var.r * _MaskTex_var.a ;
				//Tuberlence
				float2 _TurbulenceUV = (i.uv0+float2(_TurbulenceTexPannerX*_Time.g,_TurbulenceTexPannerY*_Time.g) );
                float4 _TurbulenceTex_var = tex2D(_TurbulenceTex,  TRANSFORM_TEX(_TurbulenceUV, _TurbulenceTex));
				//Base
				float2 _BaseUVCruve = float2(i.uv1.r , i.uv1.g ) * 0  ;
				#if IsCoustom
					 _BaseUVCruve = float2(i.uv1.r , i.uv1.g )   ;
				# endif
				float2 _BaseUVSelfMove = float2(_BaseMapPannerX , _BaseMapPannerY) * _Time.g ;
				float2 _BaseUV = (_TurbulenceTex_var.r * _TurbulenceStrength + (i.uv0 + float2(_BaseUVCruve + _BaseUVSelfMove)));
				#if IsCoustom
					 _BaseUV = (_TurbulenceTex_var.r * i.uv1.b  + (i.uv0 + float2(_BaseUVCruve + _BaseUVSelfMove)));
				# endif
                float4 _BaseMap_var = tex2D(_BaseMap,  TRANSFORM_TEX(_BaseUV, _BaseMap));
				//Disslove
				float2 _DissolveUV =(_TurbulenceTex_var.r*i.uv1.b ) + (i.uv0+(_DissolvePannerX * _Time.g ,_DissolvePannerY * _Time.g));
				float4 _DissolveTex_var = tex2D(_DissolveTex, TRANSFORM_TEX(_DissolveUV, _DissolveTex));
				float _DissolveOut = pow (( saturate (_DissolveTex_var.r*_DissolveTex_var.a  - saturate(i.uv1.a)*2 -  _AnDissolve ) ), _DisSoftness ) ;

				//Out

				#if IsFresnel
				  float3 _ColorOut = _BaseColor.rgb * (pow((_BaseMapBrightness * _BaseMap_var.rgb), _BaseMapPower) * i.vertexColor.rgb)* FaceColor.rgb + F.rgb;
				#else
				  float3 _ColorOut = _BaseColor.rgb * (pow((_BaseMapBrightness * _BaseMap_var.rgb), _BaseMapPower) * i.vertexColor.rgb) * FaceColor.rgb;
				# endif

				#if DeBlackBG
				  float  _AphaOut = _BaseColor.a * _BaseMap_var.r * _BaseMap_var.a  * _MaskOut  * _DissolveOut * i.vertexColor.a;
				#else
				  float _AphaOut = _BaseColor.a  * _BaseMap_var.a  * _MaskOut  * _DissolveOut * i.vertexColor.a;
				# endif


                return float4(_ColorOut,_AphaOut);
            }
            ENDCG
        }
    }
}
