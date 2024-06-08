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

uniform float3 _Contrast < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_label = "Contrast";
    ui_tooltip = "Camera exposure";
> = float3(1.0f, 1.0f, 1.0f);

uniform float3 _LinearMidpoint < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_label = "Linear Midpoint";
    ui_tooltip = "Adjust midpoint";
> = float3(0.5f, 0.5f, 0.5f);

uniform float3 _Brightness < __UNIFORM_SLIDER_FLOAT3
    ui_category = "Colour correction";
    ui_min = -5.0f;
    ui_max = 5.0f;
    ui_label = "Brightness";
    ui_tooltip = "Adjust camera brightness";
> = float3(0.0f, 0.0f, 0.0f);

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

uniform float3 _Saturation < __UNIFORM_SLIDER_FLOAT3
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_category = "Colour correction";
    ui_label = "Saturation";
    ui_tooltip = "Adjust colour saturation";
> = float3(1.0f, 1.0f, 1.0f);

uniform float3 _Gamma < __UNIFORM_SLIDER_FLOAT3
    ui_min = 0.0f;
    ui_max = 5.0f;
    ui_category = "Colour correction";
    ui_label = "Gamma";
    ui_tooltip = "Adjust colour saturation";
> = float3(1.0f, 1.0f, 1.0f);

#define colorSampler ReShade::BackBuffer 


float3 luminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

/*
Temperature controls hues between yellow and blue, tint controls pink and green hues. 
https://github.com/GarrettGunnell/AcerolaFX/blob/main/Shaders/Includes/AcerolaFX_Common.fxh#L30
https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/White-Balance-Node.html
*/
float3 whiteBalance(float3 color, float temperature, float tint) {
    float t1 = temperature * 10.0 / 6.0;
    float t2 = tint * 10.0 / 6.0;

    // CIE xy chromaticity of reference white point.
    float x = 0.31271 - t1 * (t1 < 0 ? 0.1 : 0.05);
    float standardIlluminantY = 2.87 * x - 3 * x * x - 0.27509507;
    float y = standardIlluminantY + t2 * 0.05;

    // Coefficients in LMS space
    float3 w1 = float3(0.949237, 1.03542, 1.08728);  // D65 white point

    float Y = 1;
    float X = Y * x / y;
    float Z = Y * (1 - x - y) / y;
    float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
    float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
    float S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
    float3 w2 = float3(L, M, S);

    float balance = float3(w1.x/w2.x, w1.y/w2.y, w1.z/w2.z);

    float3x3 LIN_2_LMS_MAT = float3x3(
        float3(3.90405e-1, 5.49941e-1, 8.92632e-3),
        float3(7.08416e-2, 9.63172e-1, 1.35775e-3),
        float3(2.31082e-2, 1.28021e-1, 9.36245e-1)
    );

    float3x3 LMS_2_LIN_MAT = float3x3(
        float3(2.85845, -1.62879, -2.48910e-2),
        float3(-2.10182e-1, 1.15820, 3.24281e-4),
        float3(-4.18120e-2, -1.18169e-1, 1.06867)
    );

    float3 lms = mul(LIN_2_LMS_MAT, color);
    lms *= balance;

    return mul(LMS_2_LIN_MAT, lms);
}

[shader("pixel")]
float3 PS_ColorCorrection(float4 position : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float4 color = tex2D(colorSampler, texcoord);

    float3 output = color.rgb;  // Final output, other values based on original rgb

    // Exposure
    output *= _Exposure;

    // Temperature
    output = whiteBalance(output, _Temperature, _Tint);
    output = saturate(output);

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