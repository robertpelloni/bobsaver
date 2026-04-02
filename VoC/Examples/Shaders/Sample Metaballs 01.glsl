#version 420

// by srtuss, 2013

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float rand1(float x)
{
    return fract(sin(x) * 4358.5453123);
}

float noise1(float x)
{
    float fl = floor(x);
    float fc = fract(x);
    return mix(rand1(fl), rand1(fl + 1.0), smoothstep(0.0, 1.0, fc)) * 2.0 - 1.0;
}

float fbm1(float x)
{
    return noise1(x) * 0.5 + noise1(x * 2.0) * 0.25;
}

struct METABALL
{
    vec2 pos;
    float size;
};

// classic metaball term
float intensity(vec2 pos, METABALL mtb)
{
    pos -= mtb.pos;
    return mtb.size / dot(pos, pos);
}

// calculate a field of metaballs
float field(vec2 pos)
{
    float v = 0.0;
    for(int i = 0; i < 8; i ++)
    {
        float x = float(i) * 0.5 + time - 68.0;
        
        // simulate some dynamic using smooth noise
        METABALL mtb;
        mtb.pos = vec2(fbm1(x), fbm1(x + 10.0)) * 1.5;
        mtb.size = fbm1(x + 20.0) * 0.1 + 0.1;
        
        v += intensity(pos, mtb);
    }
    
    return v;
}

// calculate proper metaball height
float height(vec2 pos)
{
    float treshold = 2.0;
    
    // we need to get rid of the pole in the field function.
    // by taking the reciproc of the intensity, we end up with some
    // sort of quadratic function. we could now flatten or sharpen
    // this using a pow(), but i think the result is great already.
    
    return 1.0 - 1.0 / max(field(pos) - treshold, 0.01);
}

// fetch field normal and height
vec4 normal_and_height(vec2 pos)
{
    float c = height(pos);
    
    vec3 h = vec3(1.0 / resolution.xy, 0.0);
    vec3 delta;
    
    // evaluate the gradient
    delta.x = (height(pos + h.xz) - c) / h.x;
    delta.y = (height(pos + h.zy) - c) / h.y;
    
    // this controls the peak size of the metaballs
    delta.z = 2.0;
    
    return vec4(normalize(delta), c);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    
    
    vec4 nh = normal_and_height(uv);
    
    vec3 bgCol = vec3(0.3, 0.3, 0.3);
    
    if(nh.w < 0.0)
    {
        glFragColor = vec4(bgCol, 1.0);
        return;
    }
    
    // light direction
    vec3 light = normalize(vec3(0.9, -0.9, 1.0));
    
    
    // smooth border
    float alpha = smoothstep(0.0, 0.3, nh.w);
    
    // reflected light vector
    vec3 ref = reflect(normalize(vec3(uv, -1.0)), nh.xyz);
    
    // diffuse light term
    float diff = dot(nh.xyz, light) * 0.6 + 0.4;
    
    // specular light term
    float spec = max(dot(ref, light), 0.0);
    spec = pow(spec, 8.0);
    
    // cubemap to simulate complex reflections (optional)
    //vec3 cube = textureCube(iChannel0, ref).xyz;
    vec3 cube=vec3(0.0);
    
    // an ambient occulsion'ish black border
    float brd = 1.0 - exp(-4.0 * nh.w);
    
    // combine colors
    vec3 col = vec3(0.0, 1.0, 0.3);
    col = col * diff + spec + cube * 0.05;
    col *= brd;
    
    glFragColor = vec4(mix(bgCol, col, alpha), 1.0);
}
