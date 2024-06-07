#include "ReShade.fxh"
#include "ReShadeUI.fxh"


uniform float _ZProjection < __UNIFORM_SLIDER_FLOAT1
    ui_min = 0.0;
    ui_max = 4000.0;
    ui_label = "Camera Z Projeaction";
    ui_tooltip = "Depth of the camera's far plane";
> = 1000.0f;

uniform float _Offset <
    ui_min = 0.0f; ui_max = 1000.0f;
    ui_label = "Fog Offset";
    ui_type = "slider";
    ui_tooltip = "Offset distance at which fog starts to appear.";
> = 0.0f;

uniform float _Density <
    ui_min = 0.0f; ui_max = 0.05f;
    ui_label = "Fog Density";
    ui_type = "slider";
    ui_tooltip = "Adjust fog density.";
> = 0.0f;


uniform float3 _FogColor < __UNIFORM_COLOR_FLOAT3
    ui_label = "Fog Colour";
    ui_tooltip = "Choose a fog colour";
> = float3(0.0, 0.0, 0.0); 

#define colorSampler ReShade::BackBuffer


[shader("pixel")]
float3 PS_ScreenspaceFog(float4 position : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float4 color = tex2D(colorSampler, texcoord);

    float depth = ReShade::GetLinearizedDepth(texcoord);  // Get pixel's depth
    float viewDistance = depth * _ZProjection;  // Distance of pixel from camera far projection

    float fogFactor = (_Density / log(2)) * max(0.0f, viewDistance - _Offset);
    fogFactor = exp2(-fogFactor);
    
    float3 outFog = lerp(_FogColor, color.rgb, saturate(fogFactor));

    return float4(outFog, color.a);
}

technique ScreenspaceFog
{
    pass ScreenspaceFog
    {
        VertexShader=PostProcessVS;
        PixelShader=PS_ScreenspaceFog;
    }
}