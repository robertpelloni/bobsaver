#version 420

// original https://www.shadertoy.com/view/wsdGRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    float x = gl_FragCoord.x/100.0;
    float phase = time;

    float ass = 0.0;
    float arr[10];

    arr[0] = -0.55;
    arr[1] = 0.77;
    arr[2] = 0.15;
    arr[3] = -0.45;
    arr[4] = -0.3;
    arr[5] = 0.42;
    arr[6] = 0.433;
    arr[7] = -0.13;
    arr[8] = 0.55;
    arr[9] = 0.65;

    for(float i=0.0; i<7.0; i+=1.0){
        float k = pow(2.0, i);
        ass += sin(time + arr[int(i)] * x ) * sin((x+ arr[int(i)] * phase)*k/2.0) / k / 4.0;
    }

    vec3 col = vec3(sin(time), distance(vec2(0, 0), gl_FragCoord.xy)/500.0, 0);
    float val = ass/2.0 + 0.5 - uv.y;
    float p = 100.0;
    float p1 = 40.0;
    if(uv.y < ass/2.0 + 0.5)
        col = vec3(pow(1.0-val, p), pow(1.0-val, p), pow(1.0-val, 2.0));
    else {
        val = -val;
        col = vec3(pow(1.0-val, p), pow(1.0-val, p), pow(1.0-val, p1));
    }

    // Output to screen
    glFragColor = vec4(col,1.0);
}
