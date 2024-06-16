// mikovac
#ifndef SHADOW_PASS
#define SHADOW_PASS

//-------------------------------
// shadow pass, common geometry shading:
// - standard features of shadow pass
// - fake refraction (geometry deformation)
//-------------------------------

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float4 _ShadowBias; // x: depth bias, y: normal bias
float3 _LightDirection;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
};

float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);

    float3 normalWS = TransformObjectToWorldDir(input.normalOS);

    float invNdotL = 1.0 - saturate(dot(_LightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y;

    // normal bias is negative since we want to apply an inset normal offset
    positionWS = _LightDirection * _ShadowBias.xxx + positionWS;
    positionWS = normalWS * scale.xxx + positionWS;
    float4 positionCS = TransformWorldToHClip(positionWS);

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.positionCS = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    return 0;
}

#endif
