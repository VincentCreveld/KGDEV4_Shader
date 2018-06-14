// This shader is made by Vincent Creveld
// http://vincentcreveld.nl

Shader "Custom/SimpleWaterShader" 
{
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("BumpMap",2D) = "bump" {}
		_AlphaWeight("Alpha", Range(0, 1)) = 0
		_Blend1("Blend between pass and grabpass", Range(0, 1)) = 0
		_WaveHeight("Wave height", Range(0,10)) = 1
		_WaveSpeed("Wave speed", Range(0,1)) = 1
	}
		SubShader{
			Tags { "RenderType" = "Transperent" "Queue" = "Transparent" }
			ZWrite On
			ColorMask RGBA
			LOD 200
		
			GrabPass{"_GrabPassTex"}

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Lambert vertex:vert

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _GrabPassTex;
			float _WaveHeight;
			float _WaveSpeed;
			float4 _Color;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
			float4 screenPos;
			float3 worldPos;
			float3 worldNormal; INTERNAL_DATA
			float3 objectNormal;
			float3 worldRefl;
		};

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex);	
			worldPos.x += sin(_Time.z + worldPos.y * 10) * 0.1 * _WaveSpeed;
			worldPos.y += cos(_Time.z + worldPos.z * 10) * 0.1 * _WaveHeight ;
			worldPos.z += sin(_Time.z + worldPos.x * 10) * 0.1 * _WaveSpeed;
			v.vertex = mul(unity_WorldToObject, worldPos);
		}

		float _Blend1, _AlphaWeight;

		void surf (Input IN, inout SurfaceOutput o) {

			// Collects reflection data from the reflection probe.
			half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, IN.worldRefl);
			half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

			// Changes the weight of the normal map to tune its prominence and blend the normals.
			half3 blue = half3(0, 0, 1);
			fixed4 normal1 = tex2D(_BumpMap, IN.uv_BumpMap + half2(0, _Time.x));
			fixed4 normal2 = tex2D(_BumpMap, IN.uv_BumpMap*2 + half2(_Time.x, 0));
			fixed4 normalBlend = (normal1 + normal2) / 2;
			o.Normal = lerp(blue, UnpackNormal(normalBlend), _AlphaWeight);

			// Applies emission based on the angle you're looking at the pixel.
			half fresnel = 1 - dot(IN.viewDir, o.Normal);
			o.Emission = pow(fresnel, 6);

			// Determines the position of the pixel in the world of the GrabPass output texture and blends it with the mesh.
			half2 screenUV = IN.screenPos.xy / IN.screenPos.w;
			// tex2D(_MainTex, IN.uv_MainTex)
			fixed4 blendTexture = lerp(tex2D(_GrabPassTex, screenUV), _Color, _Blend1);

			// Applies the world reflection and blends it with the combined texture of the GrabPass and the main texture albedo.
			o.Albedo =  lerp(blendTexture.rgb, skyColor.rgb, fresnel) + pow(fresnel, 8);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
