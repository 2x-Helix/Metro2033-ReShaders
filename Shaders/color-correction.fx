#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float _Exposure < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Colour correction";
    ui_min = 0.0f;
    ui_max = 10.0f;
    ui_label = "Exposure";
    ui_tooltip = "Modify camera exposure.";
> = 1.0f;

uniform float _Temperature < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Colour correction";
    ui_min = -1.0f;
    ui_max = 1.0f;
    ui_label = "Temperature";
    ui_tooltip = "White balance";
> = 0.0f;

uniform float _Tint < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Colour correction";
    ui_min = -1.0f;
    ui_max = 1.0f;
    ui_label = "Tint";
    ui_tooltip = "Camera exposure";
> = 0.0f;

uniform float _Contrast < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_label = "Contrast";
    ui_tooltip = "Camera exposure";
> = 1.0f;

uniform float _LinearMidpoint < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_label = "Linear Midpoint";
    ui_tooltip = "Adjust midpoint";
> = 0.5f;

uniform float _Brightness < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = -5.0f;
    ui_max = 5.0f;
    ui_label = "Brightness";
    ui_tooltip = "Adjust camera brightness";
> = 0.0f;

uniform float3 _ColorFilter < __UNIFORM_COLOR_FLOAT3
    ui_category = "Colour correction";
    ui_label = "Colour Filter";
    ui_tooltip = "Set colour filter";
> = float3(1.0f, 1.0f, 1.0f);

uniform float _FilterIntensity < __UNIFORM_SLIDER_FLOAT1
    ui_category = "Colour correction";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_label = "Colour Filter Intensity (HDR)";
    ui_tooltip = "Adjust intensity of colour filter";
> = 1.0f;

uniform float _Saturation < __UNIFORM_SLIDER_FLOAT3
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_category = "Colour correction";
    ui_label = "Saturation";
    ui_tooltip = "Adjust colour saturation";
> = 1.0f;

uniform float _Gamma < __UNIFORM_SLIDER_FLOAT3
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_category = "Colour correction";
    ui_label = "Gamma";
    ui_tooltip = "Adjust colour saturation";
> = 1.0f;

#define colorSampler ReShade::BackBuffer 


float3 luminance(float3 color) {
    return dot(color, float3(0.299f, 0.587f, 0.114f));
}

[shader("pixel")]
float3 PS_ColorCorrection(float4 position : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float4 color = tex2D(colorSampler, texcoord);

    float3 output = color.rgb;  // Final output, other values based on original rgb

    // Exposure
    output *= _Exposure;

    // Contrast
    output = _Contrast * (output - _LinearMidpoint) + _LinearMidpoint + _Brightness;
    output = saturate(output);

    // Saturation
    output = lerp(luminance(output), output, _Saturation);
    output = saturate(output);

    // Gamma correction
    output = pow(output, _Gamma);
    output = saturate(output);
    
    return float4(output.rgb, color.a);
}

technique ColorCorrection
{
    pass ColourCorrection
    {
        VertexShader=PostProcessVS;
        PixelShader=PS_ColorCorrection;
    }
}