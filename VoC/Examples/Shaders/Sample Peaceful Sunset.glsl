#version 420

// original https://www.shadertoy.com/view/wsKcRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////////////////////////////////////////////////////////////////
//
//     PEACEFUL SUNSET
//
//     by Tech_
//
/////////////////////////////////////////////////////////////////////////////

float getCloudNoiseWaves(in vec2 uv, float scale, float speed) 
{
    float waveColor;
    vec2 uvVar1 = uv * scale / 8.;
    vec2 uvVar2 = uv * scale / 0.25;
    
    float waves1;
    waves1 += cos(uvVar1.x * 30. + sin(time * speed + uvVar1.y * 10. + cos(uvVar1.x * 60.0 + time * speed)));
    waves1 *= waves1;
    waves1 *= 0.3;
    
    float waves2;
    waves2 += cos(uvVar2.x / 6. * 5.0 + sin(time * speed + uvVar2.y + cos(uvVar2.x + time * 2. * speed)));
    waves2 *= waves2 * 0.2;
    
    waveColor = waves1 + waves2 * 2.;
    
    return waveColor;
}

float getClouds(in vec2 uv, float cloudOpacity, float cloudHeight, float cloudScale, float cloudAmount) 
{
    cloudAmount -= 1.;
    float fog;
    vec2 st = uv;
    uv.y *= 4.;
    uv.x *= 0.4;
    uv.x += time / 1270. / cloudScale;
    uv.y += sin((uv.x + time / 100.) * 30.) * 0.02;
    fog += getCloudNoiseWaves(uv * cloudScale, 3.4, 0.1);
    fog -= getCloudNoiseWaves(uv * cloudScale + vec2(2.), 2.4, 0.2);
    fog = clamp(fog, 0., 1.);
    float mask;
    mask = 1. - distance(st.y - (0.35 + cloudHeight), 0.5 + cloudHeight) * 2.;
    fog *= mask;
    fog = smoothstep(0.15 - cloudAmount, 0.6 - cloudAmount, fog);
    return mix(0., clamp(fog, 0., 1.), cloudOpacity);
}

float getWave(in vec2 uv, float waveHeight, float waveSpeed, float waveFrequency, float waveAmplitude, float depth) 
{
    uv.y -= sin(time + depth * 12.) / 60. * waveAmplitude;
    waveSpeed = time / 4. * waveSpeed;
    float wave = smoothstep(0.0 + waveHeight, 0.003 + waveHeight * (depth + 1.), uv.y + sin((uv.x + waveSpeed) * waveFrequency * 10. + sin(uv.x * 3.)) * 0.03 * waveAmplitude);
    float result = 1. - wave;
    return result;
}

vec4 getOcean(in vec2 uv, float waveHeight, float waveSpeed, float waveFrequency, float waveAmplitude) 
{
    vec3 waves;
    waveHeight -= 1.;
    waveFrequency -= 1.;
    waves += getWave(uv, 0.325 + waveHeight, 0.025 * waveSpeed, 8. + waveFrequency, 0.06 * waveAmplitude, 0.0) * vec3(0.2);
    waves += getWave(uv, 0.3 + waveHeight, 0.05 * waveSpeed, 6. + waveFrequency, 0.1 * waveAmplitude, 0.0005) * vec3(0.2);
    waves += getWave(uv, 0.26 + waveHeight, 0.1 * waveSpeed, 4. + waveFrequency, 0.2 * waveAmplitude, 0.01) * vec3(0.2);
    waves += getWave(uv, 0.20 + waveHeight, 0.2 * waveSpeed, 2. + waveFrequency, 0.4 * waveAmplitude, 0.05) * vec3(0.2);
    waves += getWave(uv, 0.11 + waveHeight, 0.35 * waveSpeed, 1.5 + waveFrequency, 0.77 * waveAmplitude, 0.2) * vec3(0.2);
    waves = pow(waves, vec3(1.)) / 1.6;
    
    float oceanOpacity = 1. - getWave(uv, 0.325 + waveHeight, 0.025 * waveSpeed, 8. + waveFrequency, 0.06 * waveAmplitude, 0.0);
    
    return vec4(waves, oceanOpacity);
}

vec3 getSun(in vec2 uv, float oceanOpacity) 
{
    vec2 st = uv;
    uv -= .5;
     uv.x *= resolution.x / resolution.y;
    
    uv.y += 0.05;
    
    float radius = 0.1;
    float uvLength = 1. - length(uv);
    vec3 sun;
    float sunOpacity = 1.;
    
    for(int i = 0; i < 10; i++) 
    {
        sunOpacity *= 0.6;
        sun += vec3(smoothstep(0.95 - radius, 0.953 - radius, uvLength) * sunOpacity) * vec3(1., 0.6, 0.);
        sun = clamp(sun, 0., 1.);
        radius *= 1.3 + sin(time) / 100.;
    }
    
    sun *= oceanOpacity;
    sun.g *= 0.9;
    
    vec3 sunGlow = clamp(1. - vec3(length(uv * 2.)), 0., 1.) * oceanOpacity;
    sunGlow *= smoothstep(0.1 - sin(time) / 10., 1. - sin(time) / 10., sunGlow);
    
    vec3 flare = 1. - vec3(distance(vec2(st.x * 1.5 - 0.25, st.y * 2. - 0.5), vec2(0.5))) * 2. + sin(time) / 40.;
    flare = clamp(flare * vec3(1., 0.8, 0.), 0., 1.);
    
    return sun + (sunGlow + flare) / 4.;
}

vec3 getSkyGradient(in vec2 uv) 
{
    float mid = smoothstep(0.2, 0.5, uv.y);
    
    vec3 midColLit = vec3(1., 0.341 * 2., 0.09 * 2.2);
    vec3 midColUnlit = vec3(1., 0.341, 0.09);
    vec3 midCol = mix(midColUnlit, midColLit, 1. - clamp(distance(uv.x, 0.5) * 1.5, 0., 1.));
    vec3 upperCol = vec3(0.5, 0.156, 0.225);
    
    vec3 skyColorTop = mix(midCol, upperCol, uv.y);
    vec3 skyColorBottom = mix(vec3(1., 0.6, 0.1), vec3(1., 0.7, 0.1), 1. - clamp(distance(uv.x, 0.5) * 3., 0., 1.));
    
    vec3 skyColor = mix(skyColorBottom, skyColorTop, mid);
    
    return skyColor;
}

float luma(vec3 color)
{
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec3 changeLuminance(vec3 colorIn, float lumaOut)
{
    float lumaIn = luma(colorIn);
    return colorIn * (lumaOut / lumaIn);
}

vec3 reinhardExtended(vec3 color, float maxWhiteLuma)
{
    float lumaOld = luma(color);
    float numerator = lumaOld * (1.0 + (lumaOld / (maxWhiteLuma * maxWhiteLuma)));
    float lumaNew = numerator / (1.0 + lumaOld);
    return changeLuminance(color, lumaNew);
}

vec3 tonemapping(in vec3 color)
{
    color -= 0.06;
    color *= 1.62;
    color = reinhardExtended(color, 2.);
    return color;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    vec3 color;
    
    vec3 waveColor = vec3(0.19, 0.21, 0.45); 
    vec3 waves = getOcean(uv, 1.05, 1.2, 1.1, 1.0).rgb;
    waves *= waveColor;
    
    vec3 sun = vec3(getSun(uv, getOcean(uv, 1.05, 1.2, 1.1, 1.0).a));
    
    vec3 skyColor = getSkyGradient(uv);
    vec3 sky = pow(1. - getOcean(uv, 1.05, 1.2, 1.1, 1.0).rgb, vec3(1.5)) * skyColor;
    
    float clouds = getClouds(uv, 0.5, 0.01, 1., 0.8);
    clouds += getClouds(uv, 0.4, 0.015, 2., 0.75);
    clouds += getClouds(uv, 0.3, 0.02, 2.3, 0.75);
    
    color = waves + sky + sun + clouds;
    
    // color = tonemapping(color);
    
    // Output to screen
    glFragColor = vec4(color, 1.0);
}
