Shader "Universal Render Pipeline/FaceT"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _IlmTex ("IlmTex", 2D) = "white" {}

        _FaceColor ("FaceColor", Color) = (1,1,1,1)
        _ShadowColor ("ShadowColor", Color) = (1,1,1,1)
        _RimLightColor ("RimLightColor", Color) = (1,1,1,1)

        _RimLightPower ("RimLightPower", Range(1,16)) = 1

        _ShadowReciveThreshold ("ShadowReciveThreshold", Range(0,1)) = 0.5

        _ShadowSmooth ("ShadowSmooth", Range(0,1)) = 0.5
        _LitShadowAdjust ("LitShadowAdjust", Range(0,1)) = 0
        
        _UnlitShadowTex ("UnlitShadowTex", 2D) = "white" {}
        _UnlitShadowAdjust ("UnlitShadowAdjust", Range(0,1)) = 0.5
        _HairShadowColor ("HairShadowColor", Color) = (1,1,1,1)
        _UnlitShadowColor_01 ("UnlitShadowColor 01", Color) = (1,1,1,1)
        _UnlitShadowColor_02 ("UnlitShadowColor 02", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_PASS_FORWARDBASE


            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "BlenderNode.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionOS : TEXCOORD0;
                float3 normalVS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float4 shadowCoord : TEXCOORD5;
                float3 positionWS : TEXCOORD6;
            };

            CBUFFER_START(UnityPerMaterial);
            float4 _MainTex_ST;
            float4 _UnlitShadowTex_ST;
            float4 _IlmTex_ST;
            float4 _UnlitShadowColor_01;
            float4 _UnlitShadowColor_02;
            float4 _FaceColor;
            float4 _HairShadowColor;
            float4 _ShadowColor;    
            float _UnlitShadowAdjust;
            float _ShadowSmooth;
            float _LitShadowAdjust;
            float _ShadowReciveThreshold;
            float _RimLightPower;
            float4 _RimLightColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_UnlitShadowTex);
            SAMPLER(sampler_UnlitShadowTex);
            TEXTURE2D(_IlmTex);
			SAMPLER(sampler_IlmTex);

            

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS =GetVertexPositionInputs(IN.positionOS.xyz).positionCS;
                OUT.positionOS = IN.positionOS;
                OUT.normalOS = IN.normalOS;
                OUT.normalWS = normalize(GetVertexNormalInputs(IN.normalOS).normalWS);
                OUT.normalVS = VertesTranformFromObjectToView(IN.normalOS);
                OUT.shadowCoord = TransformWorldToShadowCoord(GetVertexPositionInputs(IN.positionOS.xyz).positionWS);
                OUT.uv = IN.uv;
                OUT.positionWS = GetVertexPositionInputs(IN.positionOS.xyz).positionWS;
                return OUT;
            }

            float4 frag(Varyings IN):SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                half4 unlitShadowCol = SAMPLE_TEXTURE2D(_UnlitShadowTex, sampler_UnlitShadowTex, IN.uv);
                //half4 tanCol = SAMPLE_TEXTURE2D(_TanLineTex, sampler_TanLineTex, IN.uv);   
                //float3 mapSubShadowNor = MappingNode_Tex(IN.normalVS,_SubShadowxyzOffset, _SubShadowxyzScale, _SubShadowxyzRotate);
                //half4 subShadowCol = SAMPLE_TEXTURE2D(_SubShadowTex, sampler_SubShadowTex, mapSubShadowNor);
                //subShadowCol.rgb += _SubShadowBright;
                //subShadowCol.rgb = saturate(subShadowCol.rgb);
                //subShadowCol = lerp(_SubShadowColor_01,_SubShadowColor_02,subShadowCol);
                //tanCol = Reverse(tanCol);
                //col *= _BodyColor;
                //col *= subShadowCol;
                unlitShadowCol.rgb = smoothstep(_UnlitShadowColor_01.rgb,_UnlitShadowColor_02.rgb,unlitShadowCol.rgb);
                unlitShadowCol.rgb = Reverse(unlitShadowCol.rgb);
                half4 hairShadowCol = float4(lerp(_HairShadowColor.rgb,_FaceColor.rgb,unlitShadowCol.rgb),1);
                col *= hairShadowCol;
                col = saturate(col);



                float isSahdow = 0;
                // Shadow From Front To Left
                half4 ilmTex = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, IN.uv);
                //Shadow From Left To Front
                half4 r_ilmTex = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, float2(1 - IN.uv.x, IN.uv.y));
                float2 Left = normalize(TransformObjectToWorldDir(float3(-1, 0, 0)).xz);	// Character left direction in world space
                float2 Front = normalize(TransformObjectToWorldDir(float3(0, 0, 1)).xz);	// Character front direction in world space
                float2 LightDir = normalize(GetMainLight().direction.xz);
                float ctrl = 1 - clamp(0, 1, dot(Front, LightDir) * 0.5 + 0.5);// Calculate the shadow area
                float ilm = dot(LightDir, Left) > 0 ? ilmTex.r : r_ilmTex.r;// Calculate the shadow value
                // If ilm is larger than (ctrl + _LitShadowAdjust), it means that the current pixel is in the shadow area
                isSahdow = step(ctrl + _LitShadowAdjust,ilm);
                float bias = smoothstep(0, _ShadowSmooth, abs(ctrl + _LitShadowAdjust - ilm));

                if (ctrl > 0.99 || isSahdow <= 0)
                {
                    col.xyz = lerp(col.xyz , col.xyz * _ShadowColor.xyz ,bias);
                    //col.rgb *= _ShadowColor.rgb;
                }
                else
                {
                    half shadow =  MainLightRealtimeShadow(IN.shadowCoord);
                    shadow = step(_ShadowReciveThreshold,shadow);
                    col.xyz = lerp(col.xyz , col.xyz * _ShadowColor.xyz ,shadow);
                }

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS.xyz);
                float rimLight = 1 - max(0,dot(viewDir,IN.normalWS));
                rimLight = pow(rimLight,_RimLightPower);
                col += lerp(float4(0,0,0,0),_RimLightColor,rimLight);

                col = saturate(col);

                return col;
            }
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }
    }
}