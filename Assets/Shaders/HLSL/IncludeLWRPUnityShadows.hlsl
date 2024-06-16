#ifndef INCLUDE_LWRP_UNITY_SHADOWS
#define INCLUDE_LWRP_UNITY_SHADOWS
//-------------------------------
// unity shadows wrapped to simple function for reuse
// Note: supports only one shadow cascade!
//-------------------------------

// macro interface
#ifdef _MAIN_LIGHT_SHADOWS
    #define DECLARE_SHADOW_COORD(index)                                       float4 shadowCoord : TEXCOORD##index;
    #define INIT_SHADOW_COORD(output, posWorld)                               output.shadowCoord = TransformWorldToShadowCoord(posWorld)
    #define CALCULATE_SHADOW_ATTENUATION(input, posWorld, defaultAttenuation) CalculateShadowAttenuation(input.shadowCoord, posWorld)

    // shadow fade utils
    half UnityComputeShadowFade(float fadeDist)
    {
        return saturate(fadeDist * _MainLightShadowData.z + _MainLightShadowData.w);
    }
    
    half ComputeShadowFade(float3 posWorld)
    {
        float2 rawFade2d = abs(float2(0.5, 0.5) - saturate(TransformWorldToShadowCoord(posWorld).xy));    // transform (0 .. 1) shadowmap coordinate to (0.5 .. 0 .. 0.5) curve
        float rawFade    = max(rawFade2d.x, rawFade2d.y); // mix two independent (0.5 .. 0 .. 0.5) curves to one
        float fade       = saturate(rawFade - 0.25f) * 4; // transform (0.5 .. 0 .. 0.5) curve to (1 .. 0 .. 0 .. 1) curve - with some zero area in the center
        return fade;
    }
    
    // fragment shader
    half CalculateShadowAttenuation(float4 shadowCoord, float3 posWorld)
    { 
        half shadowAttenuation = max(MainLightRealtimeShadow(shadowCoord), ComputeShadowFade(posWorld));
        return shadowAttenuation;
    }
#else
    #define DECLARE_SHADOW_COORD(index)                                
    #define INIT_SHADOW_COORD(output, posWorld)                            
    #define CALCULATE_SHADOW_ATTENUATION(input, posWorld, defaultAttenuation) defaultAttenuation
#endif












   
#ifdef debug_garbage   
    // keep this here - for testing and research purposes
 
    /*
    half shadowMaskAttenuation = UnitySampleBakedOcclusion(v.ambientOrLightmapUV, 0);
    //half realtimeShadowAttenuation = SHADOW_ATTENUATION(i);
    //half realtimeShadowAttenuation = UNITY_SHADOW_ATTENUATION(i, v.posWorld);
    half realtimeShadowAttenuation = UnityComputeForwardShadows(0, v.posWorld, 0);
    half atten = UnityMixRealtimeAndBakedShadows(realtimeShadowAttenuation, shadowMaskAttenuation, 0);
    atten = ApplyClouds(atten, v.posWorld);
    */
    //UNITY_LIGHT_ATTENUATION(atten, i, v.posWorld);
    //half3 bakedGI = SAMPLE_GI(v.lightmapUV, v.vertexSH, v.normalWorld);
    //MixRealtimeAndBakedGI(mainLight, v.normalWorld, bakedGI, half4(0, 0, 0, 0));
    float atten = mainLight.attenuation;

    // shadow fade to distance (hacked out of original unity shader)
    //float zDist = dot(_WorldSpaceCameraPos - v.posWorld, UNITY_MATRIX_V[2].xyz);
    float zDist = distance(_WorldSpaceCameraPos, v.posWorld); //dot(_WorldSpaceCameraPos - v.posWorld, UNITY_MATRIX_V[2].xyz);
    
    //zDist -= _ShadowData.z;
    
    //zDist *= 0.001f;
    
    //half c = zDist;
    //half c = TransformWorldToShadowCoord(v.posWorld);
//return half4(c, c, c, 1);

    //return half4(TransformWorldToShadowCoord(v.posWorld).xy, 0,1);
    
    //float fadeDist = UnityComputeShadowFadeDistance(v.posWorld, zDist);
    //atten          = max(atten, UnityComputeShadowFade(zDist));
    atten          = max(atten, ComputeShadowFade(v.posWorld));
    
/*
    // shadow fade to distance (hacked out of original unity shader)
    float zDist = dot(_WorldSpaceCameraPos - v.posWorld, UNITY_MATRIX_V[2].xyz);
    float fadeDist = UnityComputeShadowFadeDistance(v.posWorld, zDist);
    atten = max(atten, UnityComputeShadowFade(fadeDist));
    //data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
*/
#endif

#endif