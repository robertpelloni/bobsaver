#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Ns2SzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// nebula effect

// hash without sine (DaveH)
vec3 hash33(vec3 p)
{
    const float UIF = (1.0/ float(0xffffffffU));
    const uvec3 UI3 = uvec3(1597334673U, 3812015801U, 2798796415U);
    uvec3 q = uvec3(ivec3(p)) * UI3;
    q = (q.x ^ q.y ^ q.z)*UI3;
    return vec3(q) * UIF;
}

// 3D Voronoi- (IQ)
float voronoi(vec3 p){

    vec3 b, r, g = floor(p);
    p = fract(p);
    float d = 1.; 
    for(int j = -1; j <= 1; j++)
    {
        for(int i = -1; i <= 1; i++)
        {
            b = vec3(i, j, -1);
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            b.z = 0.0;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
            b.z = 1.;
            r = b - p + hash33(g+b);
            d = min(d, dot(r,r));
        }
    }
    return d;
}

// fbm layer
float noiseLayers(in vec3 p) {

    vec3 pp = vec3(0., 0., p.z + time*.05);
    float t = 0.;
    float s = 0.;
    float amp = 1.;
    for (int i = 0; i < 5; i++)
    {
        t += voronoi(p + pp) * amp;
        p *= 2.;
        pp *= 1.5;
        s += amp;
        amp *= .5;
    }
    return t/s;
}

mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    float dd = length(uv*uv)*0.25;
    //uv *= 2.0+sin(time);
    
    vec3 rd = normalize(vec3(uv.x, uv.y, 3.141592/8.));
    rd.xy *= rot(dd-time*.025);
    
    float c = noiseLayers(rd*2.25);
    float oc = c;
    c = max(c + dot(hash33(rd)*2. - 1., vec3(.006)), 0.);
    c = pow(c*1.35,3.5);    
    
    
    vec3 col =  vec3(0.55,0.8,0.35);
    vec3 col2 =  vec3(0.95,0.7,0.65);
    
    col = mix(col,col2,0.5+sin(dd+uv.x*0.3+time*0.35)*0.5);
    
    
    col = mix(col,col*1.95,0.5+sin(dd*23.0+time*.716+oc*8.0)*0.5)*c;
    glFragColor = vec4(sqrt(col),1.0);
}
